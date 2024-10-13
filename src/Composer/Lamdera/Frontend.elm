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

        toApp msg =
            ( Just msg, builder.emptyComponentsMsg )
    in
    { init = init setters toApp builder
    , update = Composer.update setters toApp builder
    , updateFromBackend = updateFromBackend setters toApp builder
    , view = Composer.view setters toApp builder
    , subscriptions = Composer.subscriptions setters toApp builder
    , onUrlRequest = \urlRequest -> builder.app.onUrlRequest urlRequest |> toApp
    , onUrlChange = \url -> builder.app.onUrlChange url |> toApp
    }


init setters toApp builder url key =
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
            appInit toApp url key
    in
    ( ( appModel, NT.endAppender componentsModel )
    , Cmd.batch (appCmd :: componentCmdsList)
    )


initer componentInterface componentInit setter acc =
    let
        sendToComponent msg =
            ( Nothing, setter (Just msg) acc.emptyComponentsMsg )

        toApp msg =
            ( Just msg, acc.emptyComponentsMsg )

        ( thisComponentModel, thisCmd ) =
            componentInit
                toApp
                sendToComponent

        interface =
            componentInterface
                toApp
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

        toApp msg =
            ( Just msg, acc.emptyComponentsMsg )

        interface =
            componentInterface
                toApp
                sendToComponent
                thisComponentModel

        appUpdate =
            acc.appUpdate interface
    in
    { appUpdate = appUpdate
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


updateFromBackend setters toApp builder appMsg ( appModel, componentsModel ) =
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
            appUpdate toApp appMsg appModel
    in
    ( ( newAppModel, componentsModel )
    , appCmd
    )
