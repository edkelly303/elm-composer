module Composer exposing (..)

import NestedTuple as NT


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
                acc.flags

        interface =
            componentInterface
                toApp
                sendToComponent
                thisComponentModel
    in
    { componentsModel = NT.appender thisComponentModel acc.componentsModel
    , appInit = acc.appInit interface
    , componentCmdsList = thisCmd :: acc.componentCmdsList
    , flags = acc.flags
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


updater componentInterface componentUpdate setter maybeThisComponentMsg thisComponentModel acc =
    let
        sendToComponent msg =
            ( Nothing, setter (Just msg) acc.emptyComponentsMsg )

        toApp msg =
            ( Just msg, acc.emptyComponentsMsg )

        ( newThisComponentModel, thisCmd ) =
            case maybeThisComponentMsg of
                Just thisComponentMsg ->
                    componentUpdate
                        toApp
                        sendToComponent
                        thisComponentMsg
                        thisComponentModel

                Nothing ->
                    ( thisComponentModel, Cmd.none )

        interface =
            componentInterface
                toApp
                sendToComponent
                newThisComponentModel

        appUpdate =
            acc.appUpdate interface
    in
    { appUpdate = appUpdate
    , componentCmdsList = thisCmd :: acc.componentCmdsList
    , newComponentsModel = NT.appender newThisComponentModel acc.newComponentsModel
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


viewer componentInterface setter thisComponentModel acc =
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
    in
    { appView = acc.appView interface
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


subscriber componentInterface componentSubscriptions setter thisComponentModel acc =
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

        componentSubscriptions_ =
            componentSubscriptions
                toApp
                sendToComponent
                thisComponentModel
    in
    { appSubscriptions = acc.appSubscriptions interface
    , componentSubscriptionsList = componentSubscriptions_ :: acc.componentSubscriptionsList
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


subscriptions setters toApp builder ( appModel, componentsModel ) =
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
    Sub.batch (appSubscriptions toApp appModel :: componentSubscriptionsList)


view setters toApp builder ( appModel, componentsModel ) =
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
    appView toApp appModel


update setters toApp builder ( maybeAppMsg, componentsMsg ) ( appModel, componentsModel ) =
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
                    appUpdate toApp appMsg appModel

                Nothing ->
                    ( appModel, Cmd.none )
    in
    ( ( newAppModel, NT.endAppender newComponentsModel )
    , Cmd.batch (appCmd :: componentCmdsList)
    )


init setters toApp builder flags =
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
            appInit toApp flags
    in
    ( ( appModel, NT.endAppender componentsModel )
    , Cmd.batch (appCmd :: componentCmdsList)
    )
