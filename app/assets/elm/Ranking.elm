module Ranking
    exposing
        ( Model
        , Msg
        , init
        , update
        , view
        )

import Api
import Html exposing (Html, div, text)
import Html.Attributes
import Material
import Material.Options as Options
import Material.Progress as Progress
import Material.Table as Table
import Return


type State
    = Loading
    | Loaded Api.Ranking


type alias Model =
    { mdl : Material.Model
    , state : State
    }


type Msg
    = Mdl (Material.Msg Msg)
    | FetchOk Api.Ranking
    | FetchFailed


init : ( Model, Cmd Msg )
init =
    Return.singleton
        { mdl = Material.model
        , state = Loading
        }
        |> Return.command (Api.fetchRanking (always FetchFailed) FetchOk)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Mdl msg ->
            Material.update msg model

        FetchOk ranking ->
            Return.singleton { model | state = Loaded ranking }

        FetchFailed ->
            -- TODO
            Return.singleton model


view : Model -> Html Msg
view model =
    let
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

        center =
            Options.css "text-align" "center"
    in
        case model.state of
            Loading ->
                loading

            Loaded ranking ->
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
                            (ranking
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
