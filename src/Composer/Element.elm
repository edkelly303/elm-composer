module Composer.Element exposing
    ( component
    , componentWithRequirements
    , app
    , compose
    )

import Composer
import NestedTuple as NT


app app_ =
    { app = app_
    , emptyComponentsMsg = NT.empty
    , setters = NT.defineSetters
    , initer = NT.define
    , updater = NT.define
    , viewer = NT.define
    , subscriber = NT.define
    }


component component_ builder =
    componentWithRequirements component_ (\toApp appModel -> ()) builder


componentWithRequirements component_ appInterface builder =
    { app = builder.app
    , emptyComponentsMsg = NT.cons Nothing builder.emptyComponentsMsg
    , setters = NT.setter builder.setters
    , initer = NT.folder (Composer.initer component_.interface component_.init) builder.initer
    , updater = NT.folder3 (Composer.updater appInterface component_.interface component_.update) builder.updater
    , viewer = NT.folder2 (Composer.viewer component_.interface) builder.viewer
    , subscriber = NT.folder2 (Composer.subscriber appInterface component_.interface component_.subscriptions) builder.subscriber
    }


compose ctor builder =
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
