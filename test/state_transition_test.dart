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

library state_machine.test.state_transition_test;

import 'dart:async';

import 'package:state_machine/state_machine.dart';
import 'package:test/test.dart';

void main() {
  group('StateTransition', () {
    StateMachine machine;
    late State isBroken;
    late State isClosed;
    late State isLocked;
    late State isOpen;
    late StateTransition breakThrough;
    late StateTransition close;
    late StateTransition lock;
    late StateTransition open;
    late StateTransition unlock;

    setUp(() {
      machine = StateMachine('machine');

      isBroken = machine.newState('broken');
      isClosed = machine.newState('closed');
      isLocked = machine.newState('locked');
      isOpen = machine.newState('open');

      close = machine.newStateTransition('close', [isOpen], isClosed);
      lock = machine.newStateTransition('lock', [isOpen, isClosed], isLocked);
      open = machine.newStateTransition('open', [isClosed, isLocked], isOpen);
      unlock = machine.newStateTransition('unlock', [isLocked], isClosed);
      breakThrough =
          machine.newStateTransition('breakThrough', [State.any], isBroken);

      machine.start(isOpen);
    });

    test('should have a name', () {
      expect(close.name, equals('close'));
    });

    test('should allow listening', () async {
      var c = Completer();
      // ignore: deprecated_member_use_from_same_package
      close.listen(c.complete);
      expect(close(), isTrue);
      expect((await c.future).from, equals(isOpen));
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

    test('should allow transitioning from any state via the wildcard state',
        () async {
      var c = Completer();
      var fromStates = [];
      breakThrough.stream!.listen((StateChange stateChange) {
        fromStates.add(stateChange.from);
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

    test('.toString() should provide a helpful result', () {
      String closeStr = close.toString();
      expect(closeStr, contains(close.name));
      expect(closeStr, contains(isOpen.name));
      expect(closeStr, contains(isClosed.name));

      String openStr = open.toString();
      expect(openStr, contains(open.name));
      expect(openStr, contains(isClosed.name));
      expect(openStr, contains(isLocked.name));
      expect(openStr, contains(isOpen.name));
    });

    test('.toString() should provide a helpful result for the state change',
        () async {
      Completer closeC = Completer();
      Completer openC = Completer();

      isOpen.onEnter!.listen((stateChange) {
        // state change from the transition to initial starting state
        String s = stateChange.toString();
        expect(s, contains('(none)'));
        expect(s, contains(isOpen.name));
        openC.complete();
      });

      isClosed.onEnter!.listen((stateChange) {
        // manual state change, which should have a payload
        String s = stateChange.toString();
        expect(s, contains(isOpen.name));
        expect(s, contains(isClosed.name));
        expect(s, contains('payload: payload'));
        closeC.complete();
      });

      close('payload');
      await Future.wait([closeC.future, openC.future]);
    });
  });
}
