module Composer.Application exposing (addComponent, defineApp, done)

import Composer
import NestedTuple as NT


defineApp app =
    { app = app
    , emptyComponentsMsg = NT.empty
    , setters = NT.defineSetters
    , initer = NT.define
    , updater = NT.define
    , viewer = NT.define
    , subscriber = NT.define
    }


addComponent component builder =
    { app = builder.app
    , emptyComponentsMsg = NT.cons Nothing builder.emptyComponentsMsg
    , setters = NT.setter builder.setters
    , initer = NT.folder (Composer.initer component.init) builder.initer
    , updater = NT.folder3 (Composer.updater component.interface component.update) builder.updater
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
    , view = Composer.view setters toApp builder
    , subscriptions = Composer.subscriptions setters toApp builder
    , onUrlRequest = \urlRequest -> builder.app.onUrlRequest urlRequest |> toApp
    , onUrlChange = \url -> builder.app.onUrlChange url |> toApp
    }


init setters toApp builder flags url key =
    let
        initialise =
            NT.endFolder builder.initer

        { componentCmdsList, componentsModel } =
            initialise
                { emptyComponentsMsg = builder.emptyComponentsMsg
                , flags = flags
                , componentCmdsList = []
                , componentsModel = NT.define
                }
                setters

        ( appModel, appCmd ) =
            builder.app.init toApp flags url key
    in
    ( ( appModel, NT.endAppender componentsModel )
    , Cmd.batch (appCmd :: componentCmdsList)
    )
