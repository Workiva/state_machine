library state_machine.example.door_example;

import 'dart:async';
import 'dart:html';

import 'package:state_machine/state_machine.dart';

import 'door.dart';

Door door;

activateState(State state) {
  querySelectorAll('.state').forEach((element) {
    element.className = 'state';
  });
  querySelector('#${state.name}').className += ' active';
}

closeDoor() {
  querySelector('#door-frame').className = 'closed';
}

lockDoor() {
  querySelector('#door-frame').className = 'locked';
}

openDoor() {
  querySelector('#door-frame').className = 'open';
}

illegalStateTransition(Element state) {
  state.className += ' illegal';
  new Timer(new Duration(milliseconds: 100), () {
    state.className = 'state';
  });
}

void main() {
  door = new Door();

  // Wire up state changes to DOM changes
  door.isClosed.onEnter.listen((State from) {
    activateState(door.isClosed);
    closeDoor();
  });

  door.isLocked.onEnter.listen((State from) {
    activateState(door.isLocked);
    lockDoor();
  });

  door.isOpen.onEnter.listen((State from) {
    activateState(door.isOpen);
    openDoor();
  });

  // Wire up controls to state machine
  var open = querySelector('#open');
  var close = querySelector('#closed');
  var lock = querySelector('#locked');
  open.onClick.listen((event) {
    try {
      door.open();
    } on IllegalStateTransition catch (e) {
      illegalStateTransition(open);
    }
  });
  close.onClick.listen((event) {
    if (door.isLocked()) {
      door.unlock();
    } else {
      door.close();
    }
  });
  lock.onClick.listen((event) {
    try {
      door.lock();
    } on IllegalStateTransition catch (e) {
      illegalStateTransition(lock);
    }
  });
}