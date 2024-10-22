
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

```elm
import Composer.Element as Composer

main =
  Composer.defineApp app
    |> Composer.addComponent component
    |> Composer.run
```

### Huh! But what's `component` in that example?

A component is almost exactly like the record of `init`, `update`, `view` and `subscriptions` functions that you normally pass to `Browser.element`, except that:

- Your `init`, `update`, `view` and `subscriptions` functions each take 2 extra arguments: `toApp` and `toSelf`.
- You rename the `view` function to `interface`.
- For example:
  ```diff
  - view model = ...
  + interface toApp toSelf model = ...
  
  - init flags = ...
  + init toApp toSelf flags = ...

  - update msg model = ...
  + update toApp toSelf msg model = ...

  - subscriptions model = ...
  + subscriptions toApp toSelf model = ...
  ```
- Any messages that you want your component to send itself need to be wrapped in `toSelf`:
  ```diff
  Html
  - Html.Events.onClick Increment
  + Html.Events.onClick (toSelf Increment)

  Cmd
  - Task.perform (\now -> TimeUpdated now) Time.now
  + Task.perform (\now -> toSelf (TimeUpdated now)) Time.now

  Sub
  - Time.every 1000 (\now -> TimeUpdated now)
  + Time.every 1000 (\now -> toSelf (TimeUpdated now))`
  ```  
- If you want your component to send a message to your main app, you need to wrap it in `toApp`. The simplest way to send a message is probably something like this:
  ```elm
  Task.perform (\() -> toApp MainAppMsg) (Task.succeed ())
  ```

### Hmm, ok, and what's `app`?

You define your main app by defining the same record of functions that you would pass to a standard `Browser.element`, `Browser.document` or `Browser.application`, except:

- For each component you want to integrate with your main app, you add a `nameOfComponent` argument to your main app's `init`, `update`, `view` and `subscriptions` functions.
- After these component arguments, you also add a `toSelf` argument.
- For example:
  ```diff
  - view model = ...
  + view myFirstComponent mySecondComponent toSelf model = ...
    
  - init flags = ...
  + init myFirstComponent mySecondComponent toSelf flags = ...

  - update msg model = ...
  + update myFirstComponent mySecondComponent toSelf msg model = ...

  - subscriptions model = ...
  + subscriptions myFirstComponent mySecondComponent toSelf model = ...
  ```
- Any messages that you want your main app to send itself need to be wrapped in `toSelf` (as above).


## `view` versus `interface`

Why did we rename the component's `view` function to `interface`? I'm so glad you asked!

In the first component we write, we will probably do something like this:

```elm
type alias ComponentModel =
  { count : Int
  , ... other fields
  }

type ComponentMsg
  = Increment
  | ... other variants

component =
  { init = ...
  , update = ...
  , subscriptions = ...
  , interface =
    \toApp toSelf model ->
      Html.button
        [ Html.Events.onClick (toSelf Increment) ]
        [ Html.text (String.fromInt model.count) ]
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
        , Html.button
          [ Html.Events.onClick component.increment ]
          [ Html.text (String.fromInt component.count) ]
        ] 
  }
```

The neat thing about this is that it lets us enforce as much or as little encapsulation of our components as we please. 
- The main app cannot directly see what is in the component's model, unless our `interface` function returns that model.
- The main app cannot send messages to the component, unless our `interface` function returns the component's `toSelf` message constructor, or provides specific message variants for the main app to send.

## Couldn't we make it a bit more complicated?

My friend, we are programmers - we can always make things more complicated.

So far, we've got a component that can provide an interface that controls how our main app can interact with it.

But what if we also want the converse: an interface that controls how our component can interact with our main app's model, and specifies what messages it can send to the main app?

This is where `Composer.addComponentWithRequirements` comes in.

Under the covers, when we call the simole baby version of `Composer.addComponent`, what's really happening is this:

```diff
import Composer.Element as Composer

main =
  Composer.defineApp app
-    |> Composer.addComponent
+    |> Composer.addComponentWithRequirements
        component
+        (\toApp appModel -> toApp)
    |> Composer.run
```

As you can see, there's now an extra function passed to each component that specifies the interface that the main app provides to the component. In this case, we simply return the `toApp` message constructor, and that's why we end up with the `toApp` argument being passed to our component's update, view and subscriptions functions.

Now, just as with the `interface` function we defined earlier in our component, this new app interface function can return any type we like. Instead of returning the `toApp` constructor, we might prefer to only expose a limited subset of the variants of the main app's `msg` type, or we might expose a subset of fields from the main app's `model`.

To see how this might work in practice, check out the `DnD` example in the examples folder.
