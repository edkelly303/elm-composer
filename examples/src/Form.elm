module Form exposing (main)

import Browser
import Composer.Element
import Html
import Html.Attributes
import Html.Events
import Process
import Result.Extra
import Task
import Time


type alias User =
    { name : String, age : Int }


main =
    Composer.Element.integrate formApp
        |> Composer.Element.withSimpleComponent (string "Name")
        |> Composer.Element.withSimpleComponent (int "Age")
        |> Composer.Element.groupedAs
            (\name age ->
                { name = name
                , age = age
                , output =
                    pure User
                        |> andMap name.parsed
                        |> andMap age.parsed
                }
            )
        |> Browser.element


pure =
    Ok


andMap resArg resCtor =
    case ( resArg, resCtor ) of
        ( Ok arg, Ok ctor ) ->
            Ok (ctor arg)

        ( Ok _, Err errs ) ->
            Err errs

        ( Err errs, Ok _ ) ->
            Err errs

        ( Err errs1, Err errs2 ) ->
            Err (errs2 ++ errs1)


formApp =
    { init =
        \{} _ () ->
            ( (), Cmd.none )
    , update =
        \{} _ () () ->
            ( (), Cmd.none )
    , view =
        \{ name, age, output } toSelf () ->
            Html.form []
                [ Html.h1 [] [ Html.text "Create a user" ]
                , name.view
                , age.view
                , Html.button
                    [ Html.Attributes.type_ "button"
                    ]
                    [ Html.text "Submit!" ]
                ]
    , subscriptions =
        \{} _ () ->
            Sub.none
    }


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
    | DebounceStarted Time.Posix
    | DebounceChecked Time.Posix


type TextInputStatus
    = Intact
    | Touched
    | Debouncing Time.Posix



textInput parse label =
    { interface =
        \toSelf model ->
            { view = textInputView label model |> Html.map toSelf
            , parsed = model.parsed
            }
    , init =
        \model ->
            ( { value = ""
              , parsed = parse ""
              , status = Intact
              }
            , Cmd.none
            )
    , update =
        \msg model ->
            case msg of
                StringChanged str ->
                    ( { model
                        | value = str
                        , parsed = parse str
                        , status = Touched
                      }
                    , Task.perform DebounceStarted Time.now
                    )

                DebounceStarted now ->
                    ( { model | status = Debouncing now }
                    , Task.perform (\() -> DebounceChecked now) (Process.sleep 500)
                    )

                DebounceChecked now ->
                    ( case model.status of
                        Debouncing current ->
                            if now == current then
                                { model | status = Touched }

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


textInputView label { value, parsed, status } =
    let
        ( icon, message ) =
            case status of
                Touched ->
                    case parsed of
                        Ok p ->
                            ( " ✅", "" )

                        Err e ->
                            ( " 🚫", String.join "\n" e )

                _ ->
                    ( "", "" )
    in
    Html.div []
        [ Html.label []
            [ Html.strong [] [ Html.text label ]
            , Html.div []
                [ Html.input
                    [ Html.Events.onInput StringChanged ]
                    [ Html.text value ]
                , Html.text icon
                ]
            , Html.small [] [ Html.text message ]
            ]
        ]
