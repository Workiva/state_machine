library state_machine.src.exceptions;

import 'package:state_machine/src/state_machine.dart';

/// An exception that is thrown when attempting to create a new
/// [State] or [StateTransition] for a [StateMachine] instance
/// that has already been started.
class IllegalStateMachineMutation implements Exception {
  String message;
  IllegalStateMachineMutation(String this.message);
  String toString() => 'IllegalStateMachineMutation: $message';
}

/// An exception that is thrown when attempting to execute a
/// state transition for a [StateMachine] instance when the
/// machine is in a state that is not defined as a legal "from"
/// state by the [StateTransition] instance.
class IllegalStateTransition implements Exception {
  State from;
  State to;
  StateTransition transition;
  IllegalStateTransition(StateTransition this.transition, State this.from, State this.to);
  String get message => '("${transition.name}") cannot transition from "${from.name}" to "${to.name}".';
  @override
  String toString() => 'IllegalStateTransition: $message';
}