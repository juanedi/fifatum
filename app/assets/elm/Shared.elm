module Shared exposing (loading)

import Html exposing (div, text)
import Html.Attributes
import Material.Progress as Progress


loading =
    div
        [ Html.Attributes.style
            [ ( "margin", "auto" )
            , ( "height", "85vh" )
            ]
        ]
        [ div
            [ Html.Attributes.style
                [ ( "position", "relative" )
                , ( "top", "50%" )
                , ( "transform", "translateY(-50%)" )
                , ( "max-width", "500px" )
                , ( "margin", "auto" )
                ]
            ]
            [ Progress.indeterminate
            ]
        ]
