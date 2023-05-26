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

@TestOn('vm || browser')
library state_machine.test.state_machine_test;

import 'dart:async';

import 'package:state_machine/state_machine.dart';
import 'package:test/test.dart';

void main() {
  group('StateMachine', () {
    late StateMachine machine;
    late State state;

    setUp(() {
      machine = StateMachine('machine');
      state = machine.newState('state');
    });

    test('should be in a dummy state until the machine has been started', () {
      expect(machine.current!.name, equals('__none__'));
    });

    test('should throw if machine is started more than once', () {
      machine.start(state);
      expect(() => machine.start(state), throwsStateError);
    });

    test(
        'should fire the onEnter event for the starting state when the machine starts',
        () async {
      var c = Completer();
      state.onEnter!.listen(c.complete);
      machine.start(state);
      await c.future;
    });

    test(
        'should throw IllegalStateMachineMutation if a state is added after machine has been started',
        () {
      var error;
      machine.start(state);
      try {
        machine.newState('state2');
      } on IllegalStateMachineMutation catch (e) {
        error = e;
      }
      expect(error, isNotNull);
      expect(error.toString().contains('Cannot create new state (state2)'),
          isTrue);
    });

    test(
        'should throw IllegalStateMachineMutation if a state transition is added after machine has been started',
        () {
      var error;
      machine.start(state);
      try {
        machine.newStateTransition('transition', [], state);
      } on IllegalStateMachineMutation catch (e) {
        error = e;
      }
      expect(error, isNotNull);
      expect(
          error
              .toString()
              .contains('Cannot create new state transition (transition)'),
          isTrue);
    });

    test('.toString() should provide a helpful result', () {
      machine.start(state);
      String s = machine.toString();
      expect(s, contains(machine.name));
      expect(s, contains('${state.name} (active)'));
    });
  });
}
