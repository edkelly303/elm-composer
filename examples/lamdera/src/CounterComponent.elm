module CounterComponent exposing (element)

import Counter
import Html
import Process
import Task
import Types exposing (CounterComponentMsg(..))


element { onUpdate } =
    { init = init
    , update = update onUpdate
    , interface = interface
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

                CounterComponentIncremented ->
                    Counter.update Types.Increment model

                CounterComponentDecremented ->
                    Counter.update Types.Decrement model
    in
    ( newModel
    , case onUpdate of
        Just onUpdateMsg ->
            newModel
                |> onUpdateMsg
                |> sendToApp
                |> Task.succeed
                |> Task.perform identity

        Nothing ->
            Cmd.none
    )


interface sendToApp sendToSelf model =
    { html =
        Counter.view model
            |> Html.map
                (\counterMsg ->
                    sendToSelf
                        (case counterMsg of
                            Types.Increment ->
                                CounterComponentIncremented

                            Types.Decrement ->
                                CounterComponentDecremented
                        )
                )
    , debug = Debug.toString model
    }


subscriptions sendToApp sendToSelf model =
    Sub.none
