module Composer.Application exposing (app, compose, withComponent, withElement, withSandbox, withSimpleComponent)

import Composer
import Html
import NestedTuple as NT


app app_ =
    { app = app_
    , emptyComponentsMsg = NT.empty
    , setters = NT.defineSetters
    , initer = NT.define
    , updater = NT.define
    , viewer = NT.define
    , subscriber = NT.define
    }


withSandbox sandbox builder =
    let
        component =
            { interface = \toSelf model -> sandbox.view model |> Html.map toSelf
            , init = \toSelf flags -> ( sandbox.init, Cmd.none )
            , update = \() toSelf msg model -> ( sandbox.update msg model, Cmd.none )
            , subscriptions = \() toSelf model -> Sub.none
            }
    in
    withComponent component (\toApp appModel -> ()) builder


withElement element builder =
    let
        component =
            { interface = \toSelf model -> element.view model |> Html.map toSelf
            , init = \toSelf flags -> element.init flags |> Tuple.mapSecond (Cmd.map toSelf)
            , update = \() toSelf msg model -> element.update msg model |> Tuple.mapSecond (Cmd.map toSelf)
            , subscriptions = \() toSelf model -> element.subscriptions model |> Sub.map toSelf
            }
    in
    withComponent component (\toApp appModel -> ()) builder


withSimpleComponent simpleComponent builder =
    let
        component =
            { interface = \toSelf model -> simpleComponent.interface toSelf model
            , init = \toSelf flags -> simpleComponent.init flags |> Tuple.mapSecond (Cmd.map toSelf)
            , update = \() toSelf msg model -> simpleComponent.update msg model |> Tuple.mapSecond (Cmd.map toSelf)
            , subscriptions = \() toSelf model -> simpleComponent.subscriptions model |> Sub.map toSelf
            }
    in
    withComponent component (\toApp appModel -> ()) builder


withComponent component_ appInterface builder =
    { app = builder.app
    , emptyComponentsMsg = NT.cons Nothing builder.emptyComponentsMsg
    , setters = NT.setter builder.setters
    , initer = NT.folder (Composer.initer component_.interface component_.init) builder.initer
    , viewer = NT.folder2 (Composer.viewer component_.interface) builder.viewer
    , updater = NT.folder3 (Composer.updater appInterface component_.interface component_.update) builder.updater
    , subscriber = NT.folder2 (Composer.subscriber appInterface component_.interface component_.subscriptions) builder.subscriber
    }


compose ctor builder =
    let
        setters =
            NT.endSetters builder.setters

        toApp msg =
            ( Just msg, builder.emptyComponentsMsg )
    in
    { init = init setters toApp ctor builder
    , update = Composer.update setters toApp ctor builder
    , view = Composer.view setters toApp ctor builder
    , subscriptions = Composer.subscriptions setters toApp ctor builder
    , onUrlRequest = \urlRequest -> builder.app.onUrlRequest urlRequest |> toApp
    , onUrlChange = \url -> builder.app.onUrlChange url |> toApp
    }


init setters toApp ctor builder flags url key =
    let
        initialise =
            NT.endFolder builder.initer

        { args, componentCmdsList, componentsModel } =
            initialise
                { args = ctor
                , emptyComponentsMsg = builder.emptyComponentsMsg
                , flags = flags
                , componentCmdsList = []
                , componentsModel = NT.define
                }
                setters

        ( appModel, appCmd ) =
            builder.app.init args toApp flags url key
    in
    ( ( appModel, NT.endAppender componentsModel )
    , Cmd.batch (appCmd :: componentCmdsList)
    )
