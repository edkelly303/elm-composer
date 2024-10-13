module Timer exposing (..)

import Browser
import Composer.Element
import Html
import Html.Attributes
import Html.Events
import Process
import Task
import Time


main :
    Program
        ()
        ( AppModel, ( TimerModel, () ) )
        ( Maybe AppMsg, ( Maybe TimerMsg, () ) )
main =
    Browser.element program


program =
    Composer.Element.defineApp app
        |> Composer.Element.addComponent (timerComponent { timerExpired = TimerExpired, timerReset = TimerReset })
        |> Composer.Element.done


type alias AppModel =
    { timerExpired : Bool }


type AppMsg
    = TimerExpired
    | TimerReset


app =
    { init =
        \sendToTimer toSelf flags ->
            ( { timerExpired = False }, Cmd.none )
    , update =
        \timer toSelf msg model ->
            case msg of
                TimerExpired ->
                    ( { model | timerExpired = True }, Cmd.none )

                TimerReset ->
                    ( { model | timerExpired = False }, Cmd.none )
    , view =
        \timer toSelf model ->
            Html.div []
                [ Html.p []
                    [ Html.text
                        """
                            The timer element below comes from an 
                            encapsulated component, which manages its own 
                            state, completely separately from the app's 
                            model. It can send messages to the app's update 
                            function, and receive messages sent by the app's 
                            view function.
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
                            it doesn't (and can't) know anything about the 
                            actual state of the timer - whether it's ticking, 
                            how much time is left, etc. The only way it can find 
                            out whether the timer has expired is if it receives 
                            a message from the timer component. So, the timer's
                            update function is configured to send a message to
                            the app's update function when it reaches zero
                            """
                    ]
                , Html.p []
                    [ Html.text
                        """
                            Here we have a button in the app's view function 
                            that can send a message to the timer component
                            """
                    ]
                , Html.button
                    [ Html.Events.onClick (timer.toMsg Reset) ]
                    [ Html.text "Reset timer" ]
                ]
    , subscriptions =
        \sendToTimer toSelf model ->
            Sub.none
    }


type TimerMsg
    = Start
    | Tick
    | Reset


type alias TimerModel =
    Maybe Int


timerComponent { timerExpired, timerReset } =
    { init =
        \toApp toSelf flags ->
            ( Nothing, Cmd.none )
    , update =
        \toApp toSelf msg model ->
            case msg of
                Start ->
                    ( Just 10, Cmd.none )

                Tick ->
                    if model == Just 0 then
                        ( Just 0, Task.perform (\_ -> toApp timerExpired) (Process.sleep 0) )

                    else
                        ( Maybe.map (\n -> n - 1) model, Cmd.none )

                Reset ->
                    ( Nothing, Task.perform (\_ -> toApp timerReset) (Process.sleep 0) )
    , interface =
        \toApp toSelf model -> { toMsg = toSelf, view = 
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
                ]}
    , subscriptions =
        \toApp toSelf model ->
            case model of
                Nothing ->
                    Sub.none

                Just _ ->
                    Time.every 1000 (\_ -> toSelf Tick)
    }
