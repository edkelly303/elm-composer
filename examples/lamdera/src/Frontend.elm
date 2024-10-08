module Frontend exposing (..)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Composer.Lamdera.Frontend as Composer
import Html
import Html.Attributes as Attr
import Lamdera
import Types exposing (..)
import Url


app =
    Lamdera.frontend composition


composition =
    Composer.defineApp
        { init = \sendToSelf url key -> init url key |> Tuple.mapSecond (Cmd.map sendToSelf)
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = \sendToSelf msg model -> update msg model |> Tuple.mapSecond (Cmd.map sendToSelf)
        , updateFromBackend = \sendToSelf msg model -> updateFromBackend msg model |> Tuple.mapSecond (Cmd.map sendToSelf)
        , subscriptions = \sendToSelf model -> Sub.none
        , view = view
        }
        |> Composer.done


init : Url.Url -> Nav.Key -> ( FAppModel, Cmd FAppMsg )
init url key =
    ( { key = key
      , message = "Welcome to Lamdera! You're looking at the auto-generated base implementation. Check out src/Frontend.elm to start coding!"
      }
    , Cmd.none
    )


update : FAppMsg -> FAppModel -> ( FAppModel, Cmd FAppMsg )
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


updateFromBackend : ToFrontend -> FAppModel -> ( FAppModel, Cmd FAppMsg )
updateFromBackend msg model =
    case msg of
        NoOpToFrontend ->
            ( model, Cmd.none )


view : (FAppMsg -> FrontendMsg) -> FAppModel -> Browser.Document FrontendMsg
view sendToSelf model =
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
