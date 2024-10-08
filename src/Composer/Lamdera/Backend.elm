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
    , initer = NT.folder (initer component.init) builder.initer
    , updater = NT.folder3 (Composer.updater component.update) builder.updater
    , updaterFromFrontend = NT.folder3 (updaterFromFrontend component.updateFromFrontend) builder.updaterFromFrontend
    , subscriber = NT.folder2 (Composer.subscriber component.subscriptions) builder.subscriber
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


initer componentInit setter acc =
    let
        sendToComponent msg =
            ( Nothing, setter (Just msg) acc.emptyComponentsMsg )

        sendToApp msg =
            ( Just msg, acc.emptyComponentsMsg )

        ( thisComponentModel, thisCmd ) =
            componentInit
                sendToApp
                sendToComponent
    in
    { componentsModel = NT.appender thisComponentModel acc.componentsModel
    , appInit = acc.appInit (\msg -> ( Nothing, setter (Just msg) acc.emptyComponentsMsg ))
    , componentCmdsList = thisCmd :: acc.componentCmdsList
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


updaterFromFrontend componentUpdate setter maybeThisComponentMsg thisComponentModel acc =
    let
        sendToComponent msg =
            ( Nothing, setter (Just msg) acc.emptyComponentsMsg )

        sendToApp msg =
            ( Just msg, acc.emptyComponentsMsg )

        appUpdate =
            acc.appUpdate sendToComponent

        ( newThisComponentModel, thisCmd ) =
            case maybeThisComponentMsg of
                Just thisComponentMsg ->
                    componentUpdate
                        sendToApp
                        sendToComponent
                        thisComponentMsg
                        thisComponentModel

                Nothing ->
                    ( thisComponentModel, Cmd.none )
    in
    { appUpdate = appUpdate
    , componentCmdsList = thisCmd :: acc.componentCmdsList
    , newComponentsModel = NT.appender newThisComponentModel acc.newComponentsModel
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


updateFromFrontend setters sendToApp builder sessionId clientId ( maybeAppMsg, componentsMsg ) ( appModel, componentsModel ) =
    let
        gatherUpdates =
            NT.endFolder3 builder.updaterFromFrontend

        { appUpdate, componentCmdsList, newComponentsModel } =
            gatherUpdates
                { appUpdate = builder.app.updateFromFrontend
                , componentCmdsList = []
                , newComponentsModel = NT.define
                , emptyComponentsMsg = builder.emptyComponentsMsg
                }
                setters
                componentsMsg
                componentsModel

        ( newAppModel, appCmd ) =
            case maybeAppMsg of
                Just appMsg ->
                    appUpdate sendToApp sessionId clientId appMsg appModel

                Nothing ->
                    ( appModel, Cmd.none )
    in
    ( ( newAppModel, NT.endAppender newComponentsModel )
    , Cmd.batch (appCmd :: componentCmdsList)
    )
