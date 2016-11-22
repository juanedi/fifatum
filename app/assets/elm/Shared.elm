module Shared
    exposing
        ( loading
        , titleHeader
        )

import Html exposing (Html, div, text)
import Html.Attributes
import Material.Layout as Layout
import Material.Progress as Progress


titleHeader : String -> List (Html msg)
titleHeader title =
    [ Layout.row []
        [ Layout.title [] [ text title ]
        ]
    ]


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
