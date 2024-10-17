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
    Composer.defineApp
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = \counter toSelf model -> Sub.none
        }
        |> Composer.addComponent (Counter.component { countChanged = BackendCounterComponentUpdated })
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
            ( model
            , case counterMsg of
                Increment ->
                    Task.perform identity (Task.succeed counter.increment)

                Decrement ->
                    Task.perform identity (Task.succeed counter.decrement)
            )

        BackendCounterComponentStatusRequested ->
            ( model
            , Task.perform toSelf (Task.succeed (BackendCounterComponentUpdated counter.count))
            )
