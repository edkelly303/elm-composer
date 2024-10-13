module Backend exposing (..)

import Composer.Lamdera.Backend as Composer
import CounterComponent
import Html
import Lamdera exposing (ClientId, SessionId)
import Process
import Task
import Types exposing (..)


app =
    Lamdera.backend composition


composition =
    Composer.defineApp
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = \counter toSelf model -> Sub.none
        }
        |> Composer.addComponent (CounterComponent.element { onUpdate = Just BackendCounterComponentUpdated })
        |> Composer.done


init counter toSelf =
    ( ()
    , Cmd.none
    )


update counter toSelf msg model =
    case msg of
        BackendCounterComponentUpdated count ->
            ( model
            , Lamdera.broadcast (BackendCounterComponentStatusResponded count)
            )


updateFromFrontend counter toSelf sessionId clientId msg model =
    case msg of
        BackendCounterComponentUpdateRequested counterMsg ->
            ( model, Task.perform counter (Task.succeed counterMsg) )

        BackendCounterComponentStatusRequested ->
            ( model, Task.perform counter (Task.succeed CounterComponentStatusRequested) )
