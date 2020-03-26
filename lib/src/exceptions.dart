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
