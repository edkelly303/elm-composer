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
    Composer.integrate
        { init = init
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = subscriptions
        , view = view
        }
        |> Composer.withComponent
            Counter.component
            (\toApp appModel -> { countChanged = \_ -> toApp Noop })
        |> Composer.groupedAs
            (\c -> { counter = c })


init components toSelf url key =
    ( { key = key
      , frontendCounter = 0
      , backendCounterComponent = 0
      }
    , Lamdera.sendToBackend BackendCounterComponentStatusRequested
    )


update components toSelf msg model =
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
            ( { model
                | frontendCounter =
                    case counterMsg of
                        Increment ->
                            model.frontendCounter + 1

                        Decrement ->
                            model.frontendCounter - 1
              }
            , Cmd.none
            )

        BackendCounterComponentClicked counterMsg ->
            ( model, Lamdera.sendToBackend (BackendCounterComponentUpdateRequested counterMsg) )

        Noop ->
            ( model, Cmd.none )


updateFromBackend components toSelf msg model =
    case msg of
        BackendCounterComponentStatusResponded count ->
            ( { model | backendCounterComponent = count }
            , Cmd.none
            )


subscriptions components toSelf model =
    Sub.none


view components toSelf model =
    { title = "`elm-composer` in Lamdera"
    , body =
        [ Html.header [ Attr.style "text-align" "center" ]
            [ Html.h1 [] [ Html.text "Counter Components Demo" ] ]
        , Html.main_ [ Attr.style "padding" "20px" ]
            [ Html.h2 [] [ Html.text "A simple counter" ]
            , Counter.view
                (toSelf (FrontendCounterClicked Increment))
                (toSelf (FrontendCounterClicked Decrement))
                model.frontendCounter
            , Html.p []
                [ Html.text
                    """
                    This is a totally ordinary counter. The main frontend app is 
                    responsible for managing its state (`model.frontendCounter`), 
                    and rendering its view.
                    """
                ]
            , Html.h2 [] [ Html.text "A counter component" ]
            , Counter.view
                components.counter.increment
                components.counter.decrement
                components.counter.count
            , Html.p []
                [ Html.text
                    """
                    This counter is a component running in the frontend, completely 
                    independent of the main frontend app. It manages its own state 
                    and provides an interface that gives the frontend app the 
                    information necessary to render it.
                    """
                ]
            , Html.h2 [] [ Html.text "A counter component running on the backend" ]
            , Counter.view
                (toSelf (BackendCounterComponentClicked Increment))
                (toSelf (BackendCounterComponentClicked Decrement))
                model.backendCounterComponent
            , Html.p []
                [ Html.text
                    """
                    And this counter is a component running on the backend. It 
                    sends messages to the main backend app whenever its count 
                    changes, and the backend app broadcasts those messages to the 
                    frontend app. The frontend app then renders the counter and 
                    sends any `onClick` messages to the backend app, which relays 
                    them to the backend counter component.
                    """
                ]
            , Html.h2 [] [ Html.text "Really?" ]
            , Html.p []
                [ Html.text
                    """
                    Yes! Here's the main frontend app's model value printed out 
                    with `Debug.toString`, so you can see the above is true. 
                    """
                ]
            , Html.pre [ Attr.style "font-size" "16px" ] [ Html.text (Debug.toString model) ]
            , Html.p []
                [ Html.text
                    """
                    Notice how there is no field 
                    called `frontendCounterComponent` - this is because the frontend 
                    counter component's state is stored and managed completely 
                    separately from the main frontend app's model.
                    """
                ]
            , Html.p []
                [ Html.text
                    """
                    Here is the state of the frontend counter component:
                    """
                ]
            , Html.pre [ Attr.style "font-size" "16px" ] [ Html.text components.counter.debug ]
            , Html.p []
                [ Html.text
                    """
                    We can only see this "debug view" of the component's state 
                    because the author of the component has decided to make it 
                    available to us via the component's interface. Our main 
                    frontend app doesn't have direct access to the component's 
                    state.
                    """
                ]
            , Html.p []
                [ Html.text
                    """
                    You might also notice that the main frontend app's model 
                    contains a field called `backendCounterComponent`. This is
                    NOT the actual state of the backend counter component. It's just
                    a copy of that state that the frontend app receives from the 
                    backend and uses to render the counter. 
                    """
                ]
            , Html.p []
                [ Html.text
                    """
                    You can prove that the state is actually managed on the backend 
                    by refreshing the page - you'll see that although the two 
                    counters running on the frontend lose their state and get 
                    reinitialised to zero when the page reloads, the backend counter
                    component keeps its current value.
                    """
                ]
            ]
        ]
    }
