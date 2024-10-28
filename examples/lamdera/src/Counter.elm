module Counter exposing (component, view)

import Html
import Html.Attributes
import Html.Events
import Process
import Task
import Types exposing (CounterMsg(..))


component =
    { init = init
    , update = update
    , interface = interface
    , subscriptions = subscriptions
    }


init toSelf =
    ( 0, Cmd.none )


update app toSelf msg model =
    let
        newModel =
            case msg of
                Increment ->
                    model + 1

                Decrement ->
                    model - 1
    in
    ( newModel
    , Task.perform identity (Task.succeed (app.countChanged newModel))
    )


interface toSelf model =
    { count = model
    , increment = toSelf Increment
    , decrement = toSelf Decrement
    , debug = Debug.toString model
    }


subscriptions app toSelf model =
    Sub.none


view inc dec count =
    Html.article []
        [ Html.button [ Html.Events.onClick dec ] [ Html.text "➖" ]
        , Html.span
            [ Html.Attributes.style "padding" "10px"
            , Html.Attributes.style "font-family" "sans-serif"
            , Html.Attributes.style "font-size" "20px"
            ]
            [ Html.text (String.fromInt count) ]
        , Html.button [ Html.Events.onClick inc ] [ Html.text "➕" ]
        ]
