module Ranking
    exposing
        ( Model
        , Msg
        , init
        , update
        , view
        )

import Html exposing (Html, div, text)
import Material
import Material.Options as Options
import Material.Table as Table
import Material.Typography as Typo


type alias Model =
    { mdl : Material.Model }


type Msg
    = Mdl (Material.Msg Msg)


init : Model
init =
    { mdl = Material.model }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Mdl msg ->
            Material.update msg model


view : Model -> Html Msg
view model =
    let
        center =
            Options.css "text-align" "center"
    in
        div
            []
            [ Html.h3 [] [ text "Ranking" ]
            , Table.table [ Options.css "width" "100%" ]
                [ Table.thead []
                    [ Table.tr []
                        [ Table.th [ center ] [ text "Position" ]
                        , Table.th [] [ text "Name" ]
                        , Table.th [] [ text "Last match" ]
                        ]
                    ]
                , Table.tbody []
                    (data
                        |> List.indexedMap
                            (\index item ->
                                Table.tr []
                                    [ Table.td [ center ] [ text (toString (index + 1)) ]
                                    , Table.td [] [ text item.name ]
                                    , Table.td [] [ text item.lastMatch ]
                                    ]
                            )
                    )
                ]
            ]


data =
    [ { name = "Player 1", lastMatch = "2016-11-15" }
    , { name = "Player 2", lastMatch = "2016-11-19" }
    , { name = "Player 3", lastMatch = "2016-11-18" }
    ]
