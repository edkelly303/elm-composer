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
    , initer = NT.folder (Composer.initer component.interface component.init) builder.initer
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
    { init = Composer.init setters toApp builder
    , update = Composer.update setters toApp builder
    , view = Composer.view setters toApp builder
    , subscriptions = Composer.subscriptions setters toApp builder
    }
