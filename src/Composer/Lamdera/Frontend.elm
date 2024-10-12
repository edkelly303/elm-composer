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
    , initer = NT.folder (initer component.view component.init) builder.initer
    , updater = NT.folder3 (Composer.updater component.view component.update) builder.updater
    , updaterFromBackend = NT.folder updaterFromBackend builder.updaterFromBackend
    , viewer = NT.folder2 (Composer.viewer component.view) builder.viewer
    , subscriber = NT.folder2 (Composer.subscriber component.view component.subscriptions) builder.subscriber
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
    , appInit = acc.appInit {toMsg = sendToComponent, view = view}
    , componentCmdsList = thisCmd :: acc.componentCmdsList
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


updaterFromBackend setter acc =
    let
        sendToComponent msg =
            ( Nothing, setter (Just msg) acc.emptyComponentsMsg )

        appUpdate =
            acc.appUpdate sendToComponent
    in
    { appUpdate = appUpdate
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


updateFromBackend setters sendToApp builder appMsg ( appModel, componentsModel ) =
    let
        gatherUpdates =
            NT.endFolder builder.updaterFromBackend

        { appUpdate } =
            gatherUpdates
                { appUpdate = builder.app.updateFromBackend
                , emptyComponentsMsg = builder.emptyComponentsMsg
                }
                setters

        ( newAppModel, appCmd ) =
            appUpdate sendToApp appMsg appModel
    in
    ( ( newAppModel, componentsModel )
    , appCmd
    )
