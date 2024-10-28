module Composer.Element exposing
    ( addComponent
    , addComponentWithRequirements
    , defineApp
    , done
    )

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
    addComponentWithRequirements component (\toApp appModel -> toApp) builder


addComponentWithRequirements component appInterface builder =
    { app = builder.app
    , emptyComponentsMsg = NT.cons Nothing builder.emptyComponentsMsg
    , setters = NT.setter builder.setters
    , initer = NT.folder (Composer.initer component.interface component.init) builder.initer
    , updater = NT.folder3 (Composer.updater appInterface component.interface component.update) builder.updater
    , viewer = NT.folder2 (Composer.viewer component.interface) builder.viewer
    , subscriber = NT.folder2 (Composer.subscriber appInterface component.interface component.subscriptions) builder.subscriber
    }


done ctor builder =
    let
        setters =
            NT.endSetters builder.setters

        toApp msg =
            ( Just msg, builder.emptyComponentsMsg )
    in
    { init = Composer.init setters toApp ctor builder
    , update = Composer.update setters toApp ctor builder
    , view = Composer.view setters toApp ctor builder
    , subscriptions = Composer.subscriptions setters toApp ctor builder
    }
