library state_machine.test.state_machine_test;

import 'dart:async';

import 'package:state_machine/state_machine.dart';
import 'package:test/test.dart';

void main() {
  group('StateMachine', () {
    var machine;
    var state;

    setUp(() {
      machine = new StateMachine();
      state = machine.newState('state');
    });

    test('should be in a dummy state until the machine has been started', () {
      expect(machine.current.name, equals('__none__'));
    });

    test('should throw if machine is started more than once', () {
      machine.start(state);
      expect(() => machine.start(state), throwsStateError);
    });

    test('should fire the onEnter event for the starting state when the machine starts', () async {
      var c = new Completer();
      state.onEnter.listen(c.complete);
      machine.start(state);
      await c.future;
    });

    test('should throw IllegalStateMachineMutation if a state is added after machine has been started', () {
      var error;
      machine.start(state);
      try {
        machine.newState('state2');
      } on IllegalStateMachineMutation catch (e) {
        error = e;
      }
      expect(error, isNotNull);
      expect(error.toString().contains('Cannot create new state (state2)'), isTrue);
    });

    test('should throw IllegalStateMachineMutation if a state transition is added after machine has been started', () {
      var error;
      machine.start(state);
      try {
        machine.newStateTransition('transition', [], state);
      } on IllegalStateMachineMutation catch (e) {
        error = e;
      }
      expect(error, isNotNull);
      expect(error.toString().contains('Cannot create new state transition (transition)'), isTrue);
    });
  });
}