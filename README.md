
# elm-composer

Compose Elm apps with typed message passing


## The problem

| Objective                                   | ☕ Flat TEA  | ☕ Nested TEA                                          | 🎼 elm-composer |
| ------------------------------------------- | ------------ | ------------------------------------------------------ | --------------- |
| Component model is independent of app model | ❌           | ❌ app model contains component model                  | ✅              |
| Component msg is independent of app msg     | ❌           | ❌ component msg is wrapped in app msg                 | ✅              |
| Component handles its own initialisation    | ❌           | ❌ app calls component's init                          | ✅              |
| Component handles its own updates           | ❌           | ❌ app's update calls component's update               | ✅              |
| Component handles its own subscriptions     | ❌           | ❌ app's subscriptions calls component's subscriptions | ✅              |
| Component generates its own view            | ❌           | ❌ app's view calls component's view                   | ✅ (optional)   |
| Easy types                                  | ✅           | 🤔                                                     | 🙈              |
| Clear Errors                                | ✅           | 🤔                                                     | 🤮              |


## elm-composer's solution

Writing a component is exactly like writing a normal `Browser.element`, except that:

- Your `init`, `update`, `view` and `subscriptions` functions each take 2 extra arguments: `toApp` and `toSelf`.
- You rename your `view` function to `interface`. For example:
  - `init flags` ➡️ `init toApp toSelf flags`
  - `update msg model` ➡️ `update toApp toSelf msg model`
  - `view model` ➡️ `interface toApp toSelf model`
  - `subscriptions model` ➡️ `subscriptions toApp toSelf model`
- Any messages that you want your component to send itself need to be wrapped in `toSelf`:
  - Html: `Html.Events.onClick Increment` ➡️ `Html.Events.onClick (toSelf Increment)`
  - Cmd: `Task.perform (\now -> TimeUpdated now) Time.now` ➡️ `Task.perform (\now -> toSelf (TimeUpdated now)) Time.now`
  - Sub: `Time.every 1000 (\now -> TimeUpdated now)` ➡️ `Time.every 1000 (\now -> toSelf (TimeUpdated now))`

Writing your main app is similar, except the number of additional arguments  for 
`init`, `update`, `view` and `subscriptions` will vary depending on the number of components you want to use:

- For each component you add, you also add a `nameOfComponent` argument.
- After the component arguments, you add a `toSelf` argument. For example:
  - `init flags` ➡️ `init myFirstComponent mySecondComponent toSelf flags`
  - `update msg model` ➡️ `update myFirstComponent mySecondComponent toSelf msg model`
  - `view model` ➡️ `view myFirstComponent mySecondComponent toSelf model`
  - `subscriptions model` ➡️ `subscriptions myFirstComponent mySecondComponent toSelf model`
- Any messages that you want your main app to send itself need to be wrapped in `toSelf` (as above).


## `view` versus `interface`

Why did we rename the component's `view` function to `interface`? I'm so glad you asked.

In the first component we write, we will probably do something like this:

```elm
component =
  { init = ...
  , update = ...
  , subscriptions = ...
  , interface =
    \toApp toSelf model ->
      Html.button [ Html.Events.onClick (toSelf Increment) ] [ Html.text (String.fromInt model.count) ]
  }
```

Our component's `interface` function simply returns a value of type `Html msg`.

The return value of the `interface` function automatically gets passed into our main app, as an argument to its `init`, `update`, `view`, and `subscriptions` functions. Let's call that argument "component".

So, if we want to render the HTML returned from our component's `interface`, all we need to do is use the `component` argument somewhere in our main app's view function, like so:

```elm
app =
  { init = ...
  , update = ...
  , subscriptions = ...
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
  , subscriptions = ...
  , interface =
    \toApp toSelf model ->
      { count = model.count
      , increment = toSelf Increment
      }
  }
```

This isn't simply a view, it's an interface - a way to control how the main app is allowed to interact with our component. And we use it thus:

```elm
app =
  { init = ...
  , update = ...
  , subscriptions = ...
  , view =
    \component toSelf model ->
      Html.div []
        [ Html.text "Behold my wondrous component which I have rendered myself!"
        , Html.button [ Html.Events.onClick component.increment ] [ Html.text (String.fromInt component.count) ]
        ] 
  }
```

The neat thing about this is that it lets us enforce as much or as little encapsulation of our components as we please. 
- The main app cannot directly see what is in the component's model, unless our `interface` function returns that model.
- The main app cannot send messages to the component, unless our `interface` function returns the component's `toSelf` message constructor, or provides specific message variants for the main app to send.
