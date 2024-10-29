module Clock exposing (main)

import Browser
import Composer.Document as C
import Html
import Task
import Time


main =
    C.app app_
        |> C.componentSimple clock
        |> C.compose (\clock_ -> { clock = clock_ })
        |> Browser.document


app_ =
    { init =
        \components toSelf () ->
            ( (), Cmd.none )
    , update =
        \components toSelf msg model ->
            ( (), Cmd.none )
    , view =
        \components toSelf model ->
            { title = "Clock demo"
            , body =
                [ Html.text
                    (String.fromInt components.clock.hours
                        ++ ":"
                        ++ String.fromInt components.clock.minutes
                        ++ ":"
                        ++ String.fromInt components.clock.seconds
                    )
                ]
            }
    , subscriptions =
        \components toSelf model ->
            Sub.none
    }


type ClockMsg
    = Tick Time.Posix


clock =
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
        \app toSelf (Tick now) model ->
            ( now, Cmd.none )
    , subscriptions =
        \app toSelf model ->
            Time.every 1000 (toSelf << Tick)
    }
