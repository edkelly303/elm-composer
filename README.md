
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


## `view` versus `interface`

Why did we rename the component's `view` function to `interface`? I'm so glad you asked.

In the first component we write, we will probably do something like this:

```elm
component =
  { init = ...
  , update = ...
``, subscriptions = ...
  , interface =
    \toApp toSelf model ->
      Html.button [ Html.Events.onClick (toSelf Increment) ] [ Html.text (String.fromInt model.count) ]
  }
```

and then in our main app, we'll do this:

```elm
app =
component =
  { init = ...
  , update = ...
``, subscriptions = ...
  , view =
    \component toSelf model ->
      Html.div []
        [ Html.text "Behold my wondrous component!"
        , component
        ] 
  }
```

But! Unlike a normal Elm app's `view` function, there is no need for our `interface` function to return `Html msg`. It can return any type we like.

So, maybe instead of having the component render itself and forcing our main app to live with those rendering decisions, we could instead provide the ingredients the main app will need to render the component properly:

```elm
component =
  { init = ...
  , update = ...
``, subscriptions = ...
  , interface =
    \toApp toSelf model ->
      { count = model.count
      , increment = toSelf Increment
      }
  }
```

```elm
app =
component =
  { init = ...
  , update = ...
``, subscriptions = ...
  , view =
    \component toSelf model ->
      Html.div []
        [ Html.text "Behold my wondrous component which I have rendered myself!"
        , Html.button [ Html.Events.onClick component.increment ] [ Html.text (String.fromInt component.count) ]
        ] 
  }
```
