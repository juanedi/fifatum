module Shared
    exposing
        ( loading
        , titleHeader
        , onSelect
        , noData
        )

import Html exposing (Html, div, text)
import Html.Attributes
import Html.Events as Events
import Json.Decode
import Material.Layout as Layout
import Material.Progress as Progress
import String


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


onSelect : (Int -> msg) -> Html.Attribute msg
onSelect msg =
    let
        decoder =
            Json.Decode.at [ "target", "value" ] Json.Decode.string
                |> Json.Decode.map String.toInt
                |> Json.Decode.map (Result.withDefault (-1))
                |> Json.Decode.map msg
    in
        Events.on "change" decoder


noData : String -> Html msg
noData m =
    div [ Html.Attributes.class "no-data" ]
        [ text m ]
