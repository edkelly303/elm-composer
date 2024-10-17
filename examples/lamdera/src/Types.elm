module Types exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Url exposing (Url)


type alias FrontendModel =
    ( FAppModel, ( CounterModel, () ) )


type alias FAppModel =
    { key : Key
    , frontendCounter : Int
    , backendCounterComponent : Int
    }


type alias FrontendMsg =
    ( Maybe FAppMsg, ( Maybe CounterMsg, () ) )


type FAppMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | FrontendCounterClicked CounterMsg
    | BackendCounterClicked CounterMsg
    | Noop


type ToBackend
    = BackendCounterComponentUpdateRequested CounterMsg
    | BackendCounterComponentStatusRequested


type alias BackendModel =
    ( BAppModel, ( CounterModel, () ) )


type alias BAppModel =
    ()


type alias BackendMsg =
    ( Maybe BAppMsg, ( Maybe CounterMsg, () ) )


type BAppMsg
    = BackendCounterComponentUpdated Int


type ToFrontend
    = BackendCounterComponentStatusResponded Int


type alias CounterModel =
    Int


type CounterMsg
    = Increment
    | Decrement
