module CounterComponent exposing (element)

import Counter
import Html
import Process
import Task
import Types exposing (CounterComponentMsg(..))


element { onUpdate } =
    { init = init
    , update = update onUpdate
    , view = view
    , subscriptions = subscriptions
    }


init sendToApp sendToSelf =
    ( Counter.init, Cmd.none )


update onUpdate sendToApp sendToSelf msg model =
    let
        newModel =
            case msg of
                CounterComponentStatusRequested ->
                    model

                CounterComponentUpdateRequested counterMsg ->
                    Counter.update counterMsg model
    in
    ( newModel
    , case onUpdate of
        Just onUpdateMsg ->
            immediately sendToApp (onUpdateMsg newModel)

        Nothing ->
            Cmd.none
    )


view sendToApp sendToSelf model =
    { html =
        Counter.view model
            |> Html.map (CounterComponentUpdateRequested >> sendToSelf)
    , debug = Debug.toString model
    }


subscriptions sendToApp sendToSelf model =
    Sub.none


immediately target msg =
    Task.perform (\() -> target msg) (Process.sleep 0)
