module Composer.Document exposing (addComponent, defineApp, done, run)

import Composer.Element
import Browser


defineApp =
    Composer.Element.defineApp


addComponent =
    Composer.Element.addComponent


done =
    Composer.Element.done

run builder =
    builder
        |> done
        |> Browser.document