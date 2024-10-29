module Composer.Lamdera.Frontend exposing (app, component, compose)

import Composer
import NestedTuple as NT


app app_ =
    { app = app_
    , emptyComponentsMsg = NT.empty
    , setters = NT.defineSetters
    , initer = NT.define
    , updater = NT.define
    , updaterFromBackend = NT.define
    , viewer = NT.define
    , subscriber = NT.define
    }


component component_ appInterface builder =
    { app = builder.app
    , emptyComponentsMsg = NT.cons Nothing builder.emptyComponentsMsg
    , setters = NT.setter builder.setters
    , initer = NT.folder (initer component_.interface component_.init) builder.initer
    , updater = NT.folder3 (Composer.updater appInterface component_.interface component_.update) builder.updater
    , updaterFromBackend = NT.folder2 (updaterFromBackend component_.interface) builder.updaterFromBackend
    , viewer = NT.folder2 (Composer.viewer component_.interface) builder.viewer
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
