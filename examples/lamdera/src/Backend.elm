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
        { init = \sendToCounter sendToSelf -> init |> Tuple.mapSecond (Cmd.map sendToSelf)
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = \sendToCounter sendToSelf model -> Sub.none
        }
        |> Composer.addComponent (CounterComponent.element { onUpdate = Just BackendCounterComponentUpdated })
        |> Composer.done


init : ( BAppModel, Cmd BAppMsg )
init =
    ( ()
    , Cmd.none
    )


update sendToCounter sendToSelf msg model =
    case msg of
        BackendCounterComponentUpdated count ->
            ( model
            , Lamdera.broadcast (BackendCounterComponentStatusResponded count)
            )


updateFromFrontend sendToCounter sendToSelf sessionId clientId msg model =
    case msg of
        BackendCounterComponentUpdateRequested counterMsg ->
            ( model, Task.perform sendToCounter (Task.succeed counterMsg) )

        BackendCounterComponentStatusRequested ->
            ( model, Task.perform sendToCounter (Task.succeed CounterComponentStatusRequested) )
