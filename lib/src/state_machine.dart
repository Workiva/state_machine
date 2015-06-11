library state_machine.src.state_machine;

import 'dart:async';

/// A simple, typed finite state machine.
///
/// Creating a state machine takes 3 steps:
/// 1. Instantiate a [StateMachine].
/// 2. Create the set of states.
/// 3. Create the set of valid state transitions.
///
///     // 1.
///     StateMachine machine = new StateMachine();
///
///     // 2.
///     State isOn = door.newState('on');
///     State isOff = door.newState('off');
///
///     // 3.
///     StateTransition turnOn = door.newStateTransition('turnOn', [isOff], isOn);
///     StateTransition turnOff = door.newStateTransition('turnOff', [isOn], isOff);
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
class StateMachine {
  /// [State] that the machine is currently in.
  State current;

  /// Whether or not this state machine has been started.
  /// If it has, calls to [newState] and [newStateTransition]
  /// will be prevented.
  bool _started = false;

  /// Stream controller used internally to control the
  /// state change stream.
  StreamController _stateChangeController;

  /// Stream of state changes used internally to notify state
  /// and state transition listeners.
  Stream<StateChange> _stateChangeStream;

  StateMachine() {
    _stateChangeController = new StreamController();
    _stateChangeStream = _stateChangeController.stream.asBroadcastStream();

    /// Start the machine in a temporary state.
    /// This allows an initial state transition to occur
    /// when the machine is started via [start].
    current = new State._('__none__', this);
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
    if (_started) throw new IllegalStateMachineMutation('Cannot create new state ($name) once the machine has been started.');
    return new State._(name, this);
  }

  /// Create a new [StateTransition] for this [StateMachine].
  ///
  /// [name] helps identify the transition for debugging purposes.
  /// This transition will only succeed when this [StateMachine]
  /// is in one of the states listed in [from]. When this transition
  /// occurs, this [StateMachine] will move to the [to] state.
  StateTransition newStateTransition(String name, List<State> from, State to) {
    if (_started) throw new IllegalStateMachineMutation('Cannot create new state transition ($name) once the machine has been started.');
    return new StateTransition._(name, this, from, to);
  }

  /// Start the state machine at the given starting state.
  void start(State startingState) {
    if (_started) throw new StateError('Machine has already been started.');
    _started = true;
    _setState(startingState);
  }

  /// Set the machine state and trigger a state change event.
  void _setState(State state) {
    State previous = current;
    current = state;
    _stateChangeController.add(new StateChange(previous, current));
  }
}

class StateChange {
  StateChange(this.from, this.to);
  State from;
  State to;
}

/// Represents a state that can be visited within a
/// [StateMachine] instance.
///
/// States must be created from a [StateMachine] instance:
///
///     StateMachine door = new StateMachine();
///
///     State isOpen = door.newState('open');
///     State isClosed = door.newState('closed');
///
///     door.start(isOpen);
///
/// There are 3 things that can be done with states:
/// 1. Listen for onEnter events (every time the machine enters
/// this state).
/// 2. Listen for onLeave events (every time the machine leaves
/// this state).
/// 3. Determine if the state is active (machine is currently
/// in this state).
///
///     // 1.
///     isOpen.onEnter.listen((State from) {
///       // onEnter stream event always includes the previous state.
///       print('${from.name} --> ${isOpen.name}');
///     });
///
///     // 2.
///     isOpen.onLeave.listen((State to) {
///       // onLeave stream event always includes the next state.
///       print('${isOpen.name} --> ${to.name}');
///     });
///
///     // 3.
///     isOpen();   // true
///     isClosed(); // false
///
/// It's recommended that states be named in the format "is[State]".
/// This may seem strange at first, but it has two main benefits:
/// 1. It helps differentiate states from transitions, which can be confusing
/// since many words in English are the same as a verb and an adjective
/// ("open" or "secure", for example).
/// 2. It reads better when calling the state to determine if it's active,
/// as demonstrated above when calling `isOpen()` and `isClosed()`.
class State implements Function {
  /// Wildcard state that should be used to define state transitions
  /// that allow transitioning from any state.
  static State any = new State._wildcard();

  /// Name of the state. Used for debugging.
  String name;

  /// [StateMachine] that this state is a part of.
  StateMachine _machine;

  /// Stream of onEnter events from [_onEnterController]
  /// as a broadcast stream.
  Stream _onEnter;

  /// Stream controller used internally to create
  /// the onEnter stream.
  StreamController _onEnterController;

  /// Stream of onLeave events from [_onLeaveController]
  /// as a broadcast stream.
  Stream _onLeave;

  /// Stream controller used internally to create
  /// the onLeave stream.
  StreamController _onLeaveController;

  State._(String this.name, StateMachine this._machine) {
    _onEnterController = new StreamController();
    _onEnter = _onEnterController.stream.asBroadcastStream();
    _onLeaveController = new StreamController();
    _onLeave = _onLeaveController.stream.asBroadcastStream();

    _machine.onStateChange.listen((StateChange stateChange) {
      if (stateChange.from == this) {
        // Left this state. Notify listeners.
        _onLeaveController.add(stateChange.to);
      }
      if (stateChange.to == this) {
        // Entered this state. Notify listeners.
        _onEnterController.add(stateChange.from);
      }
    });
  }

  State._wildcard() {
    name = '__wildcard__';
    _onEnterController = new StreamController();
    _onEnter = _onEnterController.stream.asBroadcastStream();
    _onLeaveController = new StreamController();
    _onLeave = _onLeaveController.stream.asBroadcastStream();
  }

  /// Stream of enter events. Enter event occurs every time
  /// the machine enters this state.
  Stream get onEnter => _onEnter;

  /// Stream of leave events. Leave event occurs every time
  /// the machine leaves this state.
  Stream get onLeave => _onLeave;

  /// Determine whether or not this [State] is active.
  bool call([_]) {
    return _machine.current == this;
  }
}

/// Represents a legal state transition for a  [StateMachine] instance.
///
/// State transitions must be created from a [StateMachine] instance
/// and must define the set of legal "from" states and a single "to"
/// state. The machine must be in one of the "from" states in order
/// for this transition to occur.
///
///     StateMachine door = new StateMachine();
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
/// 1. Listen for the transition events (every time the machine successfully
/// executes this transition).
/// 2. Attempt to execute this transition (will succeed so long as
/// it is legal given the machine's current state and it isn't canceled).
/// 3. Add conditions that can cancel this transition.
///
///     // 1.
///     open.listen((State from) {
///       // transition stream event always includes the previous state,
///       // since transitions can define multiple legal "from" states.
///       print('Door opened.');
///     });
///
///     // 2.
///     open(); // returns `true` since the transition was legal and succeeded.
///
///     // 3.
///     close.cancelIf(() => true); // will cancel the close transition every time
///     close(); // returns `false` since it was canceled
///
/// To get a better idea of how state transitions can be used, consider
/// the following example that integrates two separate state machines
/// to represent the state of a lamp.
///
///     StateMachine powerCord = new StateMachine();
///     State isPluggedIn = powerCord.newState('pluggedIn');
///     State isUnplugged = powerCord.newState('unplugged');
///     StateTransition plugIn = powerCord.newStateTransition('plugIn', [isUnplugged], isPluggedIn);
///     StateTransition unplug = powerCord.newStateTransition('unplug', [isPluggedIn], isUnplugged);
///
///     StateMachine lamp = new StateMachine();
///     State isOn = lamp.newState('on');
///     State isOff = lamp.newState('off');
///     StateTransition turnOn = lamp.newStateTransition('turnOn', [isOff], isOn);
///     StateTransition turnOff = lamp.newStateTransition('turnOff', [isOn], isOff);
///
///     // When the power cord is unplugged, transition the lamp to the
///     // "off" state if it is currently "on".
///     unplug.listen((_) {
///       if (lamp.isOn()) {
///         lamp.turnOff();
///       }
///     });
///
///     // The lamp cannot be turned on if the power cord is unplugged.
///     turnOn.cancelIf(isUnplugged);
///
///     isOn.onEnter.listen((_) => print('Light is on!'));
///     isOn.onLeave.listen((_) => print('Light is off :(');
///
///     powerCord.start(isUnplugged);
///     lamp.start(isOff);
///
///     turnOn(); // canceled, no power
///     plugIn();
///     turnOn(); // "Light is on!"
///     unplug(); // "Light is off :("
class StateTransition implements Function {
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

  /// Stream of transition events from [_streamController] as
  /// a broadcast stream. Transition event occurs every time
  /// this transition executes successfully.
  Stream _stream;

  /// Stream controller used internally to create a stream of
  /// transition events.
  StreamController _streamController;

  /// [State] to transition the machine to when executing
  /// this transition.
  State _to;

  StateTransition._(String this.name, StateMachine this._machine, List<State> this._from, State this._to) {
    if (_to == State.any) throw new ArgumentError('Cannot transition to the wildcard state "State.any"');
    _streamController = new StreamController();
    _stream = _streamController.stream.asBroadcastStream();
  }

  /// Listen for transition events. Transition event occurs every time
  /// this transition executes successfully.
  ///
  /// [onData] will be called with the [State] that was transitioned from.
  StreamSubscription listen(void onData(event),
                            { Function onError,
                              void onDone(),
                              bool cancelOnError}) {
    return _stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  /// Execute this transition. Will call any tests registered
  /// via [cancelIf], canceling the transition if any test
  /// returns true. Otherwise, the transition will occur
  /// and the machine will transition accordingly.
  ///
  /// Returns true if the transition succeeded, false
  /// if it was canceled.
  bool call() {
    // Verify the transition is valid from the current state.
    if (!_from.contains(_machine.current) && !_from.contains(State.any)) {
      throw new IllegalStateTransition(this, _machine.current, _to);
    }

    // Allow transition to be canceled.
    for (int i = 0; i < _cancelTests.length; i++) {
      if (_cancelTests[i](_machine.current)) return false;
    }

    // Transition is legal and wasn't canceled.
    // Update the machine state.
    State from = _machine.current;
    _machine._setState(_to);

    // Notify listeners.
    _streamController.add(from);
    return true;
  }

  /// Add a test that will be called before executing
  /// this transition. If [test] returns true, the
  /// transition will be canceled.
  void cancelIf(bool test(State from)) {
    _cancelTests.add(test);
  }
}

/// An exception that is thrown when attempting to create a new
/// [State] or [StateTransition] for a [StateMachine] instance
/// that has already been started.
class IllegalStateMachineMutation implements Exception {
  String message;
  IllegalStateMachineMutation(String this.message);
  String toString() => 'IllegalStateMachineMutation: $message';
}

/// An exception that is thrown when attempting to execute a
/// state transition for a [StateMachine] instance when the
/// machine is in a state that is not defined as a legal "from"
/// state by the [StateTransition] instance.
class IllegalStateTransition implements Exception {
  State from;
  State to;
  StateTransition transition;
  IllegalStateTransition(StateTransition this.transition, State this.from, State this.to);
  String get message => '("${transition.name}") cannot transition from "${from.name}" to "${to.name}".';
  @override
  String toString() => 'IllegalStateTransition: $message';
}