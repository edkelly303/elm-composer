module Composer.Lamdera.Frontend exposing (groupedAs, integrate, withComponent, withElement, withSandbox, withSimpleComponent)

import Composer
import Html
import NestedTuple as NT


integrate app_ =
    { app = app_
    , emptyComponentsMsg = NT.empty
    , setters = NT.defineSetters
    , initer = NT.define
    , updater = NT.define
    , updaterFromBackend = NT.define
    , viewer = NT.define
    , subscriber = NT.define
    }


withSandbox sandbox builder =
    let
        component =
            { interface = \toSelf model -> sandbox.view model |> Html.map toSelf
            , init = \toSelf -> ( sandbox.init, Cmd.none )
            , update = \() toSelf msg model -> ( sandbox.update msg model, Cmd.none )
            , subscriptions = \() toSelf model -> Sub.none
            }
    in
    withComponent component (\toApp appModel -> ()) builder


withElement element builder =
    let
        component =
            { interface = \toSelf model -> element.view model |> Html.map toSelf
            , init = \toSelf -> element.init |> Tuple.mapSecond (Cmd.map toSelf)
            , update = \() toSelf msg model -> element.update msg model |> Tuple.mapSecond (Cmd.map toSelf)
            , subscriptions = \() toSelf model -> element.subscriptions model |> Sub.map toSelf
            }
    in
    withComponent component (\toApp appModel -> ()) builder


withSimpleComponent simpleComponent builder =
    let
        component =
            { interface = \toSelf model -> simpleComponent.interface toSelf model
            , init = \toSelf -> simpleComponent.init |> Tuple.mapSecond (Cmd.map toSelf)
            , update = \() toSelf msg model -> simpleComponent.update msg model |> Tuple.mapSecond (Cmd.map toSelf)
            , subscriptions = \() toSelf model -> simpleComponent.subscriptions model |> Sub.map toSelf
            }
    in
    withComponent component (\toApp appModel -> ()) builder


withComponent component appInterface builder =
    { app = builder.app
    , emptyComponentsMsg = NT.cons Nothing builder.emptyComponentsMsg
    , setters = NT.setter builder.setters
    , initer = NT.folder (initer component.interface component.init) builder.initer
    , updater = NT.folder3 (Composer.updater appInterface component.interface component.update) builder.updater
    , updaterFromBackend = NT.folder2 (updaterFromBackend component.interface) builder.updaterFromBackend
    , viewer = NT.folder2 (Composer.viewer component.interface) builder.viewer
    , subscriber = NT.folder2 (Composer.subscriber appInterface component.interface component.subscriptions) builder.subscriber
    }


groupedAs ctor builder =
    let
        setters =
            NT.endSetters builder.setters

        toApp msg =
            ( Just msg, builder.emptyComponentsMsg )
    in
    { init = init setters toApp ctor builder
    , update = Composer.update setters toApp ctor builder
    , updateFromBackend = updateFromBackend setters toApp ctor builder
    , view = Composer.view setters toApp ctor builder
    , subscriptions = Composer.subscriptions setters toApp ctor builder
    , onUrlRequest = \urlRequest -> builder.app.onUrlRequest urlRequest |> toApp
    , onUrlChange = \url -> builder.app.onUrlChange url |> toApp
    }


init setters toApp ctor builder url key =
    let
        initialise =
            NT.endFolder builder.initer

        { args, componentCmdsList, componentsModel } =
            initialise
                { args = ctor
                , emptyComponentsMsg = builder.emptyComponentsMsg
                , componentCmdsList = []
                , componentsModel = NT.define
                }
                setters

        ( appModel, appCmd ) =
            builder.app.init args toApp url key
    in
    ( ( appModel, NT.endAppender componentsModel )
    , Cmd.batch (appCmd :: componentCmdsList)
    )


initer makeComponentInterface componentInit setter acc =
    let
        toComponent msg =
            ( Nothing, setter (Just msg) acc.emptyComponentsMsg )

        ( thisComponentModel, thisCmd ) =
            componentInit toComponent

        componentInterface =
            makeComponentInterface
                toComponent
                thisComponentModel
    in
    { args = acc.args componentInterface
    , componentsModel = NT.appender thisComponentModel acc.componentsModel
    , componentCmdsList = thisCmd :: acc.componentCmdsList
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


updaterFromBackend makeComponentInterface setter thisComponentModel acc =
    let
        toComponent msg =
            ( Nothing, setter (Just msg) acc.emptyComponentsMsg )

        componentInterface =
            makeComponentInterface
                toComponent
                thisComponentModel
    in
    { args = acc.args componentInterface
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


updateFromBackend setters toApp ctor builder appMsg ( appModel, componentsModel ) =
    let
        gatherUpdates =
            NT.endFolder2 builder.updaterFromBackend

        { args } =
            gatherUpdates
                { args = ctor
                , emptyComponentsMsg = builder.emptyComponentsMsg
                }
                setters
                componentsModel

        ( newAppModel, appCmd ) =
            builder.app.updateFromBackend args toApp appMsg appModel
    in
    ( ( newAppModel, componentsModel )
    , appCmd
    )
