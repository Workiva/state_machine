library state_machine.test.state_transition_test;

import 'dart:async';

import 'package:state_machine/state_machine.dart';
import 'package:test/test.dart';

void main() {
  group('StateTransition', () {
    StateMachine machine;
    State isBroken;
    State isClosed;
    State isLocked;
    State isOpen;
    StateTransition breakThrough;
    StateTransition close;
    StateTransition lock;
    StateTransition open;
    StateTransition unlock;

    setUp(() {
      machine = new StateMachine();

      isBroken = machine.newState('broken');
      isClosed = machine.newState('closed');
      isLocked = machine.newState('locked');
      isOpen = machine.newState('open');

      close = machine.newStateTransition('close', [isOpen], isClosed);
      lock = machine.newStateTransition('lock', [isOpen, isClosed], isLocked);
      open = machine.newStateTransition('open', [isClosed, isLocked], isOpen);
      unlock = machine.newStateTransition('unlock', [isLocked], isClosed);
      breakThrough = machine.newStateTransition('breakThrough', [State.any], isBroken);

      machine.start(isOpen);
    });

    test('should have a name', () {
      expect(close.name, equals('close'));
    });

    test('should allow listening', () async {
      var c = new Completer();
      close.listen(c.complete);
      expect(close(), isTrue);
      expect(await c.future, equals(isOpen));
    });

    test('should be callable to execute the transition', () {
      // door is open, so close() should succeed
      expect(close(), isTrue);
      // door is closed, so lock() should succeed
      expect(lock(), isTrue);
      // door is not open, so close() should fail
      expect(() => close(), throwsException);
    });

    test('should allow cancellation', () {
      breakThrough.cancelIf(isLocked);
      lock();
      expect(breakThrough(), isFalse);
      unlock();
      expect(breakThrough(), isTrue);
    });

    test('should allow multiple cancellation conditions', () {
      breakThrough.cancelIf(isLocked);
      breakThrough.cancelIf(isOpen);
      lock();
      expect(breakThrough(), isFalse);
      open();
      expect(breakThrough(), isFalse);
      close();
      expect(breakThrough(), isTrue);
    });

    test('should allow transitioning from any state via the wildcard state', () async {
      var c = new Completer();
      var fromStates = [];
      breakThrough.listen((State from) {
        fromStates.add(from);
        if (fromStates.length >= 2) {
          c.complete();
        }
      });
      breakThrough();
      breakThrough();
      await c.future;
      expect(fromStates, equals([isOpen, isBroken]));
    });

    test('should throw an IllegalStateTransition if transition is illegal', () {
      lock();
      var error;
      try {
        close();
      } on IllegalStateTransition catch (e) {
        error = e;
      }
      expect(error, isNotNull);
      expect(error.message.contains('("close")'), isTrue);
      expect(error.toString().contains('from "locked" to "closed"'), isTrue);
    });
  });
}