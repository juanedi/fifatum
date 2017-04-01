module Versus
    exposing
        ( Model
        , Msg(Event)
        , VersusEvent(..)
        , init
        , update
        , view
        )

import Api exposing (User)
import Html exposing (Html, div, span, text, p)
import Html.Attributes exposing (id, class)
import Html.Events as Events
import Material
import Material.Button as Button
import Material.Icon as Icon
import Material.Options as Options exposing (cs, css)
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
    | Event VersusEvent
    | FetchOk Api.Stats
    | FetchFailed
    | OpenDetail Api.RivalStat
    | CloseDetail


type VersusEvent
    = NewMatch


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
                case openDetail of
                    Nothing ->
                        versusView model.mdl model.user stats.versus

                    Just rivalStat ->
                        detailView model.mdl rivalStat


versusView : Material.Model -> User -> List Api.RivalStat -> Html Msg
versusView mdl user stats =
    div []
        [ div [ id "stats" ] <|
            [ statsListing (List.sortBy (\stat -> (-1) * balance stat) stats) ]
        , newMatchButton mdl
        ]


detailView : Material.Model -> Api.RivalStat -> Html Msg
detailView mdl stat =
    let
        fields =
            [ ( "Balance", displayBalance stat )
            , ( "Matches", toString (stat.won + stat.tied + stat.lost) )
            , ( "Record", (toString stat.won) ++ " victories - " ++ (toString stat.tied) ++ " tied - " ++ (toString stat.lost) ++ " lost" )
            , ( "Goals made", toString stat.goalsMade )
            , ( "Goals received", toString stat.goalsReceived )
            ]

        renderField ( name, value ) =
            Html.li
                []
                [ span [ class "name" ] [ text name ]
                , span [ class "value" ] [ text value ]
                ]
    in
        div [ class "rival-stat-detail" ]
            [ Html.h1 [] [ text stat.rivalName ]
            , Html.ul
                [ class "rival-stat-fields" ]
                (List.map renderField fields)
            , div [ class "actions" ]
                [ Button.render Mdl
                    [ mdlIds.closeModal ]
                    mdl
                    [ Options.onClick CloseDetail, Button.colored, Button.raised, Options.cs "main-action-btn" ]
                    [ text "Close" ]
                ]
            ]


statsListing : List Api.RivalStat -> Html Msg
statsListing stats =
    let
        statRow stat =
            Html.li
                [ Events.onClick (OpenDetail stat) ]
                [ span [ class "item-main" ] [ text stat.rivalName ]
                , span [ class "balance-num" ] [ text (displayBalance stat) ]
                , span [ class "icon" ] [ Icon.i (balanceIcon stat) ]
                ]
    in
        Html.ul [ class "listing" ] <|
            List.map statRow stats


balance : Api.RivalStat -> Int
balance stat =
    stat.won - stat.lost


balanceIcon : Api.RivalStat -> String
balanceIcon stat =
    if balance stat == 0 then
        "trending_flat"
    else if balance stat > 1 then
        "trending_up"
    else
        "trending_down"


displayBalance : Api.RivalStat -> String
displayBalance stat =
    if stat.won > stat.lost then
        "+" ++ toString (balance stat)
    else
        toString (balance stat)


newMatchButton : Material.Model -> Html Msg
newMatchButton mdl =
    Shared.newMatchButton mdlIds.newMatch mdl Mdl (Event NewMatch)


mdlIds =
    { menu = 1
    , closeModal = 2
    , newMatch = 3
    }
