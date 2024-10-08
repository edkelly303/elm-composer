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
        [ Html.h1 [] [ Html.text "Counter Components Demo" ]
        , Html.p [] [ Html.text "This is a totally ordinary counter. The main frontend app is responsible for managing its state in `model.count`, and rendering its view." ]
        , Counter.view model.count
            |> Html.map (\counterMsg -> sendToSelf (FrontendCounterClicked counterMsg))
        , Html.p [] [ Html.text "This counter is a component running in the frontend, completely independent of the main app. It manages its own state and renders its own view, which is passed into the main app's view for rendering." ]
        , viewCounter
        , Html.p [] [ Html.text "And this counter is a component running in the backend. It sends messages to the main backend app whenever its count changes, and the backend app broadcasts those messages to the frontend app. The frontend app then renders the counter and sends any `onClick` messages to the backend app, which relays them to the backend counter component." ]
        , Counter.view model.backendCounter
            |> Html.map (\counterMsg -> sendToSelf (BackendCounterClicked counterMsg))
        , Html.p [] [ Html.text "Here's the Frontend model value printed out so you can see the above is true. Notice how the counter component is not present." ]
        , Html.pre [] [ Html.text (Debug.toString model) ]
        , Html.p [] [ Html.text "But we can still ask the Counter component to show us its own state. Here's the Counter.debug view" ]
        , viewCounter

        {-
           @TODO hrm, viewCounter is already compiled to Html.Html FrontendMsg, so we can't pass arguments.
           ideally we could pass in a record i.e. `viewCounter { mode = Counter.Debug }` to give the parent
           a nice typed API to exert some external control over the view. Or maybe even viewCounter could be
           an arbitrary record of values that result in Html.Html FrontendMsg, so one might have `viewCounter.view`
           and `viewCounter.debug` and `viewCounter.somethingFancy { someArg = "blah" }`

           I tried giving this a bash and got introduced to the nice error messages 😆

           I'm imagining this could work well for complex components that have multiple view parts the user would
           want to integrate into their own app in specific ways. For example:

              viewCalendar : {
                horizontal : { months : Int } -> Html.Html msg,
                vertical : { months : Int } -> Html.Html msg,
                datePicker : Html.Html msg
              }

            Where I may want to render the calendar in a horizontal layout with 3 months in my main column, but
            in a vertical layout with 6 months in a sidebar, and also have a date picker component that I can
            render in a modal or a sidebar or a dropdown or whatever.

            So usage would become;

              , p [] [ Html.text "Here's a calendar component" ]
              , viewCalendar.horizontal { months = 3 }
              , p [] [ Html.text "And here's a vertical calendar with 6 months over here" ]
              viewCalendar.vertical { months = 6 }
              , p [] [ Html.text "And here's a date picker over there" ]
              , viewCalendar.datePicker


        -}
        ]
    }
