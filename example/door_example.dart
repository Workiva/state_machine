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

library state_machine.example.door_example;

import 'dart:async';
import 'dart:html';

import 'package:state_machine/state_machine.dart';

import 'door.dart';

Door? door;

activateState(State state) {
  querySelectorAll('.state').forEach((element) {
    element.className = 'state';
  });
  querySelector('#${state.name}')!.className += ' active';
}

closeDoor() {
  querySelector('#door-frame')!.className = 'closed';
}

lockDoor() {
  querySelector('#door-frame')!.className = 'locked';
}

openDoor() {
  querySelector('#door-frame')!.className = 'open';
}

illegalStateTransition(Element state, e) {
  print('');
  print(e);
  state.className += ' illegal';
  Timer(Duration(milliseconds: 100), () {
    state.className = 'state';
  });
}

void main() {
  door = Door();

  // Wire up state changes to DOM changes
  door!.isClosed!.onEnter!.listen((StateChange change) {
    print('');
    print(change);
    print(door);
    activateState(door!.isClosed!);
    closeDoor();
  });

  door!.isLocked!.onEnter!.listen((StateChange change) {
    print('');
    print(change);
    print(door);
    activateState(door!.isLocked!);
    lockDoor();
  });

  door!.isOpen!.onEnter!.listen((StateChange change) {
    print('');
    print(change);
    print(door);
    activateState(door!.isOpen!);
    openDoor();
  });

  // Wire up controls to state machine
  var open = querySelector('#open')!;
  var close = querySelector('#closed')!;
  var lock = querySelector('#locked')!;
  open.onClick.listen((event) {
    try {
      door!.open!();
    } on IllegalStateTransition catch (e) {
      illegalStateTransition(open, e);
    }
  });
  close.onClick.listen((event) {
    try {
      if (door!.isLocked!()) {
        door!.unlock!();
      } else {
        door!.close!();
      }
    } on IllegalStateTransition catch (e) {
      illegalStateTransition(close, e);
    }
  });
  lock.onClick.listen((event) {
    try {
      door!.lock!();
    } on IllegalStateTransition catch (e) {
      illegalStateTransition(lock, e);
    }
  });

  print(door);
  print('');
  print(door!.isOpen);
  print(door!.isClosed);
  print(door!.isLocked);
  print('');
  print(door!.open);
  print(door!.close);
  print(door!.lock);
  print(door!.unlock);
}
