
# elm-composer

Compose Elm apps with typed message passing


## The problem

| Objective                    | Flat TEA   | Nested TEA | Elm Composed TEA |
| ---------------------------- | ---------- | ---------- | ---------------- |
| Encapsulation                | ❌          | ✅          | ✅                |
| Parent msgs to/from child    | ❌ Pick one | ❌ Pick one | ✅ Both           |
| Child msgs to/from parent    | ❌ Pick one | ❌ Pick one | ✅ Both           |
| View msgs to child or parent | ❌ Pick one | ❌ Pick one | ✅ Both           |
| Easy types                   | ✅          | 🤔          | 🙈                |
| Clear Errors                 | ✅          | 🤔          | 🙈                |


## Elm Compose's solution

Writing a component is exactly like writing a normal `Browser.element`, except that:

- Your `init`, `update`, `view` and `subscriptions` functions each take 2 extra arguments: `sendToApp` and `sendToSelf`.
  - So for example, `view model` becomes `view sendToApp sendToSelf model`.
  - Any messages that you want to send from `Html`, `Cmd` or `Sub` need to be wrapped in one or other of these `sendToX` functions.
- Writing your main app is similar, except the number of additional arguments will vary depending on how many components you have added.
  - So if you have one component, your `init` function will take 2 extra args, `sendToComponent` and `sendToSelf`. If you have two components, it will be `sendToComponent1`, `sendToComponent2` and `sendToSelf`

- The exception is your main app's view function, which also takes a `viewComponent` argument for each component you've added.
  - So `view model` becomes something like `view viewComponent1 sendToComponent1 viewComponent2 sendToComponent2 sendToSelf model`
