# Core Beliefs

## Repository Knowledge Beats Chat Memory

If future agents need to know something, it belongs in the repository. Chat
history can explain the moment, but repo files must carry the durable rule.

## Agents Need Maps, Not Encyclopedias

The root instruction file should stay short. It should point to focused files
that can be read only when relevant.

## Simple Architecture Is A Force Multiplier

The MVVM shape should remain predictable. New abstractions need a real reason:
shared behavior, reduced duplication, or a boundary that makes tests easier.

## Verification Is Part Of The Feature

Behavior is not complete until it can be checked. For most work, that means
`flutter analyze`, `flutter test`, or a documented reason a narrower check is
enough.

## Repeated Advice Should Become A Check

If reviewers or agents repeat the same guidance, promote it into a lint, test,
script, template, or harness document.

## Technical Debt Should Be Small And Visible

Debt should be tracked when accepted. Prefer small cleanup plans over rare large
cleanup pushes.
