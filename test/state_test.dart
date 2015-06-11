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
      expect(await c.future, equals(isOff));
    });

    test('should allow litening to onLeave event', () async {
      var c = new Completer();
      isOff.onLeave.listen(c.complete);
      machine.start(isOff);
      turnOn();
      expect(await c.future, equals(isOn));
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