module Clock exposing (main)

import Browser
import Composer.Document
import Html
import Task
import Time


type alias Flags =
    ()


type alias ProgModel =
    ( AppModel, ( ClockModel, () ) )


type alias ProgMsg =
    ( Maybe AppMsg, ( Maybe ClockMsg, () ) )


type alias AppModel =
    ()


type alias AppMsg =
    ()


type alias ClockModel =
    Time.Posix


type ClockMsg
    = Tick Time.Posix


type alias ClockToApp =
    { hours : Int, minutes : Int, seconds : Int }


type alias AppToClock =
    ()


main : Program Flags ProgModel ProgMsg
main =
    Composer.Document.app clockApp
        |> Composer.Document.componentSimple clockComponent
        |> Composer.Document.compose identity
        |> Browser.document


clockApp :
    { init : ClockToApp -> (AppMsg -> ProgMsg) -> Flags -> ( AppModel, Cmd ProgMsg )
    , update : ClockToApp -> (AppMsg -> ProgMsg) -> AppMsg -> AppModel -> ( AppModel, Cmd ProgMsg )
    , view : ClockToApp -> (AppMsg -> ProgMsg) -> AppModel -> Browser.Document ProgMsg
    , subscriptions : ClockToApp -> (AppMsg -> ProgMsg) -> AppModel -> Sub ProgMsg
    }
clockApp =
    { init =
        \clock toSelf () ->
            ( (), Cmd.none )
    , update =
        \clock toSelf msg model ->
            ( (), Cmd.none )
    , view =
        \clock toSelf model ->
            { title = "Clock demo"
            , body =
                [ Html.text
                    (String.fromInt clock.hours
                        ++ ":"
                        ++ String.fromInt clock.minutes
                        ++ ":"
                        ++ String.fromInt clock.seconds
                    )
                ]
            }
    , subscriptions =
        \clock toSelf model ->
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
