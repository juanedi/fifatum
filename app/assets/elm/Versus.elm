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
import Html.Events as Events
import Material
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
    div [ id "stats" ] <|
        SelectList.select
            [ maybe <|
                Maybe.map
                    (rivalStatDialog mdl)
                    openDetail
            , include <|
                statsListing (List.sortBy (\stat -> (-1) * balance stat) stats)
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


rivalStatDialog : Material.Model -> Api.RivalStat -> Html Msg
rivalStatDialog mdl stat =
    Shared.modalDialog mdl
        Mdl
        mdlIds.closeModal
        CloseDetail
        [ ( "Rival", stat.rivalName )
        , ( "Balance", displayBalance stat )
        , ( "Record", (toString stat.won) ++ " victories - " ++ (toString stat.tied) ++ " tied - " ++ (toString stat.lost) ++ " lost" )
        , ( "Goals made", toString stat.goalsMade )
        , ( "Goals received", toString stat.goalsReceived )
        ]


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


mdlIds =
    { menu = 1
    , closeModal = 2
    }
