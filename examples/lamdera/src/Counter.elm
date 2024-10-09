module Counter exposing (init, update, view)

import Html
import Html.Attributes as Attr
import Html.Events
import Types exposing (CounterModel, CounterMsg(..))


init =
    0


update msg model =
    case msg of
        Increment ->
            model + 1

        Decrement ->
            model - 1


view count =
    Html.article []
        [ Html.button [ Html.Events.onClick Decrement ] [ Html.text "➖" ]
        , Html.span
            [ Attr.style "padding" "10px"
            , Attr.style "font-family" "sans-serif"
            , Attr.style "font-size" "20px"
            ]
            [ Html.text (String.fromInt count) ]
        , Html.button [ Html.Events.onClick Increment ] [ Html.text "➕" ]
        ]
