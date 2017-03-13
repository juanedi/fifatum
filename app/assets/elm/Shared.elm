module Shared
    exposing
        ( loading
        , titleHeader
        , onSelect
        , noData
        , clickableCell
        , modalDialog
        )

import Html exposing (Html, div, span, text, p)
import Html.Attributes exposing (id, class)
import Html.Events as Events
import Json.Decode
import Material
import Material.Button as Button
import Material.Layout as Layout
import Material.Options as Options exposing (cs, css)
import Material.Progress as Progress
import Material.Table as Table
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
                , ( "padding", "0 20px" )
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


clickableCell msg options content =
    Table.td options
        [ div
            [ Events.onClick msg ]
            content
        ]


modalDialog : Material.Model -> (Material.Msg msg -> msg) -> Int -> msg -> List ( String, String ) -> Html msg
modalDialog mdl mdlTagger closeButtonId closeMsg fields =
    let
        modalCloseButton =
            Button.render mdlTagger
                [ closeButtonId ]
                mdl
                [ Options.onClick closeMsg ]
                [ text "Close" ]

        field name value =
            div [ class "field" ]
                [ span [ class "name" ] [ text name ]
                , span [ class "value" ] [ text value ]
                ]
    in
        div [ class "modal-dialog-container" ]
            [ div [ class "modal-dialog" ]
                [ div [ class "content" ] <|
                    List.map (uncurry field) fields
                , div [ class "actions" ]
                    [ modalCloseButton ]
                ]
            ]
