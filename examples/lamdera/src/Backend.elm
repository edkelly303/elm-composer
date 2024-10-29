module Backend exposing (..)

import Composer.Lamdera.Backend as Composer
import Counter
import Html
import Lamdera exposing (ClientId, SessionId)
import Process
import Task
import Types exposing (..)


app =
    Lamdera.backend composition


composition =
    Composer.app
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = subscriptions
        }
        |> Composer.component
            Counter.component
            (\toApp appModel -> { countChanged = toApp << BackendCounterComponentUpdated })
        |> Composer.compose (\c -> { counter = c })


subscriptions counter toSelf model =
    Sub.none


init components toSelf =
    ( ()
    , Cmd.none
    )


update components toSelf msg model =
    case msg of
        BackendCounterComponentUpdated count ->
            ( model
            , Lamdera.broadcast (BackendCounterComponentStatusResponded count)
            )


updateFromFrontend components toSelf sessionId clientId msg model =
    case msg of
        BackendCounterComponentUpdateRequested counterMsg ->
            ( model
            , case counterMsg of
                Increment ->
                    Task.perform identity (Task.succeed components.counter.increment)

                Decrement ->
                    Task.perform identity (Task.succeed components.counter.decrement)
            )

        BackendCounterComponentStatusRequested ->
            ( model
            , Task.perform toSelf (Task.succeed (BackendCounterComponentUpdated components.counter.count))
            )
