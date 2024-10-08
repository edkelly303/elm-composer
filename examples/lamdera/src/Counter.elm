module Counter exposing (component, init, update, view)

import Html
import Html.Events
import Types exposing (CounterModel, CounterMsg(..))


component =
    { init = \sendToApp sendToSelf -> init |> Tuple.mapSecond (Cmd.map sendToSelf)
    , update = \sendToApp sendToSelf msg model -> update msg model |> Tuple.mapSecond (Cmd.map sendToSelf)
    , view = \sendToApp sendToSelf model -> view model.count |> Html.map sendToSelf
    , subscriptions = \sendToApp sendToSelf model -> subscriptions model |> Sub.map sendToSelf
    }


init =
    ( { count = 0 }
    , Cmd.none
    )


update msg model =
    case msg of
        Increment ->
            ( { model | count = model.count + 1 }, Cmd.none )

        Decrement ->
            ( { model | count = model.count - 1 }, Cmd.none )

        Noop ->
            ( model, Cmd.none )


view count =
    Html.div []
        [ Html.button [ Html.Events.onClick Decrement ] [ Html.text "-" ]
        , Html.text (String.fromInt count)
        , Html.button [ Html.Events.onClick Increment ] [ Html.text "+" ]
        ]


subscriptions model =
    Sub.none
