module Form exposing (main)

import Browser
import Composer.Element
import Html
import Html.Attributes
import Html.Events
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
                    [ Html.Attributes.disabled (Result.Extra.isErr output) ]
                    [ Html.text "Submit!" ]
                ]
    , subscriptions =
        \{} _ () ->
            Sub.none
    }


type StringMsg
    = StringChanged String


type Status
    = Intact
    | Touched


string label =
    { interface =
        \toSelf model ->
            { view = textInputView label model |> Html.map toSelf
            , parsed = model.parsed
            }
    , init =
        \model ->
            ( { value = "", parsed = Ok "", status = Intact }
            , Cmd.none
            )
    , update =
        \(StringChanged str) model ->
            ( { model | value = str, parsed = Ok str, status = Touched }, Cmd.none )
    , subscriptions =
        \model ->
            Sub.none
    }


int label =
    { interface =
        \toSelf model ->
            { view = textInputView label model |> Html.map toSelf
            , parsed = model.parsed
            }
    , init =
        \model ->
            ( { value = "", parsed = Err [ "must be an integer" ], status = Intact }
            , Cmd.none
            )
    , update =
        \(StringChanged str) model ->
            ( { model
                | value = str
                , parsed =
                    case String.toInt str of
                        Just i ->
                            Ok i

                        Nothing ->
                            Err [ "must be an integer" ]
                , status = Touched
              }
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
                Intact ->
                    ( "", "" )

                Touched ->
                    case parsed of
                        Ok p ->
                            ( " ✅", "" )

                        Err e ->
                            ( " 🚫", String.join "\n" e )
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
