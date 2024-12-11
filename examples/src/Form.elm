module Form exposing (main)

import Browser
import Composer.Element
import Html
import Html.Attributes
import Html.Events
import NestedTuple as NT
import Process
import Result.Extra
import Task
import Time


type alias User =
    { name : String, age : Int, cool : Bool }


main =
    Composer.Element.integrate formApp
        |> Composer.Element.withSimpleComponent (string "Name")
        |> Composer.Element.withSimpleComponent (int "Age")
        |> Composer.Element.withSimpleComponent (bool "Is cool?")
        |> Composer.Element.groupedAs
            (\name age cool ->
                { name = name
                , age = age
                , cool = cool
                }
            )
        |> Browser.element


pure =
    Ok


andMap resArg resCtor =
    case ( resArg, resCtor ) of
        ( Touched (Ok arg), Ok ctor ) ->
            Ok (ctor arg)

        ( Touched (Ok _), Err errs ) ->
            Err errs

        ( Touched (Err errs), Ok _ ) ->
            Err errs

        ( Touched (Err errs1), Err errs2 ) ->
            Err (errs2 ++ errs1)

        ( _, _ ) ->
            Err []


type AppMsg
    = SubmitClicked
    | BackClicked


type AppModel
    = FormActive
    | Success User


formApp =
    { init =
        \{} _ () ->
            ( FormActive, Cmd.none )
    , update =
        \{ name, age, cool } _ msg model ->
            case msg of
                SubmitClicked ->
                    case
                        pure User
                            |> andMap name.parsed
                            |> andMap age.parsed
                            |> andMap cool.parsed
                    of
                        Ok user ->
                            ( Success user
                            , Cmd.batch
                                [ send name.reset
                                , send age.reset
                                , send cool.reset
                                ]
                            )

                        Err _ ->
                            ( FormActive
                            , Cmd.batch
                                [ send name.touch
                                , send age.touch
                                ]
                            )

                BackClicked ->
                    ( FormActive
                    , Cmd.none
                    )
    , view =
        \{ name, age, cool } toSelf model ->
            case model of
                FormActive ->
                    Html.form []
                        [ Html.h1 [] [ Html.text "Create a user" ]
                        , name.view
                        , age.view
                        , cool.view
                        , Html.button
                            [ Html.Attributes.type_ "button"
                            , Html.Events.onClick (toSelf SubmitClicked)
                            ]
                            [ Html.text "Submit!" ]
                        ]

                Success user ->
                    Html.div []
                        [ Html.text ("Hello " ++ user.name)
                        , Html.button
                            [ Html.Attributes.type_ "button"
                            , Html.Events.onClick (toSelf BackClicked)
                            ]
                            [ Html.text "Go back!" ]
                        ]
    , subscriptions =
        \{} _ model ->
            Sub.none
    }


send msg =
    Task.perform identity (Task.succeed msg)


string label =
    textInput
        (\str ->
            if String.isEmpty str then
                Err [ "Name must not be blank" ]

            else
                Ok str
        )
        label


int label =
    textInput
        (\str ->
            case String.toInt str of
                Just i ->
                    Ok i

                Nothing ->
                    Err [ "Age must be an integer" ]
        )
        label


type TextInputMsg
    = StringChanged String
    | Touch
    | Reset
    | DebounceStarted Time.Posix
    | DebounceChecked Time.Posix


type TextInputStatus parsed
    = Intact
    | Debouncing Time.Posix
    | Touched (Result (List String) parsed)

select label = 
    { interface =
        \toSelf model ->
            { view =
                Html.div []
                    [ Html.label []
                        [ Html.strong [] [ Html.text label ]
                        , Html.input
                            [ Html.Attributes.type_ "radio"
                            , Html.Attributes.name "radio"
                            , Html.Attributes.checked model
                            , Html.Events.onCheck (\_ -> toSelf (not model))
                            ]
                            []
                        ]
                    ]
            , parsed = Touched (Ok model)
            , reset = toSelf False
            }
    , init =
        \flags ->
            ( Nothing, Cmd.none )
    , update =
        \app msg model ->
            ( msg, Cmd.none )
    , subscriptions =
        \app model ->
            Sub.none
    }


bool label =
    { interface =
        \toSelf model ->
            { view =
                Html.div []
                    [ Html.label []
                        [ Html.strong [] [ Html.text label ]
                        , Html.input
                            [ Html.Attributes.type_ "checkbox"
                            , Html.Attributes.checked model
                            , Html.Events.onCheck (\_ -> toSelf (not model))
                            ]
                            []
                        ]
                    ]
            , parsed = Touched (Ok model)
            , reset = toSelf False
            }
    , init =
        \flags ->
            ( False, Cmd.none )
    , update =
        \msg model ->
            ( msg, Cmd.none )
    , subscriptions =
        \model ->
            Sub.none
    }


textInput parse label =
    let
        init =
            ( { value = ""
              , status = Intact
              }
            , Cmd.none
            )
    in
    { interface =
        \toSelf model ->
            { view = textInputView label model |> Html.map toSelf
            , parsed = model.status
            , touch = toSelf Touch
            , reset = toSelf Reset
            }
    , init =
        \flags ->
            init
    , update =
        \msg model ->
            case msg of
                StringChanged str ->
                    ( { model | value = str }
                    , Task.perform DebounceStarted Time.now
                    )

                Reset ->
                    init

                Touch ->
                    ( { model
                        | status =
                            case model.status of
                                Touched _ ->
                                    model.status

                                _ ->
                                    Touched (parse model.value)
                      }
                    , Cmd.none
                    )

                DebounceStarted now ->
                    ( { model | status = Debouncing now }
                    , Task.perform (\() -> DebounceChecked now) (Process.sleep 500)
                    )

                DebounceChecked now ->
                    ( case model.status of
                        Debouncing current ->
                            if now == current then
                                { model | status = Touched (parse model.value) }

                            else
                                model

                        _ ->
                            model
                    , Cmd.none
                    )
    , subscriptions =
        \model ->
            Sub.none
    }


textInputView label { value, status } =
    let
        ( icon, message ) =
            case status of
                Intact ->
                    ( "", "" )

                Touched parsed ->
                    case parsed of
                        Ok p ->
                            ( " ✅", "" )

                        Err e ->
                            ( " 🚫", String.join "\n" e )

                Debouncing _ ->
                    ( " ⌨️", "" )
    in
    Html.div []
        [ Html.label []
            [ Html.strong [] [ Html.text label ]
            , Html.div []
                [ Html.input
                    [ Html.Events.onInput StringChanged
                    , Html.Attributes.value value
                    ]
                    []
                , Html.text icon
                ]
            , Html.small [] [ Html.text message ]
            ]
        ]
