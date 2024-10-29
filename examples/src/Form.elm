module Form exposing (main)

import Browser
import Composer.Document
import Html
import Html.Attributes
import Html.Events
import Task
import Time


main =
    Composer.Document.app formApp
        |> Composer.Document.componentSimple (string)
        |> Composer.Document.componentSimple (string)
        |> Composer.Document.compose (\a b -> ())
        |> Browser.document


formApp =
    { init =
        \() toSelf () ->
            ( (), Cmd.none )
    , update =
        \() toSelf () () ->
            ( (), Cmd.none )
    , view =
        \() toSelf () ->
            { title = "Form demo"
            , body =
                []
            }
    , subscriptions =
        \() toSelf () ->
            Sub.none
    }


type StringMsg
    = StringChanged String


string  =
    { interface =
        \toSelf () ->
            ()
    , init =
        \toSelf () ->
            ( ()
            , Cmd.none
            )
    , update =
        \() toSelf () () ->
            ( (), Cmd.none )
    , subscriptions =
        \() toSelf () ->
            Sub.none
    }
