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

library state_machine.test.state_test;

import 'dart:async';

import 'package:state_machine/state_machine.dart';
import 'package:test/test.dart';

void main() {
  group('State', () {
    late StateMachine machine;
    late State isOn;
    late State isOff;
    late StateTransition turnOn;

    setUp(() {
      machine = StateMachine('machine');
      isOn = machine.newState('on');
      isOff = machine.newState('off');
      turnOn = machine.newStateTransition('turnOn', [isOff], isOn);
    });

    test('should have a name', () {
      expect(isOn.name, equals('on'));
    });

    test('should allow listening to onEnter event', () async {
      var c = Completer();
      isOn.onEnter!.listen(c.complete);
      machine.start(isOff);
      turnOn();
      expect((await c.future).from, equals(isOff));
    });

    test('should allow litening to onLeave event', () async {
      var c = Completer();
      isOff.onLeave!.listen(c.complete);
      machine.start(isOff);
      turnOn();
      expect((await c.future).to, equals(isOn));
    });

    test('should be callable to determine if active', () {
      expect(isOn(), isFalse);
      expect(isOff(), isFalse);
      machine.start(isOff);
      expect(isOff(), isTrue);
      turnOn();
      expect(isOn(), isTrue);
    });

    test('.toString() should provide a helpful result', () async {
      machine.start(isOn);
      await isOn.onEnter!.first;

      String isOnStr = isOn.toString();
      expect(isOnStr, contains(isOn.name));
      expect(isOnStr, contains(machine.name));
      expect(isOnStr, contains('active: true'));

      String isOffStr = isOff.toString();
      expect(isOffStr, contains(isOff.name));
      expect(isOffStr, contains(machine.name));
      expect(isOffStr, contains('active: false'));
    });

    test('.toString() should explain what the __none__ state means', () {
      State? noneState = machine.current;
      String s = noneState.toString();
      expect(s, contains('machine has yet to start'));
      expect(s, isNot(contains('__none__')));
    });

    test('canCall should return accordingly', () async {
      var c = Completer();
      isOff.onLeave!.listen(c.complete);
      machine.start(isOff);
      expect(turnOn.canCall(), isTrue);
      turnOn();
      expect(isOn(), isTrue);
      expect((await c.future).to, equals(isOn));
      expect(turnOn.canCall(), isFalse);
    });
  });
}
