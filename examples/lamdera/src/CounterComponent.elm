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


init toApp toSelf =
    ( Counter.init, Cmd.none )


update onUpdate toApp toSelf msg model =
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
                |> toApp
                |> Task.succeed
                |> Task.perform identity

        Nothing ->
            Cmd.none
    )


interface toApp toSelf model =
    { html =
        Counter.view model
            |> Html.map
                (\counterMsg ->
                    toSelf
                        (case counterMsg of
                            Types.Increment ->
                                CounterComponentIncremented

                            Types.Decrement ->
                                CounterComponentDecremented
                        )
                )
    , debug = Debug.toString model
    }


subscriptions toApp toSelf model =
    Sub.none
