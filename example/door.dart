library state_machine.example.door;

import 'package:state_machine/state_machine.dart';

class Door {
  Door() {
    _machine = new StateMachine();

    isClosed = _machine.newState('closed');
    isLocked = _machine.newState('locked');
    isOpen = _machine.newState('open', isStartingState: true);

    close = _machine.newStateTransition('close', [isOpen], isClosed);
    lock = _machine.newStateTransition('lock', [isClosed], isLocked);
    open = _machine.newStateTransition('open', [isClosed], isOpen);
    unlock = _machine.newStateTransition('unlock', [isLocked], isClosed);
  }

  State isClosed;
  State isLocked;
  State isOpen;

  StateTransition close;
  StateTransition lock;
  StateTransition open;
  StateTransition unlock;

  StateMachine _machine;
}