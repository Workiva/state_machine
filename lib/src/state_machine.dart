// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library state_machine.src.state_machine;

import 'dart:async';

import 'package:state_machine/src/exceptions.dart';
import 'package:w_common/disposable.dart';

/// Represents a state that can be visited within a
/// [StateMachine] instance.
///
/// States must be created from a [StateMachine] instance:
///
///     StateMachine door = new StateMachine('door');
///
///     State isOpen = door.newState('open');
///     State isClosed = door.newState('closed');
///
///     door.start(isOpen);
///
/// There are 3 things that can be done with states:
///
/// 1. Listen for onEnter events (every time the machine enters
/// this state).
/// 2. Listen for onLeave events (every time the machine leaves
/// this state).
/// 3. Determine if the state is active (machine is currently
/// in this state).
///
/// To demonstrate:
///
///     // 1.
///     isOpen.onEnter.listen((StateChange change) {
///       // onEnter stream event always includes the StateChange info.
///       print('${change.from.name} --> ${isOpen.name}');
///     });
///
///     // 2.
///     isOpen.onLeave.listen((StateChange change) {
///       // onLeave stream event always includes the StateChange info.
///       print('${isOpen.name} --> ${change.to.name}');
///     });
///
///     // 3.
///     isOpen();   // true
///     isClosed(); // false
///
/// It's recommended that states be named in the format "isState".
/// This may seem strange at first, but it has two main benefits:
///
/// 1. It helps differentiate states from transitions, which can be confusing
/// since many words in English are the same as a verb and an adjective
/// ("open" or "secure", for example).
/// 2. It reads better when calling the state to determine if it's active,
/// as demonstrated above when calling `isOpen()` and `isClosed()`.
class State extends Disposable {
  @override
  String get disposableTypeName => 'State';

  /// Wildcard state that should be used to define state transitions
  /// that allow transitioning from any state.
  static State any = State._wildcard();

  /// Name of the state. Used for debugging.
  String name;

  /// [StateMachine] that this state is a part of.
  StateMachine? _machine;

  /// Stream controller used internally to create
  /// the onEnter stream.
  late StreamController<StateChange> _onEnterController = StreamController();

  /// Stream of onEnter events from [_onEnterController]
  /// as a broadcast stream.
  late Stream<StateChange> _onEnter =
      _onEnterController.stream.asBroadcastStream();

  /// Stream controller used internally to create
  /// the onLeave stream.
  late StreamController<StateChange> _onLeaveController = StreamController();

  /// Stream of onLeave events from [_onLeaveController]
  /// as a broadcast stream.
  late Stream<StateChange> _onLeave =
      _onLeaveController.stream.asBroadcastStream();

  State._(this.name, this._machine, {bool listenTo = true}) {
    manageStreamController(_onEnterController);
    manageStreamController(_onLeaveController);

    if (!listenTo) return;
  }

  State._none(StateMachine machine) : this._('__none__', machine);

  State._wildcard() : this._('__wildcard__', null, listenTo: false);

  /// Stream of enter events. Enter event occurs every time
  /// the machine enters this state.
  Stream<StateChange> get onEnter => _onEnter;

  /// Stream of leave events. Leave event occurs every time
  /// the machine leaves this state.
  Stream<StateChange> get onLeave => _onLeave;

  /// Determine whether or not this [State] is active.
  bool call([_]) {
    return _machine!.current == this;
  }

  @override
  String toString() {
    String name = this.name;
    if (name == '__none__') {
      name = 'none - state machine has yet to start';
    }
    return 'State: $name (active: ${this()}, machine: ${_machine!.name})';
  }
}

/// Represents a change for a [StateMachine] instance from
/// one state to another. If a payload was supplied when
/// executing the transition, it will be available via
/// [payload].
class StateChange {
  /// State the machine transitioned from.
  State from;

  /// Payload supplied when the transition was called,
  /// if any.
  dynamic payload;

  /// State the machine transitioned to.
  State to;

  StateChange._(this.from, this.to, this.payload);

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    String fromName = from.name == '__none__' ? '(none)' : from.name;
    sb.writeln('StateChange: ${fromName} --> ${to.name}');
    if (payload != null) {
      sb.writeln('    payload: $payload');
    }
    return sb.toString();
  }
}

/// A simple, typed finite state machine.
///
/// Creating a state machine takes 3 steps:
///
/// 1. Instantiate a [StateMachine].
/// 2. Create the set of states.
/// 3. Create the set of valid state transitions.
///
/// To demonstrate:
///
///     // 1.
///     StateMachine machine = new StateMachine('switch');
///
///     // 2.
///     State isOn = machine.newState('on');
///     State isOff = machine.newState('off');
///
///     // 3.
///     StateTransition turnOn = machine.newStateTransition('turnOn', [isOff], isOn);
///     StateTransition turnOff = machine.newStateTransition('turnOff', [isOn], isOff);
///
/// Once the state machine is setup as desired,
/// it must be started at a specific state. Once started,
/// no additional states or transitions can be added.
///
///     machine.start(isOff);
///
/// At any point, you can retrieve the current state
/// from the machine:
///
///     State current = machine.current;
///
/// Once initialized, the state machine is driven by the
/// states and the state transitions. See [State] and
/// [StateTransition] for more information.
class StateMachine extends Disposable {
  @override
  String get disposableTypeName => 'StateMachine';

  /// Name of the state machine. Used for debugging.
  String name;

  /// [State] that the machine is currently in.
  State get current => _current;

  /// Start the machine in a temporary state.
  /// This allows an initial state transition to occur
  /// when the machine is started via [start].
  late State _current = State._none(this);

  /// Whether or not this state machine has been started.
  /// If it has, calls to [newState] and [newStateTransition]
  /// will be prevented.
  bool _started = false;

  /// Stream controller used internally to control the
  /// state change stream.
  late StreamController<StateChange> _stateChangeController =
      StreamController();

  /// Stream of state changes used internally to notify state
  /// and state transition listeners.
  late Stream<StateChange> _stateChangeStream =
      _stateChangeController.stream.asBroadcastStream();

  /// List of states created by for this machine.
  List<State> _states = [];

  StateMachine(String this.name) {
    manageStreamController(_stateChangeController);
    _stateChangeStream = _stateChangeController.stream.asBroadcastStream();
    manageDisposable(_current);
  }

  /// Stream of state change events. This allows [State]s
  /// and [StateTransition]s to listen for state changes
  /// and notify listeners as necessary.
  ///
  /// The event payload will be the previous [State].
  Stream<StateChange> get onStateChange => _stateChangeStream;

  /// Create a new [State] for this [StateMachine].
  ///
  /// [name] helps identify the state for debugging purposes.
  State newState(String name) {
    if (_started)
      throw IllegalStateMachineMutation(
          'Cannot create new state ($name) once the machine has been started.');
    State state = State._(name, this);
    manageDisposable(state);
    _states.add(state);
    return state;
  }

  /// Create a new [StateTransition] for this [StateMachine].
  ///
  /// [name] helps identify the transition for debugging purposes.
  /// This transition will only succeed when this [StateMachine]
  /// is in one of the states listed in [from]. When this transition
  /// occurs, this [StateMachine] will move to the [to] state.
  StateTransition newStateTransition(String name, List<State> from, State to) {
    if (_started)
      throw IllegalStateMachineMutation(
          'Cannot create new state transition ($name) once the machine has been started.');
    StateTransition newTransition = StateTransition._(name, this, from, to);
    manageDisposable(newTransition);
    return newTransition;
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.writeln('StateMachine: $name');
    _states.forEach((state) {
      if (state()) {
        sb.writeln(' >> ${state.name} (active)');
      } else {
        sb.writeln('    ${state.name}');
      }
    });
    return sb.toString();
  }

  /// Start the state machine at the given starting state.
  void start(State startingState) {
    if (_started) throw StateError('Machine has already been started.');
    _started = true;
    _transition(StateChange._(current, startingState, null));
  }

  /// Set the machine state and trigger a state change event.
  void _transition(StateChange stateChange) {
  // Notify the current state that it is being left
  _current._onLeaveController.add(stateChange);

  // Update the current state to the new state
  _current = stateChange.to;
  manageDisposable(_current);

  // Notify the new state that it is being entered
  _current._onEnterController.add(stateChange);

  // Add the state change to the stream
  _stateChangeController.add(stateChange);
}

}

/// Represents a legal state transition for a  [StateMachine] instance.
///
/// State transitions must be created from a [StateMachine] instance
/// and must define the set of legal "from" states and a single "to"
/// state. The machine must be in one of the "from" states in order
/// for this transition to occur.
///
///     StateMachine door = new StateMachine('door');
///
///     State isOpen = door.newState('open');
///     State isClosed = door.newState('closed');
///
///     StateTransition open = door.newStateTransition('open', [isClosed], isOpen);
///     StateTransition close = door.newStateTransition('close', [isOpen], isClosed);
///
///     door.start(isClosed);
///
/// There are 3 things that can be done with state transitions:
///
/// 1. Listen for the transition events (every time the machine successfully
/// executes this transition).
/// 2. Attempt to execute this transition (will succeed so long as
/// it is legal given the machine's current state and it isn't canceled).
/// 3. Add conditions that can cancel this transition.
///
/// To demonstrate:
///
///     // 1.
///     open.listen((StateChange change) {
///       // transition stream event always includes the previous state,
///       // since transitions can define multiple legal "from" states.
///       print('Door opened.');
///     });
///
///     // 2.
///     open(); // returns `true` since the transition was legal and succeeded.
///
///     // 3.
///     close.cancelIf((StateChange change) => true); // will cancel the close transition every time
///     close(); // returns `false` since it was canceled
///
/// To get a better idea of how state transitions can be used, consider
/// the following example that integrates two separate state machines
/// to represent the state of a lamp.
///
///     StateMachine powerCord = new StateMachine('powerCord');
///     State isPluggedIn = powerCord.newState('pluggedIn');
///     State isUnplugged = powerCord.newState('unplugged');
///     StateTransition plugIn = powerCord.newStateTransition('plugIn', [isUnplugged], isPluggedIn);
///     StateTransition unplug = powerCord.newStateTransition('unplug', [isPluggedIn], isUnplugged);
///
///     StateMachine lamp = new StateMachine('lamp');
///     State isOn = lamp.newState('on');
///     State isOff = lamp.newState('off');
///     StateTransition turnOn = lamp.newStateTransition('turnOn', [isOff], isOn);
///     StateTransition turnOff = lamp.newStateTransition('turnOff', [isOn], isOff);
///
///     // When the power cord is unplugged, transition the lamp to the
///     // "off" state if it is currently "on".
///     unplug.listen((_) {
///       if (isOn()) {
///         turnOff();
///       }
///     });
///
///     // The lamp cannot be turned on if the power cord is unplugged.
///     turnOn.cancelIf(isUnplugged);
///
///     isOn.onEnter.listen((_) => print('Light is on!'));
///     isOn.onLeave.listen((_) => print('Light is off :('));
///
///     powerCord.start(isUnplugged);
///     lamp.start(isOff);
///
///     turnOn(); // canceled, no power
///     plugIn();
///     turnOn(); // "Light is on!"
///     unplug(); // "Light is off :("
class StateTransition extends Disposable {
  @override
  String get disposableTypeName => 'StateTransition';

  /// Name of the state transition. Used for debugging.
  String name;

  /// List of cancel tests registered via [cancelIf]
  /// that will be called before executing this transition.
  List<Function> _cancelTests = [];

  /// List of valid [State]s that the machine must be in
  /// for this transition to occur.
  List<State> _from;

  /// [StateMachine] that this state transition is a part of.
  StateMachine _machine;

  /// Stream controller used internally to create a stream of
  /// transition events.
  late StreamController<StateChange> _streamController =
      StreamController<StateChange>();

  /// Stream of transition events from [_streamController] as
  /// a broadcast stream. Transition event occurs every time
  /// this transition executes successfully.
  late Stream<StateChange> _stream =
      _streamController.stream.asBroadcastStream();

  /// Stream of transition events. A transition event occurs every time this
  /// transition executes successfully.
  Stream<StateChange> get stream => _stream;

  /// [State] to transition the machine to when executing
  /// this transition.
  State _to;

  StateTransition._(String this.name, StateMachine this._machine,
      List<State> this._from, State this._to) {
    if (_to == State.any)
      throw ArgumentError(
          'Cannot transition to the wildcard state "State.any"');
    manageStreamController(_streamController);
  }

  /// Listen for transition events. Transition event occurs every time
  /// this transition executes successfully.
  ///
  /// [onData] will be called with the [State] that was transitioned from.
  @Deprecated('Listen to \'stream\' directly')
  StreamSubscription listen(void onTransition(StateChange stateChange),
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    final streamSubscription = listenToStream(_stream, onTransition,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
    return streamSubscription;
  }

  /// Execute all the pre-checks to understand
  /// if a transition can take place or not.
  /// Will call any tests registered via [cancelIf],
  /// canceling the transition if any test
  /// returns true.
  ///
  /// Returns true if transition can be executed,
  /// false if it's not possible.
  bool canCall([payload]) {
    StateChange stateChange = StateChange._(_machine.current, _to, payload);

    // Verify the transition is valid from the current state.
    if (!_from.contains(stateChange.from) && !_from.contains(State.any)) {
      return false;
    }

    // Allow transition to be canceled.
    for (int i = 0; i < _cancelTests.length; i++) {
      if (_cancelTests[i](stateChange)) {
        return false;
      }
    }

    return true;
  }

  /// Execute this transition. Will call any tests registered
  /// via [cancelIf], canceling the transition if any test
  /// returns true. Otherwise, the transition will occur
  /// and the machine will transition accordingly.
  ///
  /// Returns true if the transition succeeded, false
  /// if it was canceled.
  bool call([payload]) {
    StateChange stateChange = StateChange._(_machine.current, _to, payload);

    // Verify the transition is valid from the current state.
    if (!_from.contains(stateChange.from) && !_from.contains(State.any)) {
      throw IllegalStateTransition(this, stateChange.from, stateChange.to);
    }

    // Allow transition to be canceled.
    for (int i = 0; i < _cancelTests.length; i++) {
      if (_cancelTests[i](stateChange)) return false;
    }

    // Transition is legal and wasn't canceled.
    // Update the machine state.
    _machine._transition(stateChange);

    // Notify listeners.
    _streamController.add(stateChange);
    return true;
  }

  /// Add a test that will be called before executing
  /// this transition. If [test] returns true, the
  /// transition will be canceled.
  void cancelIf(bool test(StateChange stateChange)) {
    _cancelTests.add(test);
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.writeln('StateTransition: $name (machine: ${_machine.name})');
    sb.writeln('    from: ${_from.map((f) => f.name).join(', ')}');
    sb.writeln('    to: ${_to.name}');
    return sb.toString();
  }
}
