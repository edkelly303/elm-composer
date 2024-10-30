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
    ( ClockToApp, ClockToApp )


type alias ClockToApp =
    { hours : Int, minutes : Int, seconds : Int }


type alias AppToClock =
    ()


main : Program Flags ProgModel ProgMsg
main =
    Composer.Document.app clockApp
        |> Composer.Document.componentSimple clockComponent
        |> Composer.Document.componentSimple clockComponent
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
                [ Html.div []
                    [ Html.text
                        (String.fromInt c1.hours
                            ++ ":"
                            ++ String.fromInt c1.minutes
                            ++ ":"
                            ++ String.fromInt c1.seconds
                        )
                    ]
                , Html.div []
                    [ Html.text
                        (String.fromInt c2.hours
                            ++ ":"
                            ++ String.fromInt c2.minutes
                            ++ ":"
                            ++ String.fromInt c2.seconds
                        )
                    ]
                ]
            }
    , subscriptions =
        \( c1, c2 ) toSelf model ->
            Sub.none
    }


clockComponent :
    { interface : (ClockMsg -> ProgMsg) -> ClockModel -> ClockToApp
    , init : (ClockMsg -> ProgMsg) -> Flags -> ( ClockModel, Cmd ProgMsg )
    , update : AppToClock -> (ClockMsg -> ProgMsg) -> ClockMsg -> ClockModel -> ( ClockModel, Cmd ProgMsg )
    , subscriptions : AppToClock -> (ClockMsg -> ProgMsg) -> ClockModel -> Sub ProgMsg
    }
clockComponent =
    { interface =
        \toSelf model ->
            { hours = Time.toHour Time.utc model
            , minutes = Time.toMinute Time.utc model
            , seconds = Time.toSecond Time.utc model
            }
    , init =
        \toSelf model ->
            ( Time.millisToPosix 0
            , Task.perform (toSelf << Tick) Time.now
            )
    , update =
        \() toSelf (Tick now) model ->
            ( now, Cmd.none )
    , subscriptions =
        \() toSelf model ->
            Time.every 1000 (toSelf << Tick)
    }
