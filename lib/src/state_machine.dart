library state_machine.src.state_machine;

import 'dart:async';

/// A simple, typed finite state machine.
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

class IllegalStateMachineMutation implements Exception {
  String message;
  IllegalStateMachineMutation(String this.message);
  String toString() => 'IllegalStateMachineMutation: $message';
}

class IllegalStateTransition implements Exception {
  State from;
  State to;
  StateTransition transition;
  IllegalStateTransition(StateTransition this.transition, State this.from, State this.to);
  String get message => '("${transition.name}") cannot transition from "${from.name}" to "${to.name}".';
  @override
  String toString() => 'IllegalStateTransition: $message';
}