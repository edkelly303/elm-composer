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
    , initer = NT.folder (Composer.initer component.init) builder.initer
    , updater = NT.folder3 (Composer.updater component.update) builder.updater
    , updaterFromBackend = NT.folder3 (Composer.updater component.updateFromBackend) builder.updaterFromBackend
    , viewer = NT.folder2 (Composer.viewer component.view) builder.viewer
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
    , updateFromBackend = Composer.update setters sendToApp builder
    , view = Composer.view setters sendToApp builder
    , subscriptions = Composer.subscriptions setters sendToApp builder
    , onUrlRequest = \urlRequest -> builder.app.onUrlRequest urlRequest |> sendToApp
    , onUrlChange = \url -> builder.app.onUrlChange url |> sendToApp
    }


init setters sendToApp builder flags url key =
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
            appInit sendToApp flags url key
    in
    ( ( appModel, NT.endAppender componentsModel )
    , Cmd.batch (appCmd :: componentCmdsList)
    )
