module Types exposing (..)

import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Url exposing (Url)


type alias FrontendModel =
    ( FAppModel, () )


type alias FAppModel =
    { key : Key
    , message : String
    }


type alias FrontendMsg =
    ( Maybe FAppMsg, () )


type FAppMsg
    = UrlClicked UrlRequest
    | UrlChanged Url
    | NoOpFrontendMsg


type ToBackend
    = NoOpToBackend


type alias BackendModel =
    ( BAppModel, () )


type alias BAppModel =
    { message : String
    }


type alias BackendMsg =
    ( Maybe BAppMsg, () )


type BAppMsg
    = NoOpBackendMsg


type ToFrontend
    = NoOpToFrontend
