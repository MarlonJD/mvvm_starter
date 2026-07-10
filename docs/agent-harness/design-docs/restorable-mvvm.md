# Restorable MVVM

## Decision

Use Flutter's `RestorationMixin` and `RestorableProperty` APIs for short-lived
UI restoration, while keeping ViewModels responsible for the restorable
properties they coordinate.

Views explicitly register a ViewModel's restorable properties from
`restoreState`. This keeps lifecycle details visible and avoids a magical base
State class that can become hard to adapt for route parameters, nested tabs, or
mixed restorable and non-restorable state.

## Boundaries

Restoration may hold ephemeral UI state:

- Form text.
- Selected tabs.
- Temporary filters.
- Scroll positions.
- Wizard steps.

Restoration must not hold app or domain data:

- Users.
- Sessions.
- Auth tokens.
- Database records.
- Settings.
- Long-lived cache data.

## Pattern

ViewModels that own restorable properties implement a small
`RestorableViewModel` contract. Views using `RestorationMixin` create a
`MixinRestorationRegistrar` and pass it to the ViewModel during
`restoreState`.

Restorable wrappers expose `ValueListenable<T>` publicly instead of mutable
`ValueNotifier<T>`. Mutation should go through controlled methods so
`RestorableProperty.notifyListeners()` cannot be bypassed accidentally.

## Consequences

Login and signup can demonstrate restored form text without pretending that
restoration is durable storage. Future features can copy the explicit
registration pattern, and a base helper can be introduced later only if repeated
boilerplate becomes measurable.
