/// A simple, typed finite state machine library.
///
/// State machines are created by defining a set
/// of states and a set of legal state transitions.
///
/// These machines can be used inline, or they can
/// be easily wrapped in a class to provide a more
/// formal API by directly exposing the [State]s
/// and [StateTransition]s directly.
///
/// Simple usage:
///
///     StateMachine door = new StateMachine();
///     State isOpen = door.newState('open');
///     State isClosed = door.newState('closed');
///     StateTransition open = door.newStateTransition('open', [isClosed], isOpen);
///     StateTransition close = door.newStateTransition('close', [isOpen], isClosed);
///
///     door.start(isOpen);
///     close();
///     isClosed(); // true
///
/// Wrapping in a class:
///
///     class Door {
///       State isOpen;
///       State isClosed;
///
///       StateTransition open;
///       StateTransition close;
///
///       StateMachine _machine;
///
///       Door() {
///         _machine = new StateMachine();
///         isOpen = _machine.newState('open');
///         isClosed = _machine.newState('closed');
///         open = _machine.newStateTransition('open', [isClosed], isOpen);
///         close = _machine.newStateTransition('close', [isOpen], isClosed);
///         _machine.start(isOpen);
///       }
///     }
///
///     void main() {
///       Door door = new Door();
///
///       // Exposing the [State] and [StateTransition] objects
///       // created a useful and understandable API for the Door
///       // class without any extra work!
///       door.close();
///       door.isClosed(); // true
///     }
library state_machine;

export 'src/exceptions.dart' show IllegalStateMachineMutation, IllegalStateTransition;
export 'src/state_machine.dart' show State, StateChange, StateMachine, StateTransition;