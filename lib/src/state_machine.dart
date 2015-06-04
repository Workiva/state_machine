library state_machine.src.state_machine;

import 'dart:async';

// TODO: make state transitions return future so they can be awaited?

class StateMachine {
  StateMachine() {
    _stateChangeController = new StreamController();
    _stateChange = _stateChangeController.stream.asBroadcastStream();

    current = new State._('__none__', this);
  }

  /// [State] that the machine is currently in.
  State current;

  /// Stream of state change events. This allows [State]s
  /// and [StateTransition]s to listen for state changes
  /// and notify listeners as necessary.
  ///
  /// The event payload will be the previous [State].
  Stream<StateChange> _stateChange;
  StreamController _stateChangeController;

  /// Set the machine state and trigger a state change event.
  void _setState(State state) {
    State previous = current;
    current = state;
    _stateChangeController.add(new StateChange(previous, current));
  }

  State newState(String name, {bool isStartingState: false}) {
    State state = new State._(name, this);
    if (isStartingState) {
      current = state;
    }
    return state;
  }

  StateTransition newStateTransition(String name, List<State> from, State to) {
    return new StateTransition._(name, this, from, to);
  }
}

class StateChange {
  StateChange(this.from, this.to);
  State from;
  State to;
}

class State {
  State._(String this.name, StateMachine this._machine) {
    _onEnterController = new StreamController();
    _onEnter = _onEnterController.stream.asBroadcastStream();
    _onLeaveController = new StreamController();
    _onLeave = _onLeaveController.stream.asBroadcastStream();

    _machine._stateChange.listen((StateChange stateChange) {
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

  /// Name of the state. Used for debugging.
  String name;

  /// Stream of enter events. Enter event occurs every time
  /// the machine enters this state.
  Stream get onEnter => _onEnter;
  Stream _onEnter;
  StreamController _onEnterController;

  /// Stream of leave events. Leave event occurs every time
  /// the machine leaves this state.
  Stream get onLeave => _onLeave;
  Stream _onLeave;
  StreamController _onLeaveController;

  /// [StateMachine] that this state is a part of.
  StateMachine _machine;

  /// Determine whether or not this [State] is active.
  bool call() {
    return _machine.current == this;
  }
}

class StateTransition {
  StateTransition._(String this.name, StateMachine this._machine, List<State> this._from, State this._to) {
    _streamController = new StreamController();
    _stream = _streamController.stream.asBroadcastStream();
  }

  /// Name of the state transition. Used for debugging.
  String name;

  /// Listen for transition events. Transition event occurs every time
  /// this transition executes successfully.
  StreamSubscription listen(void onData(event),
                            { Function onError,
                              void onDone(),
                              bool cancelOnError}) {
    return _stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  /// List of cancel tests registered via [cancelIf]
  /// that will be called before executing this transition.
  List<Function> _cancelTests = [];

  /// List of valid [State]s that the machine must be in
  /// for this transition to occur.
  List<State> _from;

  /// [StateMachine] that this state transition is a part of.
  StateMachine _machine;

  /// Stream of transition events. Transition event occurs every time
  /// this transition executes successfully.
  Stream _stream;
  StreamController _streamController;

  /// [State] to transition the machine to when executing
  /// this transition.
  State _to;

  /// Execute this transition. Will call any tests registered
  /// via [cancelIf], canceling the transition if any test
  /// returns true. Otherwise, the transition will occur
  /// and the machine will transition accordingly.
  void call() {
    // Verify the transition is valid from the current state.
    if (!_from.contains(_machine.current)) {
      throw new IllegalStateTransition();
    }

    // Allow transition to be canceled.
    for (int i = 0; i < _cancelTests.length; i++) {
      if (_cancelTests[i](_machine.current)) return;
    }

    // Transition is legal and wasn't canceled.
    // Update the machine state.
    State from = _machine.current;
    _machine._setState(_to);

    // Notify listeners.
    _streamController.add(from);
  }

  /// Add a test that will be called before executing
  /// this transition. If [test] returns true, the
  /// transition will be canceled.
  void cancelIf(bool test(State from)) {
    _cancelTests.add(test);
  }
}

class IllegalStateTransition implements Exception {
  IllegalStateTransition();
}