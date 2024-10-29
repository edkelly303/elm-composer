module Composer.Lamdera.Backend exposing (app, component, compose)

import Composer
import NestedTuple as NT


app app_ =
    { app = app_
    , emptyComponentsMsg = NT.empty
    , setters = NT.defineSetters
    , initer = NT.define
    , updater = NT.define
    , updaterFromFrontend = NT.define
    , subscriber = NT.define
    }


component component_ appInterface builder =
    { app = builder.app
    , emptyComponentsMsg = NT.cons Nothing builder.emptyComponentsMsg
    , setters = NT.setter builder.setters
    , initer = NT.folder (initer component_.interface component_.init) builder.initer
    , updater = NT.folder3 (Composer.updater appInterface component_.interface component_.update) builder.updater
    , updaterFromFrontend = NT.folder2 (updaterFromFrontend appInterface component_.interface) builder.updaterFromFrontend
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
    , updateFromFrontend = updateFromFrontend setters toApp ctor builder
    , subscriptions = Composer.subscriptions setters toApp ctor builder
    }


init setters toApp ctor builder =
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
            builder.app.init args toApp
    in
    ( ( appModel, NT.endAppender componentsModel )
    , Cmd.batch (appCmd :: componentCmdsList)
    )


initer makeComponentInterface componentInit setter acc =
    let
        sendToComponent msg =
            ( Nothing, setter (Just msg) acc.emptyComponentsMsg )

        ( thisComponentModel, thisCmd ) =
            componentInit sendToComponent

        componentInterface =
            makeComponentInterface
                sendToComponent
                thisComponentModel
    in
    { args = acc.args componentInterface
    , componentsModel = NT.appender thisComponentModel acc.componentsModel
    , componentCmdsList = thisCmd :: acc.componentCmdsList
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


updaterFromFrontend appInterface makeComponentInterface setter thisComponentModel acc =
    let
        toComponent msg =
            ( Nothing, setter (Just msg) acc.emptyComponentsMsg )

        toApp msg =
            ( Just msg, acc.emptyComponentsMsg )

        componentInterface =
            makeComponentInterface
                toComponent
                thisComponentModel
    in
    { args = acc.args componentInterface
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


updateFromFrontend setters toApp ctor builder sessionId clientId msgFromFrontend ( appModel, componentsModel ) =
    let
        gatherUpdates =
            NT.endFolder2 builder.updaterFromFrontend

        { args } =
            gatherUpdates
                { args = ctor
                , emptyComponentsMsg = builder.emptyComponentsMsg
                }
                setters
                componentsModel

        ( newAppModel, appCmd ) =
            builder.app.updateFromFrontend args toApp sessionId clientId msgFromFrontend appModel
    in
    ( ( newAppModel, componentsModel )
    , appCmd
    )
