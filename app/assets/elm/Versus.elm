module Versus
    exposing
        ( Model
        , Msg
        , init
        , update
        , view
        )

import Api exposing (User)
import Html exposing (Html, div, span, text, p)
import Html.Attributes exposing (id, class)
import Material
import Material.Options as Options exposing (cs, css)
import Material.Table as Table
import Return
import SelectList exposing (include, maybe)
import Shared


type State
    = Loading
    | Loaded { stats : Api.Stats, openDetail : Maybe Api.RivalStat }


type alias Model =
    { mdl : Material.Model
    , user : User
    , state : State
    }


type Msg
    = Mdl (Material.Msg Msg)
    | FetchOk Api.Stats
    | FetchFailed
    | OpenDetail Api.RivalStat
    | CloseDetail


init : User -> ( Model, Cmd Msg )
init user =
    Return.singleton
        { mdl = Material.model
        , user = user
        , state = Loading
        }
        |> Return.command (Api.fetchStats (always FetchFailed) FetchOk)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( model.state, msg ) of
        ( _, Mdl msg ) ->
            Material.update Mdl msg model

        ( Loading, FetchOk stats ) ->
            Return.singleton <|
                { model | state = Loaded { stats = stats, openDetail = Nothing } }

        ( Loading, FetchFailed ) ->
            -- TODO
            Return.singleton model

        ( Loading, _ ) ->
            Debug.crash "Invalid state"

        ( Loaded state, msg ) ->
            case msg of
                OpenDetail stat ->
                    Return.singleton { model | state = Loaded { state | openDetail = Just stat } }

                CloseDetail ->
                    Return.singleton { model | state = Loaded { state | openDetail = Nothing } }

                _ ->
                    Debug.crash "Invalid state"


view : Model -> Html Msg
view model =
    case model.state of
        Loading ->
            Shared.loading

        Loaded { stats, openDetail } ->
            if List.isEmpty stats.recentMatches then
                -- TODO
                Shared.noData "You haven't played any matches yet"
            else
                versusView model.mdl model.user stats.versus openDetail


versusView : Material.Model -> User -> List Api.RivalStat -> Maybe Api.RivalStat -> Html Msg
versusView mdl user stats openDetail =
    let
        onClick stat =
            OpenDetail stat
    in
        div [ id "stats" ] <|
            SelectList.select
                [ maybe <|
                    Maybe.map
                        (rivalStatDialog mdl)
                        openDetail
                , include <|
                    Table.table [ Options.id "stats-table" ]
                        [ Table.thead []
                            [ Table.tr []
                                [ Table.th [] [ text "Rival" ]
                                , Table.th [ Table.numeric ] [ text "Balance" ]
                                ]
                            ]
                        , Table.tbody
                            []
                            (stats
                                |> List.sortBy (\stat -> stat.lost - stat.won)
                                |> List.indexedMap
                                    (\index stat ->
                                        Table.tr []
                                            [ Shared.clickableCell (onClick stat) [] [ text stat.rivalName ]
                                            , Shared.clickableCell (onClick stat) [ Table.numeric ] [ text (balance stat) ]
                                            ]
                                    )
                            )
                        ]
                ]


rivalStatDialog : Material.Model -> Api.RivalStat -> Html Msg
rivalStatDialog mdl stat =
    Shared.modalDialog mdl
        Mdl
        mdlIds.closeModal
        CloseDetail
        [ ( "Rival", stat.rivalName )
        , ( "Balance", balance stat )
        , ( "Record", (toString stat.won) ++ " victories - " ++ (toString stat.tied) ++ " tied - " ++ (toString stat.lost) ++ " lost" )
        , ( "Goals made", toString stat.goalsMade )
        , ( "Goals received", toString stat.goalsReceived )
        ]


balance : Api.RivalStat -> String
balance stat =
    if stat.won > stat.lost then
        "+" ++ toString (stat.won - stat.lost)
    else
        toString (stat.won - stat.lost)


mdlIds =
    { menu = 1
    , closeModal = 2
    }
