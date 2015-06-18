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
    StateMachine machine;
    State isOn;
    State isOff;
    StateTransition turnOn;

    setUp(() {
      machine = new StateMachine();
      isOn = machine.newState('on');
      isOff = machine.newState('off');
      turnOn = machine.newStateTransition('turnOn', [isOff], isOn);
    });

    test('should have a name', () {
      expect(isOn.name, equals('on'));
    });

    test('should allow listening to onEnter event', () async {
      var c = new Completer();
      isOn.onEnter.listen(c.complete);
      machine.start(isOff);
      turnOn();
      expect((await c.future).from, equals(isOff));
    });

    test('should allow litening to onLeave event', () async {
      var c = new Completer();
      isOff.onLeave.listen(c.complete);
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
  });
}