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
    { args = acc.args componentInterface
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
    { args = acc.args componentInterface
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
    { args = acc.args componentInterface
    , componentSubscriptionsList = componentSubscriptions_ :: acc.componentSubscriptionsList
    , emptyComponentsMsg = acc.emptyComponentsMsg
    }


subscriptions setters toApp ctor builder ( appModel, componentsModel ) =
    let
        gatherSubscriptions =
            NT.endFolder2 builder.subscriber

        { args, componentSubscriptionsList } =
            gatherSubscriptions
                { args = ctor
                , appModel = appModel
                , componentSubscriptionsList = []
                , emptyComponentsMsg = builder.emptyComponentsMsg
                }
                setters
                componentsModel
    in
    Sub.batch (builder.app.subscriptions args toApp appModel :: componentSubscriptionsList)


view setters toApp ctor builder ( appModel, componentsModel ) =
    let
        gatherComponentViews =
            NT.endFolder2 builder.viewer

        { args } =
            gatherComponentViews
                { args = ctor
                , appModel = appModel
                , emptyComponentsMsg = builder.emptyComponentsMsg
                }
                setters
                componentsModel
    in
    builder.app.view args toApp appModel


update setters toApp ctor builder ( maybeAppMsg, componentsMsg ) ( appModel, componentsModel ) =
    let
        gatherUpdates =
            NT.endFolder3 builder.updater

        { args, componentCmdsList, newComponentsModel } =
            gatherUpdates
                { args = ctor
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
                    builder.app.update args toApp appMsg appModel

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
