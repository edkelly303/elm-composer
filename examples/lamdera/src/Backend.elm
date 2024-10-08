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
        { init = \sendToCounter sendToSelf -> init |> Tuple.mapSecond (Cmd.map sendToSelf)
        , update = \sendToCounter sendToSelf msg model -> update msg model |> Tuple.mapSecond (Cmd.map sendToSelf)
        , updateFromFrontend = updateFromFrontend
        , subscriptions = \sendToCounter sendToSelf model -> Sub.none
        }
        |> Composer.addComponent component
        |> Composer.done


component =
    let
        replaceCmd sendToApp ( model, cmd ) =
            ( model
            , immediately sendToApp (CounterComponentUpdated model.count)
            )
    in
    { init = Counter.component.init
    , view = Counter.component.view
    , subscriptions = Counter.component.subscriptions
    , update =
        \sendToApp sendToSelf msg model ->
            Counter.update msg model
                |> replaceCmd sendToApp
    }


init : ( BAppModel, Cmd BAppMsg )
init =
    ( { message = "Hello!" }
    , Cmd.none
    )


update : BAppMsg -> BAppModel -> ( BAppModel, Cmd BAppMsg )
update msg model =
    case msg of
        CounterComponentUpdated count ->
            ( model, Lamdera.broadcast (BackendCounterUpdated count) )


updateFromFrontend sendToCounter sendToSelf sessionId clientId msg model =
    case msg of
        BackendCounterUpdateRequested counterMsg ->
            ( model, immediately sendToCounter counterMsg )

        BackendCounterStatusRequested ->
            ( model, immediately sendToCounter Noop )


immediately target msg =
    Task.perform (\() -> target msg) (Process.sleep 0)
