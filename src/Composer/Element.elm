module Composer.Element exposing (..)

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
    , initer = NT.folder (Composer.initer component) builder.initer
    , updater = NT.folder3 (Composer.updater component) builder.updater
    , viewer = NT.folder2 (Composer.viewer component) builder.viewer
    , subscriber = NT.folder2 (Composer.subscriber component) builder.subscriber
    }


done builder =
    let
        setters =
            NT.endSetters builder.setters

        sendToApp msg =
            ( Just msg, builder.emptyComponentsMsg )
    in
    { init = Composer.init setters sendToApp builder
    , update = Composer.update setters sendToApp builder
    , view = Composer.view setters sendToApp builder
    , subscriptions = Composer.subscriptions setters sendToApp builder
    }
