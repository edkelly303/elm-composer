module Form exposing (main)

import Browser
import Composer.Element
import Html
import Html.Attributes
import Html.Events
import Task
import Time


main =
    Composer.Element.app formApp
        |> Composer.Element.component string (\toApp appModel -> 1)
        |> Composer.Element.component string (\toApp appModel -> 2)
        |> Composer.Element.compose (\a b -> ( a, b ))
        |> Browser.element


formApp =
    { init =
        \( a, b ) toSelf () ->
            ( (), Cmd.none )
    , update =
        \( a, b ) toSelf () () ->
            ( (), Cmd.none )
    , view =
        \( a, b ) toSelf () ->
            Html.text "wooo"
    , subscriptions =
        \( a, b ) toSelf () ->
            Sub.none
    }


type StringMsg
    = StringChanged String


string =
    { interface =
        \toSelf () ->
            1
    , init =
        \toSelf () ->
            ( ()
            , Cmd.none
            )
    , update =
        \int toSelf () () ->
            ( (), Cmd.none )
    , subscriptions =
        \int toSelf () ->
            let
                _ =
                    int * 2
            in
            Sub.none
    }
