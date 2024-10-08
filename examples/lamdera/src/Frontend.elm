module Frontend exposing (..)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Html
import Html.Attributes as Attr
import Lamdera
import Types exposing (..)
import Url
import Composer.Lamdera.Frontend

type alias Model =
    FrontendModel


app =
    Lamdera.frontend composition

composition = 
    Composer.Lamdera.Frontend.defineApp
        { init = \sendToSelf url key -> init url key |> Tuple.mapSecond (Cmd.map sendToSelf)
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = \sendToSelf msg model -> update msg model |> Tuple.mapSecond (Cmd.map sendToSelf)
        , updateFromBackend = \sendToSelf msg model -> updateFromBackend msg model |> Tuple.mapSecond (Cmd.map sendToSelf)
        , subscriptions = \sendToSelf model -> Sub.none
        , view = \sendToSelf model -> {title = "title", body = []}
        }
        |> Composer.Lamdera.Frontend.done


init : Url.Url -> Nav.Key -> ( Model, Cmd FrontendMsg )
init url key =
    ( { key = key
      , message = "Welcome to Lamdera! You're looking at the auto-generated base implementation. Check out src/Frontend.elm to start coding!"
      }
    , Cmd.none
    )


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Nav.pushUrl model.key (Url.toString url)
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        UrlChanged url ->
            ( model, Cmd.none )

        NoOpFrontendMsg ->
            ( model, Cmd.none )


updateFromBackend : ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend msg model =
    case msg of
        NoOpToFrontend ->
            ( model, Cmd.none )


view : Model -> Browser.Document FrontendMsg
view model =
    { title = ""
    , body =
        [ Html.div [ Attr.style "text-align" "center", Attr.style "padding-top" "40px" ]
            [ Html.img [ Attr.src "https://lamdera.app/lamdera-logo-black.png", Attr.width 150 ] []
            , Html.div
                [ Attr.style "font-family" "sans-serif"
                , Attr.style "padding-top" "40px"
                ]
                [ Html.text model.message ]
            ]
        ]
    }