module Frontend exposing (..)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav
import Composer.Lamdera.Frontend as Composer
import Counter
import Html
import Html.Attributes as Attr
import Lamdera
import Types exposing (..)
import Url


app =
    Lamdera.frontend composition


composition =
    Composer.defineApp
        { init = \sendToCounter sendToSelf url key -> init url key |> Tuple.mapSecond (Cmd.map sendToSelf)
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = \sendToCounter sendToSelf msg model -> update msg model |> Tuple.mapSecond (Cmd.map sendToSelf)
        , updateFromBackend = \sendToCounter sendToSelf msg model -> updateFromBackend msg model |> Tuple.mapSecond (Cmd.map sendToSelf)
        , subscriptions = \sendToCounter sendToSelf model -> Sub.none
        , view = view
        }
        |> Composer.addComponent Counter.component
        |> Composer.done


init : Url.Url -> Nav.Key -> ( FAppModel, Cmd FAppMsg )
init url key =
    ( { key = key
      , count = 0
      , backendCounter = 0
      }
    , Lamdera.sendToBackend BackendCounterStatusRequested
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

        FrontendCounterClicked counterMsg ->
            Counter.update counterMsg model

        BackendCounterClicked counterMsg ->
            ( model, Lamdera.sendToBackend (BackendCounterUpdateRequested counterMsg) )


updateFromBackend : ToFrontend -> FAppModel -> ( FAppModel, Cmd FAppMsg )
updateFromBackend msg model =
    case msg of
        BackendCounterUpdated count ->
            ( { model | backendCounter = count }, Cmd.none )


view : Html.Html FrontendMsg -> (CounterMsg -> FrontendMsg) -> (FAppMsg -> FrontendMsg) -> FAppModel -> Browser.Document FrontendMsg
view viewCounter sendToCounter sendToSelf model =
    { title = "`elm-composer` in Lamdera"
    , body =
        [ Html.h1 [] [Html.text "Counter Components Demo"]
        , Html.p [] [Html.text "This is a totally ordinary counter. The main frontend app is responsible for managing its state, and rendering its view."]
        , Counter.view model.count
            |> Html.map (\counterMsg -> sendToSelf (FrontendCounterClicked counterMsg))
        , Html.p [] [Html.text "This counter is a component running in the frontend, completely independent of the main app. It manages its own state and renders its own view, which is passed into the main app's view for rendering."]
        , viewCounter
        , Html.p [] [Html.text "And this counter is a component running in the backend. It sends messages to the main backend app whenever its count changes, and the backend app broadcasts those messages to the frontend app. The frontend app then renders the counter and sends any `onClick` messages to the backend app, which relays them to the backend counter component."]
        , Counter.view model.backendCounter
            |> Html.map (\counterMsg -> sendToSelf (BackendCounterClicked counterMsg))
        ]
    }
