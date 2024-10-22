module Composer exposing (..)

import NestedTuple as NT


initer componentInit setter acc =
    let
        toComponent msg =
            ( Nothing, setter (Just msg) acc.emptyComponentsMsg )

        toApp msg =
            ( Just msg, acc.emptyComponentsMsg )

        ( thisComponentModel, thisCmd ) =
            componentInit
                toApp
                toComponent
                acc.flags
    in
    { componentsModel = NT.appender thisComponentModel acc.componentsModel
    , componentCmdsList = thisCmd :: acc.componentCmdsList
    , flags = acc.flags
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


updater makeAppInterface makeComponentInterface componentUpdate setter maybeThisComponentMsg thisComponentModel acc =
    let
        toComponent msg =
            ( Nothing, setter (Just msg) acc.emptyComponentsMsg )

        toApp msg =
            ( Just msg, acc.emptyComponentsMsg )

        ( newThisComponentModel, thisCmd ) =
            case maybeThisComponentMsg of
                Just thisComponentMsg ->
                    componentUpdate
                        (makeAppInterface toApp acc.appModel)
                        toComponent
                        thisComponentMsg
                        thisComponentModel

                Nothing ->
                    ( thisComponentModel, Cmd.none )

        componentInterface =
            makeComponentInterface
                (makeAppInterface toApp acc.appModel)
                toComponent
                newThisComponentModel
    in
    { appUpdate = acc.appUpdate componentInterface
    , componentCmdsList = thisCmd :: acc.componentCmdsList
    , newComponentsModel = NT.appender newThisComponentModel acc.newComponentsModel
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


viewer makeAppInterface makeComponentInterface setter thisComponentModel acc =
    let
        sendToComponent msg =
            ( Nothing, setter (Just msg) acc.emptyComponentsMsg )

        toApp msg =
            ( Just msg, acc.emptyComponentsMsg )

        componentInterface =
            makeComponentInterface
                (makeAppInterface toApp acc.appModel)
                sendToComponent
                thisComponentModel
    in
    { appView = acc.appView componentInterface
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


subscriber makeAppInterface makeComponentInterface componentSubscriptions setter thisComponentModel acc =
    let
        sendToComponent msg =
            ( Nothing, setter (Just msg) acc.emptyComponentsMsg )

        toApp msg =
            ( Just msg, acc.emptyComponentsMsg )

        componentInterface =
            makeComponentInterface
                (makeAppInterface toApp acc.appModel)
                sendToComponent
                thisComponentModel

        componentSubscriptions_ =
            componentSubscriptions
                (makeAppInterface toApp acc.appModel)
                sendToComponent
                thisComponentModel
    in
    { appSubscriptions = acc.appSubscriptions componentInterface
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
                , appModel = appModel
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
                , appModel = appModel
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
                , appModel = appModel
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

        ( appModel, appCmd ) =
            builder.app.init toApp flags

        { componentCmdsList, componentsModel } =
            initialise
                { emptyComponentsMsg = builder.emptyComponentsMsg
                , flags = flags
                , componentCmdsList = []
                , componentsModel = NT.define
                }
                setters
    in
    ( ( appModel, NT.endAppender componentsModel )
    , Cmd.batch (appCmd :: componentCmdsList)
    )
