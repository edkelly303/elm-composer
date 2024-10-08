module Composer exposing (..)

import NestedTuple as NT


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
                acc.flags
    in
    { componentsModel = NT.appender thisComponentModel acc.componentsModel
    , appInit = acc.appInit (\msg -> ( Nothing, setter (Just msg) acc.emptyComponentsMsg ))
    , componentCmdsList = thisCmd :: acc.componentCmdsList
    , flags = acc.flags
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


updater componentUpdate setter maybeThisComponentMsg thisComponentModel acc =
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


viewer componentView setter thisComponentModel acc =
    let
        sendToComponent msg =
            ( Nothing, setter (Just msg) acc.emptyComponentsMsg )

        sendToApp msg =
            ( Just msg, acc.emptyComponentsMsg )

        componentView_ =
            componentView
                sendToApp
                sendToComponent
                thisComponentModel
    in
    { appView = acc.appView componentView_ sendToComponent
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


subscriber componentSubscriptions setter thisComponentModel acc =
    let
        sendToComponent msg =
            ( Nothing, setter (Just msg) acc.emptyComponentsMsg )

        sendToApp msg =
            ( Just msg, acc.emptyComponentsMsg )

        componentSubscriptions_ =
            componentSubscriptions
                sendToApp
                sendToComponent
                thisComponentModel
    in
    { appSubscriptions = acc.appSubscriptions sendToComponent
    , componentSubscriptionsList = componentSubscriptions_ :: acc.componentSubscriptionsList
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


subscriptions setters sendToApp builder ( appModel, componentsModel ) =
    let
        gatherSubscriptions =
            NT.endFolder2 builder.subscriber

        { appSubscriptions, componentSubscriptionsList } =
            gatherSubscriptions
                { appSubscriptions = builder.app.subscriptions
                , componentSubscriptionsList = []
                , emptyComponentsMsg = builder.emptyComponentsMsg
                }
                setters
                componentsModel
    in
    Sub.batch (appSubscriptions sendToApp appModel :: componentSubscriptionsList)


view setters sendToApp builder ( appModel, componentsModel ) =
    let
        gatherComponentViews =
            NT.endFolder2 builder.viewer

        { appView } =
            gatherComponentViews
                { appView = builder.app.view
                , emptyComponentsMsg = builder.emptyComponentsMsg
                }
                setters
                componentsModel
    in
    appView sendToApp appModel


update setters sendToApp builder ( maybeAppMsg, componentsMsg ) ( appModel, componentsModel ) =
    let
        gatherUpdates =
            NT.endFolder3 builder.updater

        { appUpdate, componentCmdsList, newComponentsModel } =
            gatherUpdates
                { appUpdate = builder.app.update
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
                    appUpdate sendToApp appMsg appModel

                Nothing ->
                    ( appModel, Cmd.none )
    in
    ( ( newAppModel, NT.endAppender newComponentsModel )
    , Cmd.batch (appCmd :: componentCmdsList)
    )


init setters sendToApp builder flags =
    let
        initialise =
            NT.endFolder builder.initer

        { appInit, componentCmdsList, componentsModel } =
            initialise
                { emptyComponentsMsg = builder.emptyComponentsMsg
                , flags = flags
                , appInit = builder.app.init
                , componentCmdsList = []
                , componentsModel = NT.define
                }
                setters

        ( appModel, appCmd ) =
            appInit sendToApp flags
    in
    ( ( appModel, NT.endAppender componentsModel )
    , Cmd.batch (appCmd :: componentCmdsList)
    )
