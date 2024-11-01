module Clock exposing (main)

import Browser
import Composer.Document
import Html
import Task
import Time


type alias Flags =
    ()


type alias ProgModel =
    ( AppModel, ( ClockModel, ( ClockModel, () ) ) )


type alias ProgMsg =
    ( Maybe AppMsg, ( Maybe ClockMsg, ( Maybe ClockMsg, () ) ) )


type alias AppModel =
    ()


type alias AppMsg =
    ()


type alias ClockModel =
    Time.Posix


type ClockMsg
    = Tick Time.Posix


type alias Components =
    ( Html.Html ProgMsg, Html.Html ProgMsg )


type alias ClockToApp =
    { hours : Int, minutes : Int, seconds : Int }


type alias AppToClock =
    ()


main : Program Flags ProgModel ProgMsg
main =
    Composer.Document.app clockApp
        |> Composer.Document.withElement clockElement
        |> Composer.Document.withElement clockElement
        |> Composer.Document.compose (\c1 c2 -> ( c1, c2 ))
        |> Browser.document


clockApp :
    { init : Components -> (AppMsg -> ProgMsg) -> Flags -> ( AppModel, Cmd ProgMsg )
    , update : Components -> (AppMsg -> ProgMsg) -> AppMsg -> AppModel -> ( AppModel, Cmd ProgMsg )
    , view : Components -> (AppMsg -> ProgMsg) -> AppModel -> Browser.Document ProgMsg
    , subscriptions : Components -> (AppMsg -> ProgMsg) -> AppModel -> Sub ProgMsg
    }
clockApp =
    { init =
        \( c1, c2 ) toSelf () ->
            ( (), Cmd.none )
    , update =
        \( c1, c2 ) toSelf msg model ->
            ( (), Cmd.none )
    , view =
        \( c1, c2 ) toSelf model ->
            { title = "Clock demo"
            , body =
                [ Html.div [] [ c1 ]
                , Html.div [] [ c2 ]
                ]
            }
    , subscriptions =
        \( c1, c2 ) toSelf model ->
            Sub.none
    }


clockElement :
    { view : ClockModel -> Html.Html ClockMsg
    , init : Flags -> ( ClockModel, Cmd ClockMsg )
    , update : ClockMsg -> ClockModel -> ( ClockModel, Cmd ClockMsg )
    , subscriptions : ClockModel -> Sub ClockMsg
    }
clockElement =
    { view =
        \model ->
            let
                hours =
                    Time.toHour Time.utc model

                minutes =
                    Time.toMinute Time.utc model

                seconds =
                    Time.toSecond Time.utc model
            in
            Html.text
                (String.fromInt hours
                    ++ ":"
                    ++ String.fromInt minutes
                    ++ ":"
                    ++ String.fromInt seconds
                )
    , init =
        \flags ->
            ( Time.millisToPosix 0
            , Task.perform Tick Time.now
            )
    , update =
        \(Tick now) model ->
            ( now, Cmd.none )
    , subscriptions =
        \model ->
            Time.every 1000 Tick
    }
