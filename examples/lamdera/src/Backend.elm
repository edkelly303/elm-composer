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
        , subscriptions = \counter sendToSelf model -> Sub.none
        }
        |> Composer.addComponent (CounterComponent.element { onUpdate = Just BackendCounterComponentUpdated })
        |> Composer.done



init counter sendToSelf =
    ( ()
    , Cmd.none
    )


update counter sendToSelf msg model =
    case msg of
        BackendCounterComponentUpdated count ->
            ( model
            , Lamdera.broadcast (BackendCounterComponentStatusResponded count)
            )


updateFromFrontend counter sendToSelf sessionId clientId msg model =
    case msg of
        BackendCounterComponentUpdateRequested counterMsg ->
            ( model, Task.perform counter (Task.succeed counterMsg) )

        BackendCounterComponentStatusRequested ->
            ( model, Task.perform counter (Task.succeed CounterComponentStatusRequested) )
