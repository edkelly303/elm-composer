
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


## elm-composer's solution

Writing a component is exactly like writing a normal `Browser.element`, except that:

- Your `init`, `update`, `view` and `subscriptions` functions each take 2 extra arguments: `toApp` and `toSelf`, and you rename your `view` function to `interface`.
  - So for example, `view model` becomes `interface toApp toSelf model`.
  - Any messages that you want to send from `Html`, `Cmd` or `Sub` need to be wrapped in one or other of these `toX` functions.

Writing your main app is similar, except the number of additional arguments  for 
`init`, `update`, `view` and `subscriptions` will vary depending on the number of components you want to use:

  - For each component you add, you also add a `nameOfComponent` argument.
  - After the component arguments, you add a `toSelf` argument.
  - So `view model` becomes something like `view myComponent1 myComponent2 toSelf model`.
  - Any messages that you want your main app to send to itself need to be wrapped in `toSelf`.