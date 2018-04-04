# Dart State Machine
[![Pub](https://img.shields.io/pub/v/state_machine.svg)](https://pub.dartlang.org/packages/state_machine)
[![Build Status](https://travis-ci.org/Workiva/state_machine.svg?branch=master)](https://travis-ci.org/Workiva/state_machine)
[![codecov.io](https://codecov.io/gh/Workiva/state_machine/branch/master/graph/badge.svg)](http://codecov.io/github/Workiva/state_machine?branch=master)
[![documentation](https://img.shields.io/badge/Documentation-state_machine-blue.svg)](https://www.dartdocs.org/documentation/state_machine/latest/)

> Easily create a finite state machine and define legal state transitions. Listen to state entrances, departures, and transitions.

## Getting Started
Import the `state_machine` package:

```dart
import 'package:state_machine/state_machine.dart';
```

### Create a Machine
Once created, the `StateMachine` will be used to create states and state transitions.

```dart
StateMachine light = new StateMachine('light');
```

### Define a Set of States
Use the machine to create all required states. A string name is required for ease of debugging.
 
```dart
State isOn = light.newState('on');
State isOff = light.newState('off');
```

It's recommended that states be named in the format "is[State]".
This may seem strange at first, but it has two main benefits:

1. It helps differentiate states from transitions, which can be confusing
since many words in English are the same as a verb and an adjective
("open" or "secure", for example).
2. It reads better when calling the state to determine if it's active,
as will be demonstrated later.

### Define the Legal State Transitions
By defining legal state transitions, you can prevent certain actions based on the current state of the machine.
Defining a state transition requires a name (again for ease of debugging), a list of valid "from" states, and
the state to transition the machine to.

```dart
StateTransition turnOn = light.newStateTransition('turnOn', [isOff], isOn);
StateTransition turnOff = light.newStateTransition('turnOff', [isOn], isOff);
```

### Start the Machine
Before executing any state transitions, the machine should be started at a specific starting state.

```dart
light.start(isOff);
```

### Executing a State Transition
The `StateTransition` class implements `Function` so that you can simply call a transition to execute it.

```dart
light.start(isOff);
turnOn(); // transitions machine from "isOff" to "isOn"
```

### Determining the Active State
The `StateMachine` instance exposes a `current` state property which allows you to retrieve the machine's current state
at any time.

```dart
light.start(isOff);
light.current == isOff; // true
```

Additionally, the `State` class implements `Function` so that you can simply call a state to determine if it's active.

```dart
light.start(isOff);
isOff(); // true
isOn();  // false
```

### Listening to State Transitions
The `StateTransition` class exposes a `listen()` method that allows you to listen to the transition and receive an
event every time the transition executes.

```dart
turnOn.listen((StateChange change) {
  print('Light transitioned from ${change.from.name} to ${change.to.name}');
});
light.start(isOff);
turnOn(); // "Light transitioned from off to on"
```

### Passing Data with a State Transition
State transitions accept an optional payload in case you need to pass data along to listeners.

```dart
turnOn.listen((StateChange change) {
  print('Light turned on. Wattage: ${change.payload}');
});
light.start(isOff);
turnOn('15w'); // "Light turned on. Wattage: 15w"
```

### Listening for State Entrances and Departures
The `State` class exposes two streams so that you can listen for the state being entered and the state being left.

```dart
isOff.onLeave.listen((StateChange change) {
  print('Left: off');
});
isOn.onEnter.listen((StateChange change) {
  print('Entered: on');
});
light.start(isOff);
turnOn(); // "Left: off"
          // "Entered: on"
```

### Wildcard State and State Transitions
The `State` class exposes a static instance `State.any` that can be used as a wildcard when defining a state transition.

```dart
StateMachine machine = new StateMachine('machine');
State isFailed = machine.newState('failed');

// This transition will be valid regardless of which state the machine is in.
StateTransition fail = machine.newStateTransition('fail', [State.any], isFailed);
```

### Illegal State Transitions
When you create state transitions, you must define the list of valid "from" states. The machine must be in one of these
states in order to execute the transition. If that's not the case, an `IllegalStateTransition` exception will be thrown.

```dart
// Consider a door with the following states and transitions.
StateMachine door = new StateMachine('door');

State isOpen = door.newState('open');
State isClosed = door.newState('closed');
State isLocked = door.newState('locked');

StateTransition open = door.newStateTransition('open', [isClosed], isOpen);
StateTransition close = door.newStateTransition('close', [isOpen], isClosed);
StateTransition lock = door.newStateTransition('lock', [isClosed], isLocked);
StateTransition unlock = door.newStateTransition('unlock', [isLocked], isClosed);

// Let's transition the door from open, to closed, to locked.
door.start(isOpen);
close();
lock();

// In order to open the door, we must first unlock it.
// If we try to open it first, an exception will be thrown.
open(); // throws IllegalStateTransition
```

### Canceling State Transitions
State machines have a set of legal state transitions that are set in stone and provide the required structure.
But, there may be scenarios where a state transition may or may not be desirable based on additional logic.
To handle this, state transitions support cancellation conditions.

```dart
// Consider two state machines - a person and a door.
// The door can be locked or unlocked and the person
// can be with or without a key.
StateMachine door = new StateMachine('door');
State isLocked = door.newState('locked');
State isUnlocked = door.newState('unlocked');
StateTransition unlock = door.newStateTransition('unlock', [isLocked], isUnlocked);

StateMachine person = new StateMachine('person');
State isWithKey = person.newState('withKey');
State isWithoutKey = person.newState('withoutKey');
StateTransition obtainKey = person.newStateTransition('obtainKey', [isWithoutKey], isWithKey);

door.start(isLocked);
person.start(isWithoutKey);

// Add a cancellation condition for unlocking the door:
// If the person is without a key, cancel the unlock transition.
unlock.cancelIf((StateChange change) => isWithoutKey());

unlock(); // false (canceled)
isUnlocked(); // false
obtainKey();
unlock(); // true (not canceled)
isUnlocked(); // true
```


## Development

This project leverages [the dart_dev package](https://github.com/Workiva/dart_dev)
for most of its tooling needs, including static analysis, code formatting,
running tests, collecting coverage, and serving examples. Check out the dart_dev
readme for more information.
