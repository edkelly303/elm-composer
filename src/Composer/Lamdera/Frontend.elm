module Composer.Lamdera.Frontend exposing (..)

import Composer
import NestedTuple as NT


defineApp app =
    { app = app
    , emptyComponentsMsg = NT.empty
    , setters = NT.defineSetters
    , initer = NT.define
    , updater = NT.define
    , updaterFromBackend = NT.define
    , viewer = NT.define
    , subscriber = NT.define
    }


addComponent component builder =
    { app = builder.app
    , emptyComponentsMsg = NT.cons Nothing builder.emptyComponentsMsg
    , setters = NT.setter builder.setters
    , initer = NT.folder (initer component.interface component.init) builder.initer
    , updater = NT.folder3 (Composer.updater component.interface component.update) builder.updater
    , updaterFromBackend = NT.folder2 (updaterFromBackend component.interface) builder.updaterFromBackend
    , viewer = NT.folder2 (Composer.viewer component.interface) builder.viewer
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
    , updateFromBackend = updateFromBackend setters sendToApp builder
    , view = Composer.view setters sendToApp builder
    , subscriptions = Composer.subscriptions setters sendToApp builder
    , onUrlRequest = \urlRequest -> builder.app.onUrlRequest urlRequest |> sendToApp
    , onUrlChange = \url -> builder.app.onUrlChange url |> sendToApp
    }


init setters sendToApp builder url key =
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
            appInit sendToApp url key
    in
    ( ( appModel, NT.endAppender componentsModel )
    , Cmd.batch (appCmd :: componentCmdsList)
    )


initer componentInterface componentInit setter acc =
    let
        sendToComponent msg =
            ( Nothing, setter (Just msg) acc.emptyComponentsMsg )

        sendToApp msg =
            ( Just msg, acc.emptyComponentsMsg )

        ( thisComponentModel, thisCmd ) =
            componentInit
                sendToApp
                sendToComponent

        interface =
            componentInterface
                sendToApp
                sendToComponent
                thisComponentModel
    in
    { componentsModel = NT.appender thisComponentModel acc.componentsModel
    , appInit = acc.appInit interface
    , componentCmdsList = thisCmd :: acc.componentCmdsList
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


updaterFromBackend componentInterface setter thisComponentModel acc =
    let
        sendToComponent msg =
            ( Nothing, setter (Just msg) acc.emptyComponentsMsg )

        sendToApp msg =
            ( Just msg, acc.emptyComponentsMsg )

        interface =
            componentInterface
                sendToApp
                sendToComponent
                thisComponentModel

        appUpdate =
            acc.appUpdate interface
    in
    { appUpdate = appUpdate
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


updateFromBackend setters sendToApp builder appMsg ( appModel, componentsModel ) =
    let
        gatherUpdates =
            NT.endFolder2 builder.updaterFromBackend

        { appUpdate } =
            gatherUpdates
                { appUpdate = builder.app.updateFromBackend
                , emptyComponentsMsg = builder.emptyComponentsMsg
                }
                setters
                componentsModel

        ( newAppModel, appCmd ) =
            appUpdate sendToApp appMsg appModel
    in
    ( ( newAppModel, componentsModel )
    , appCmd
    )
