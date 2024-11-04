
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
| Pure Elm (no ports, no JS, no codegen)      | ✅           | ✅                                                     | ✅              |
| No functions in Msg or Model                | ✅           | ✅                                                     | ✅              |
| Framework agnostic (e.g. works with elm-ui) | ✅           | ✅                                                     | ✅              |
| Easy types                                  | ✅           | 🤔                                                     | 🙈              |
| Clear Errors                                | ✅           | 🤔                                                     | 🤮              |


## `elm-composer`'s solution

```elm
import Composer.Element exposing (integrate, withSandbox, withElement, withSimpleComponent, withComponent, groupedAs)
import Browser

main =
  integrate myApp
    |> withSandbox counter
    |> withElement clock
    |> withSimpleComponent stopwatch
    |> withComponent timer (\toApp appModel -> { timerExpired = TimerExpired } )
    |> groupedAs 
      (\counter_ clock_ stopwatch_ timer_ -> 
        { counter = counter_
        , clock = clock_ 
        , stopwatch = stopwatch_
        , timer = timer_
        }
      )
    |> Browser.element
```

### Huh! Ok, talk me through it. What is `myApp` here?

`myApp` is our main application, which we will be integrating various components into. It's going to be a `Browser.element` application, which is why we've imported the `Composer.Element` module here. 

`myApp` should be a record that contains the same four fields that we would usually pass to `Browser.element`: `init`, `update`, `view` and `subscriptions`. But there are a couple of things we'll need to change.

- First, we need to add two extra arguments to `myApp`'s `init`, `update`, `view` and `subscriptions` functions. Let's call those arguments `components` and `toSelf`. For example:
  ```diff  
  - init flags = ...
  + init components toSelf flags = ...

  - update msg model = ...
  + update components toSelf msg model = ...
  
  - view model = ...
  + view components toSelf model = ...
  
  - subscriptions model = ...
  + subscriptions components toSelf model = ...
  ```
- Second, if we want `myApp` to be able to send itself any `Msg`s, we need to wrap those `Msg`s in `toSelf`. For example, in our `init` and `update` functions:
  ```diff
  - Task.perform (\now -> TimeUpdated now) Time.now
  + Task.perform (\now -> toSelf (TimeUpdated now)) Time.now
  ```
  In our `view` function:
  ```diff
  - Html.Events.onClick Increment
  + Html.Events.onClick (toSelf Increment)
  ```
  And in our `subscriptions` function:
  ```diff
  - Time.every 1000 (\now -> TimeUpdated now)
  + Time.every 1000 (\now -> toSelf (TimeUpdated now))`
  ```  

### Ok, I'll trust you on `toSelf`... but what's the `components` argument about?

Patience, friend! First, let's put together the simplest possible example of an app with an integrated component.

Make a file called `Main.elm`, and add the following code::

```elm
-- in Main.elm

module Main exposing (main)

import Html

myApp = 
  { init = 
      \components toSelf flags -> 
        ((), Cmd.none)
  , update = 
      \components toSelf msg model -> 
        ((), Cmd.none)
  , view = 
      \components toSelf model -> 
        Html.div [] 
          [ Html.text "Hello world" ]
  , subscriptions = 
      \components toSelf model -> 
        Sub.none
  }
```

Yes, that's right, it's an app that does absolutely nothing except display "Hello world" in the browser.

We're going to integrate [the `Counter` example from the Elm Guide](https://guide.elm-lang.org/architecture/buttons) into this app. Imagine we've copy-pasted the code from the Elm Guide into a file called `Counter.elm`, and added a module declaration at the top like this:

```elm
-- in Counter.elm

module Counter exposing (init, update, view)
```

Switch back to our `Main.elm` file, and add this:

```elm
-- in Main.elm

import Counter

counter = 
  { init = Counter.init
  , update = Counter.update
  , view = Counter.view
  }
```

Now, let's use `elm-composer` to write our `main` function: 

```elm
-- in Main.elm

import Browser
import Composer.Element exposing (integrate, withSandbox, groupedAs)

main = 
  integrate myApp
  |> withSandbox counter
  |> groupedAs 
    (\counterView -> 
      { counterView = counterView 
      }
    )
  |> Browser.element
```
We can run this in `elm reactor` or (even better) `elm-watch`, and we should see... hmmm... just "Hello world" in our browser. What happened to our counter?

Well, we need to do one more bit of wiring to make this work. Let's revisit `myApp`'s `view` function:

```diff
 -- in Main.elm

   , view = 
       \components toSelf model -> 
         Html.div [] 
-          [ Html.text "Hello world" ]
+          [ Html.text "Here's your counter!"
+          , components.counterView
+          ]
```

Ta-daaa! We should see the Elm Guide's counter in all its glory!

### Ok, what the heck actually happened there?

In our `main` function, we called a function called `groupedAs`. The `groupedAs` function takes the output of our counter component's `view` function (i.e. a value of type `Html Counter.Msg`), converts its `msg` type to a type that is compatible with `elm-composer`, and puts it into a record, under a field called `counterView`.

At runtime, `elm-composer` passes this record into `myApp`s `init`, `update`, `view` and `subscriptions` functions as the first argument, which we've called `components`. 

So, in `myApp`'s `view` function, if we call `components.counterView`, we'll display the output of the counter's  `view` function.

### Climbing the power curve

Let's recap: we now have a component, `counter`, which is effectively a `Browser.sandbox` program, and it's embedded in our main application, `myApp`.

A `sandbox` is great if we just want a component that manages a little bit of state and provides a little bit of interactivity via HTML events. 

But what if we want to do something a bit more powerful - for example, what if we want a component that can send messages via `Cmd` from its `init` and `update` functions and receive messages via `Sub` in its `subscriptions`?

Well, in a very similar analogy to `elm-browser`, we can create a component that is the equivalent of a `Browser.element`, using the `withElement` function.

Let's integrate [the `Clock` example from the Elm Guide](https://guide.elm-lang.org/effects/time) into this app. Copy-paste the code from the Elm Guide into a file called `Clock.elm`, and add a module declaration at the top like this:

```elm
-- in Clock.elm

module Clock exposing (init, update, view, subscriptions)
```
And then add a new component definition in `Main.elm`:
```elm
-- in Main.elm

import Clock

clock = 
  { init = Clock.init
  , update = Clock.update
  , view = Clock.view
  , subscriptions = Clock.subscriptions
  }
```
Then add it to our `main` function:
```diff
 -- in Main.elm

main = 
  integrate myApp
  |> withSandbox counter
+ |> withElement clock
  |> groupedAs 
-    (\counterView -> 
+    (\counterView clockView-> 
       { counterView = counterView 
+      , clockView = clockView
       }
     )
  |> Browser.element
```
And update our `view`:
```diff
 -- in Main.elm

   , view = 
       \components toSelf model -> 
         Html.div [] 
           [ Html.text "Here's your counter!"
           , components.counterView
+          , Html.text "And here's your clock!"
+          , components.clockView
           ]
```

# OLD STUFF


## `view` versus `interface`

Why did we rename the component's `view` function to `interface`? I'm so glad you asked!

In the first component we write, we will probably do something like this:

```elm
type alias CounterModel =
  { count : Int
  , ... other fields
  }

type CounterMsg
  = Increment
  | ... other variants

counter =
  { init = ...
  , update = ...
  , subscriptions = ...
  , interface =
    \toSelf model ->
      Html.button
        [ Html.Events.onClick (toSelf Increment) ]
        [ Html.text (String.fromInt model.count) ]
  }
```

Our `counter` component's `interface` function simply returns a value of type `Html msg`.

Look back at the function that we passed to `Composer.Element.compose` in our `main` function: 

```elm
    |> Composer.Element.compose (\counter_ clock_ -> { counter = counter_, clock = clock_ })
```

This function takes the return value of each component's `interface` function and inserts it into a record. The `counter` component's interface is in the `counter` field of the record, and the `clock` component's interface is in the `clock` field. 

This record is then passed into our main app's `init`, `update`, `view`, and `subscriptions` functions as their first argument. Let's call that argument "components".

Now, if we want to render the HTML returned from our `counter` component's `interface`, all we need to do is add `components.counter` somewhere in our main app's view function, like so:

```elm
myApp =
  { init = ...
  , update = ...
  , subscriptions = ...
  , view =
    \components toSelf model ->
      Html.div []
        [ Html.text "Behold my wondrous counter component!"
        , components.counter
        ] 
  }
```

But! Unlike a normal Elm app's `view` function, there is no need for our `interface` function to return `Html msg`. It can return any type we like.

So, maybe instead of having the component render itself and forcing our main app to live with those rendering decisions, we could instead provide the ingredients the main app will need to render the component properly:

```elm
counter =
  { init = ...
  , update = ...
  , subscriptions = ...
  , interface =
    \toSelf model ->
      { count = model.count
      , increment = toSelf Increment
      }
  }
```

This isn't simply a view, it's an interface - a way to control how the main app is allowed to interact with our component. And we use it thus:

```elm
myApp =
  { init = ...
  , update = ...
  , subscriptions = ...
  , view =
    \components toSelf model ->
      Html.div []
        [ Html.text "Behold my wondrous counter component which I have rendered myself!"
        , Html.button
          [ Html.Events.onClick components.counter.increment ]
          [ Html.text (String.fromInt components.counter.count) ]
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

This is where `Composer.component` comes in.

Under the covers, when we call `Composer.componentSimple`, what's really happening is this:

```diff
import Composer.Element as Composer
import Browser

main =
  Composer.app app
-    |> Composer.componentSimple counter
+    |> Composer.component
+        counter
+        (\toApp appModel -> ())
    |> Composer.Element.componentSimple clock
    |> Composer.Element.compose (\counter_ clock_ -> { counter = counter_, clock = clock_ })
    |> Browser.element
```

As you can see, there's now an extra function passed to each component that specifies the interface that the main app provides to the component. In this case, we simply return the unit type `()`, and that `()` gets passed to our component's `update`, `view` and `subscriptions` functions as the `app` argument.

Now, just as with the `interface` function we defined earlier in our component, this new app interface function can return any type we like. Instead of returning `()`, we might decide expose a limited subset of the variants of the main app's `msg` type, or a subset of fields from the main app's `model`.

To see how this might work in practice, check out the `DnD` example in the examples folder.
