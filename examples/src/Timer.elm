module Timer exposing (..)

import Browser
import Composer.Element
import Html
import Html.Attributes
import Html.Events
import Process
import Task
import Time


type alias Components timer =
    { timer : timer }


main :
    Program
        ()
        ( AppModel, ( TimerModel, () ) )
        ( Maybe AppMsg, ( Maybe TimerMsg, () ) )
main =
    Composer.Element.app app_
        |> Composer.Element.componentWithRequirements
            timerComponent
            (\toApp appModel ->
                { timerExpired = toApp TimerExpired
                , timerReset = toApp TimerReset
                }
            )
        |> Composer.Element.compose Components
        |> Browser.element


type alias AppModel =
    { timerExpired : Bool }


type AppMsg
    = TimerExpired
    | TimerReset


app_ =
    { init =
        \components toSelf flags ->
            ( { timerExpired = False }, Cmd.none )
    , update =
        \{ timer } toSelf msg model ->
            case msg of
                TimerExpired ->
                    ( { model | timerExpired = True }, Cmd.none )

                TimerReset ->
                    ( { model | timerExpired = False }, Cmd.none )
    , view =
        \{ timer } toSelf model ->
            Html.div []
                [ Html.p []
                    [ Html.text
                        """
                        The timer element below comes from an 
                        encapsulated component, which manages its own 
                        state, completely separately from the main app's 
                        model.
                        """
                    ]
                , timer.view
                , Html.p []
                    [ Html.text
                        """
                        Here is a `Debug.toString` of the app's model:
                        """
                    ]
                , Html.p [ Html.Attributes.style "font-family" "monospace" ]
                    [ Html.text (Debug.toString model) ]
                , Html.p []
                    [ Html.text
                        """
                        The only thing the app's model does is keep track of
                        whether the timer has expired. But as you can see, 
                        it doesn't know anything about the actual state of the 
                        timer - whether it's ticking, how much time is left, 
                        etc.
                        """
                    ]
                , Html.p []
                    [ Html.text
                        """
                        The only way the main app can find out whether the timer 
                        has expired is if it receives a message from the timer 
                        component. So, the timer's update function is configured 
                        to send a `TimerExpired` message to the app's update 
                        function when it reaches zero. It will also send a 
                        `TimerReset` message if the reset button has been 
                        clicked.
                        """
                    ]
                , Html.p []
                    [ Html.text
                        """
                        As well as receiving messages from its components, the 
                        main app can also send messages to them. Here we have a 
                        button in the main app's view function that sends a 
                        `Reset` message to the timer component.
                        """
                    ]
                , Html.button
                    [ Html.Events.onClick timer.reset ]
                    [ Html.text "Reset timer" ]
                ]
    , subscriptions =
        \{ timer } toSelf model ->
            Sub.none
    }


type TimerMsg
    = Start
    | Tick
    | Reset


type alias TimerModel =
    Maybe Int


timerComponent =
    { interface =
        \toSelf model ->
            { reset = toSelf Reset
            , view =
                Html.article
                    [ Html.Attributes.style "border" "solid 1px pink"
                    , Html.Attributes.style "border-radius" "10px"
                    , Html.Attributes.style "background-color" "aliceblue"
                    , Html.Attributes.style "padding" "10px"
                    , Html.Attributes.style "width" "200px"
                    , Html.Attributes.style "text-align" "center"
                    , Html.Attributes.style "font-family" "sans-serif"
                    ]
                    [ Html.p [] [ Html.text "Countdown timer" ]
                    , Html.h1 [] [ Html.text (model |> Maybe.withDefault 10 |> String.fromInt) ]
                    , Html.button
                        [ Html.Events.onClick (toSelf Start) ]
                        [ Html.text "Start" ]
                    , Html.button
                        [ Html.Events.onClick (toSelf Reset) ]
                        [ Html.text "Reset" ]
                    ]
            }
    , init =
        \toSelf flags ->
            ( Nothing, Cmd.none )
    , update =
        \app toSelf msg model ->
            case msg of
                Start ->
                    ( Just 10, Cmd.none )

                Tick ->
                    if model == Just 0 then
                        ( Just 0, send app.timerExpired )

                    else
                        ( Maybe.map (\n -> n - 1) model, Cmd.none )

                Reset ->
                    ( Nothing, send app.timerReset )
    , subscriptions =
        \app toSelf model ->
            case model of
                Nothing ->
                    Sub.none

                Just _ ->
                    Time.every 1000 (\_ -> toSelf Tick)
    }


send msg =
    Task.perform identity (Task.succeed msg)
