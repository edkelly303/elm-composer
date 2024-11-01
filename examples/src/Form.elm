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
    Composer.Element.app formApp
        |> Composer.Element.withSimpleComponent (string "Name")
        |> Composer.Element.withSimpleComponent (int "Age")
        |> Composer.Element.compose
            (\name age ->
                { name = name
                , age = age
                , output =
                    Ok User
                        |> Result.Extra.andMap name.parsed
                        |> Result.Extra.andMap age.parsed
                }
            )
        |> Browser.element


formApp =
    { init =
        \{ name, age } toSelf () ->
            ( (), Cmd.none )
    , update =
        \{ name, age } toSelf () () ->
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
        \{ name, age } toSelf () ->
            Sub.none
    }


type StringMsg
    = StringChanged String


string label =
    { interface =
        \toSelf model ->
            { view = textInputView label model |> Html.map toSelf
            , parsed = model.parsed
            }
    , init =
        \model ->
            ( { value = "", parsed = Ok "" }
            , Cmd.none
            )
    , update =
        \(StringChanged str) model ->
            ( { model | value = str, parsed = Ok str }, Cmd.none )
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
            ( { value = "", parsed = Err "Must be an integer" }
            , Cmd.none
            )
    , update =
        \(StringChanged str) model ->
            ( { model
                | value = str
                , parsed = String.toInt str |> Result.fromMaybe "Must be an integer"
              }
            , Cmd.none
            )
    , subscriptions =
        \model ->
            Sub.none
    }


textInputView label { value, parsed } =
    let
        ( icon, message ) =
            case parsed of
                Ok p ->
                    ( "✅", "" )

                Err e ->
                    ( "🚫 ", e )
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
