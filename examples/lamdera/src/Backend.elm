module Backend exposing (..)

import Composer.Lamdera.Backend as Composer
import Html
import Lamdera exposing (ClientId, SessionId)
import Types exposing (..)


app =
    Lamdera.backend composition


composition =
    Composer.defineApp
        { init = \sendToSelf -> init |> Tuple.mapSecond (Cmd.map sendToSelf)
        , update = \sendToSelf msg model -> update msg model |> Tuple.mapSecond (Cmd.map sendToSelf)
        , updateFromFrontend = \sendToSelf sesId clId msg model -> updateFromFrontend sesId clId msg model |> Tuple.mapSecond (Cmd.map sendToSelf)
        , subscriptions = \sendToSelf model -> Sub.none
        }
        |> Composer.done


init : ( BAppModel, Cmd BAppMsg )
init =
    ( { message = "Hello!" }
    , Cmd.none
    )


update : BAppMsg -> BAppModel -> ( BAppModel, Cmd BAppMsg )
update msg model =
    case msg of
        NoOpBackendMsg ->
            ( model, Cmd.none )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> BAppModel -> ( BAppModel, Cmd BAppMsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        NoOpToBackend ->
            ( model, Cmd.none )
