module Types exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Url exposing (Url)


type alias FrontendModel =
    ( FAppModel, ( CounterModel, () ) )


type alias FAppModel =
    { key : Key
    , count : Int
    , backendCounter : Int
    }


type alias FrontendMsg =
    ( Maybe FAppMsg, ( Maybe CounterMsg, () ) )


type FAppMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | FrontendCounterClicked CounterMsg
    | BackendCounterClicked CounterMsg


type ToBackend
    = BackendCounterUpdateRequested CounterMsg
    | BackendCounterStatusRequested


type alias BackendModel =
    ( BAppModel, ( CounterModel, () ) )


type alias BAppModel =
    { message : String
    }


type alias BackendMsg =
    ( Maybe BAppMsg, ( Maybe CounterMsg, () ) )


type BAppMsg
    = CounterComponentUpdated Int


type ToFrontend
    = BackendCounterUpdated Int


type alias CounterModel =
    { count : Int }


type CounterMsg
    = Increment
    | Decrement
    | Noop
