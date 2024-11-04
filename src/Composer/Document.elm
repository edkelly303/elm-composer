module Composer.Document exposing
    ( groupedAs
    , integrate
    , withComponent
    , withElement
    , withSandbox
    , withSimpleComponent
    )

import Composer.Element


integrate =
    Composer.Element.integrate


withSandbox =
    Composer.Element.withSandbox


withElement =
    Composer.Element.withElement


withSimpleComponent =
    Composer.Element.withSimpleComponent


withComponent =
    Composer.Element.withComponent


groupedAs =
    Composer.Element.groupedAs
