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
        |> Composer.Element.componentSimple (string "Name")
        |> Composer.Element.componentSimple (int "Age")
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
            { view = textInputView label toSelf model
            , parsed = model.parsed
            }
    , init =
        \toSelf model ->
            ( { value = "", parsed = Ok "" }
            , Cmd.none
            )
    , update =
        \app toSelf (StringChanged str) model ->
            ( { model | value = str, parsed = Ok str }, Cmd.none )
    , subscriptions =
        \app toSelf model ->
            Sub.none
    }


int label =
    { interface =
        \toSelf model ->
            { view = textInputView label toSelf model
            , parsed = model.parsed
            }
    , init =
        \toSelf model ->
            ( { value = "", parsed = Err "Must be an integer" }
            , Cmd.none
            )
    , update =
        \app toSelf (StringChanged str) model ->
            ( { model
                | value = str
                , parsed = String.toInt str |> Result.fromMaybe "Must be an integer"
              }
            , Cmd.none
            )
    , subscriptions =
        \app toSelf model ->
            Sub.none
    }


textInputView label toSelf { value, parsed } =
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
                    [ Html.Events.onInput (toSelf << StringChanged) ]
                    [ Html.text value ]
                , Html.text icon
                ]
            , Html.small [] [ Html.text message ]
            ]
        ]
