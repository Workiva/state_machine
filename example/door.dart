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

library state_machine.example.door;

import 'package:state_machine/state_machine.dart';
import 'package:w_common/disposable.dart';

class Door extends Disposable {
  @override
  String get disposableTypeName => 'Door';

  Door() {
    _machine = StateMachine('door');
    manageDisposable(_machine);
    isClosed = _machine.newState('closed');
    isLocked = _machine.newState('locked');
    isOpen = _machine.newState('open');

    close = _machine.newStateTransition('close', [isOpen], isClosed);
    lock = _machine.newStateTransition('lock', [isClosed], isLocked);
    open = _machine.newStateTransition('open', [isClosed], isOpen);
    unlock = _machine.newStateTransition('unlock', [isLocked], isClosed);

    _machine.start(isOpen);
  }

  State isClosed;
  State isLocked;
  State isOpen;

  StateTransition close;
  StateTransition lock;
  StateTransition open;
  StateTransition unlock;

  StateMachine _machine;

  @override
  String toString() => _machine.toString();
}
