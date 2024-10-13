module Composer.Lamdera.Backend exposing (..)

import Composer
import NestedTuple as NT


defineApp app =
    { app = app
    , emptyComponentsMsg = NT.empty
    , setters = NT.defineSetters
    , initer = NT.define
    , updater = NT.define
    , updaterFromFrontend = NT.define
    , subscriber = NT.define
    }


addComponent component builder =
    { app = builder.app
    , emptyComponentsMsg = NT.cons Nothing builder.emptyComponentsMsg
    , setters = NT.setter builder.setters
    , initer = NT.folder (initer component.interface component.init) builder.initer
    , updater = NT.folder3 (Composer.updater component.interface component.update) builder.updater
    , updaterFromFrontend = NT.folder updaterFromFrontend builder.updaterFromFrontend
    , subscriber = NT.folder2 (Composer.subscriber component.interface component.subscriptions) builder.subscriber
    }


done builder =
    let
        setters =
            NT.endSetters builder.setters

        sendToApp msg =
            ( Just msg, builder.emptyComponentsMsg )
    in
    { init = init setters sendToApp builder
    , update = Composer.update setters sendToApp builder
    , updateFromFrontend = updateFromFrontend setters sendToApp builder
    , subscriptions = Composer.subscriptions setters sendToApp builder
    }


init setters sendToApp builder =
    let
        initialise =
            NT.endFolder builder.initer

        { appInit, componentCmdsList, componentsModel } =
            initialise
                { emptyComponentsMsg = builder.emptyComponentsMsg
                , appInit = builder.app.init
                , componentCmdsList = []
                , componentsModel = NT.define
                }
                setters

        ( appModel, appCmd ) =
            appInit sendToApp
    in
    ( ( appModel, NT.endAppender componentsModel )
    , Cmd.batch (appCmd :: componentCmdsList)
    )


initer componentView componentInit setter acc =
    let
        sendToComponent msg =
            ( Nothing, setter (Just msg) acc.emptyComponentsMsg )

        sendToApp msg =
            ( Just msg, acc.emptyComponentsMsg )

        ( thisComponentModel, thisCmd ) =
            componentInit
                sendToApp
                sendToComponent

        view =
            componentView
                sendToApp
                sendToComponent
                thisComponentModel
    in
    { componentsModel = NT.appender thisComponentModel acc.componentsModel
    , appInit = acc.appInit { toMsg = sendToComponent, view = view }
    , componentCmdsList = thisCmd :: acc.componentCmdsList
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


updaterFromFrontend setter acc =
    let
        sendToComponent msg =
            ( Nothing, setter (Just msg) acc.emptyComponentsMsg )

        appUpdate =
            acc.appUpdate sendToComponent
    in
    { appUpdate = appUpdate
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


updateFromFrontend setters sendToApp builder sessionId clientId msgFromFrontend ( appModel, componentsModel ) =
    let
        gatherUpdates =
            NT.endFolder builder.updaterFromFrontend

        { appUpdate } =
            gatherUpdates
                { appUpdate = builder.app.updateFromFrontend
                , emptyComponentsMsg = builder.emptyComponentsMsg
                }
                setters

        ( newAppModel, appCmd ) =
            appUpdate sendToApp sessionId clientId msgFromFrontend appModel
    in
    ( ( newAppModel, componentsModel )
    , appCmd
    )
