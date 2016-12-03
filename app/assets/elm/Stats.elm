module Stats
    exposing
        ( Model
        , Msg
        , init
        , update
        , header
        , view
        )

import Api exposing (User)
import Html exposing (Html, div, span, text, p)
import Html.Attributes exposing (id, class)
import Html.Events
import Material
import Material.Button as Button
import Material.Layout as Layout
import Material.Menu as Menu
import Material.Options as Options exposing (cs, css)
import Material.Table as Table
import Return
import SelectList exposing (include, maybe)
import Shared
import String
import Util exposing (dateString)


type State
    = Loading
    | RecentMatches { stats : Api.Stats, openDetail : Maybe Api.Match }
    | Versus { stats : Api.Stats, openDetail : Maybe Api.RivalStat }


type alias Model =
    { mdl : Material.Model
    , user : User
    , state : State
    }


type Msg
    = Mdl (Material.Msg Msg)
    | FetchOk Api.Stats
    | FetchFailed
    | MRecentMatches RecentMatchesMsg
    | GoToVersus
    | GoToRecentMatches
    | MVersus VersusMsg


type RecentMatchesMsg
    = OpenMatchDetail Api.Match
    | CloseMatchDetail


type VersusMsg
    = OpenRivalDetail Api.RivalStat
    | CloseRivalDetail


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
            Material.update msg model

        ( Loading, FetchOk stats ) ->
            Return.singleton <|
                initRecentMatches model stats

        ( Loading, FetchFailed ) ->
            Return.singleton model

        ( RecentMatches state, GoToVersus ) ->
            Return.singleton <|
                initVersus model state.stats

        ( RecentMatches state, MRecentMatches msg ) ->
            case msg of
                OpenMatchDetail match ->
                    Return.singleton { model | state = RecentMatches { state | openDetail = Just match } }

                CloseMatchDetail ->
                    Return.singleton { model | state = RecentMatches { state | openDetail = Nothing } }

        ( Versus state, GoToRecentMatches ) ->
            Return.singleton <|
                initRecentMatches model state.stats

        ( Versus state, MVersus msg ) ->
            case msg of
                OpenRivalDetail stat ->
                    Return.singleton { model | state = Versus { state | openDetail = Just stat } }

                CloseRivalDetail ->
                    Return.singleton { model | state = Versus { state | openDetail = Nothing } }

        _ ->
            Debug.crash "Invalid state"


initRecentMatches : Model -> Api.Stats -> Model
initRecentMatches model stats =
    { model | state = RecentMatches { stats = stats, openDetail = Nothing } }


initVersus : Model -> Api.Stats -> Model
initVersus model stats =
    { model | state = Versus { stats = stats, openDetail = Nothing } }


header : Model -> List (Html Msg)
header model =
    let
        items =
            case model.state of
                Loading ->
                    []

                RecentMatches _ ->
                    [ Menu.item
                        [ Menu.onSelect GoToVersus ]
                        [ text "Versus" ]
                    ]

                Versus _ ->
                    [ Menu.item
                        [ Menu.onSelect GoToRecentMatches ]
                        [ text "Recent matches" ]
                    ]

        menu =
            Menu.render Mdl
                [ mdlIds.menu ]
                model.mdl
                [ Menu.ripple
                , Menu.bottomRight
                , css "position" "absolute"
                , css "right" "16px"
                ]
                items
    in
        [ Layout.row []
            [ Layout.title [] [ text "Stats" ]
            , Options.div
                [ cs "secondary-menu" ]
                [ Options.div [] [ menu ] ]
            ]
        ]


view : Model -> Html Msg
view model =
    let
        center =
            Options.css "text-align" "center"
    in
        case model.state of
            Loading ->
                Shared.loading

            RecentMatches { stats, openDetail } ->
                if List.isEmpty stats.recentMatches then
                    Shared.noData "You haven't played any matches yet"
                else
                    recentMatchesView model.mdl model.user stats.recentMatches openDetail

            Versus { stats, openDetail } ->
                if List.isEmpty stats.recentMatches then
                    -- TODO
                    Shared.noData "You haven't played any matches yet"
                else
                    versusView model.mdl model.user stats.versus openDetail


recentMatchesView : Material.Model -> User -> List Api.Match -> Maybe Api.Match -> Html Msg
recentMatchesView mdl user recentMatches openDetail =
    let
        matchCell match options content =
            clickableCell (MRecentMatches <| OpenMatchDetail match) options content
    in
        div [ id "stats" ] <|
            SelectList.select
                [ include <| Html.h5 [] [ text "Last matches" ]
                , maybe <|
                    Maybe.map
                        (matchDetailDialog mdl user)
                        openDetail
                , include <|
                    Table.table [ Options.id "stats-table" ]
                        [ Table.thead []
                            [ Table.tr []
                                [ Table.th [] [ text "Date" ]
                                , Table.th [] [ text "Rival" ]
                                , Table.th [ Table.numeric ] [ text "Result" ]
                                ]
                            ]
                        , Table.tbody []
                            (recentMatches
                                |> List.indexedMap
                                    (\index match ->
                                        Table.tr
                                            []
                                            [ matchCell match [] [ text (dateString match.date) ]
                                            , matchCell match [] [ text (rivalName user match) ]
                                            , matchCell match [ Table.numeric ] [ text (score user match) ]
                                            ]
                                    )
                            )
                        ]
                ]


versusView : Material.Model -> User -> List Api.RivalStat -> Maybe Api.RivalStat -> Html Msg
versusView mdl user stats openDetail =
    let
        onClick stat =
            MVersus <| OpenRivalDetail stat
    in
        div [ id "stats" ] <|
            SelectList.select
                [ include <| Html.h5 [] [ text "Rivals" ]
                , maybe <|
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
                                            [ clickableCell (onClick stat) [] [ text stat.rivalName ]
                                            , clickableCell (onClick stat) [ Table.numeric ] [ text (balance stat) ]
                                            ]
                                    )
                            )
                        ]
                ]


clickableCell msg options content =
    Table.td options
        [ div
            [ Html.Events.onClick msg ]
            content
        ]


balance : Api.RivalStat -> String
balance stat =
    if stat.won > stat.lost then
        "+" ++ toString (stat.won - stat.lost)
    else
        toString (stat.won - stat.lost)


matchDetailDialog : Material.Model -> User -> Api.Match -> Html Msg
matchDetailDialog mdl user match =
    let
        own =
            ownParticipation user match

        rival =
            rivalParticipation user match
    in
        modalDialog mdl
            (MRecentMatches CloseMatchDetail)
            [ ( "Rival", rival.name )
            , ( "Score", (score user match) )
            , ( "Your team", own.team.name )
            , ( "Rival's team", rival.team.name )
            ]


rivalStatDialog : Material.Model -> Api.RivalStat -> Html Msg
rivalStatDialog mdl stat =
    modalDialog mdl
        (MVersus CloseRivalDetail)
        [ ( "Rival", stat.rivalName )
        , ( "Balance", balance stat )
        , ( "Record", (toString stat.won) ++ " victories - " ++ (toString stat.tied) ++ " tied - " ++ (toString stat.lost) ++ " lost" )
        , ( "Goals made", toString stat.goalsMade )
        , ( "Goals received", toString stat.goalsReceived )
        ]


modalDialog : Material.Model -> Msg -> List ( String, String ) -> Html Msg
modalDialog mdl closeMsg fields =
    let
        modalCloseButton =
            Button.render Mdl
                [ mdlIds.closeModal ]
                mdl
                [ Button.onClick closeMsg ]
                [ text "Close" ]

        field name value =
            div [ class "field" ]
                [ span [ class "name" ] [ text name ]
                , span [ class "value" ] [ text value ]
                ]
    in
        div [ class "match-detail-dialog-container" ]
            [ div [ class "match-detail-dialog" ]
                [ div [ class "content" ] <|
                    List.map (uncurry field) fields
                , div [ class "actions" ]
                    [ modalCloseButton ]
                ]
            ]


rivalName : User -> Api.Match -> String
rivalName user match =
    .name (rivalParticipation user match)


score : User -> Api.Match -> String
score user match =
    String.join " - " <|
        List.map toString <|
            [ .goals (ownParticipation user match)
            , .goals (rivalParticipation user match)
            ]


ownParticipation : User -> Api.Match -> Api.Participation
ownParticipation user match =
    if user.id == match.user1.id then
        match.user1
    else
        match.user2


rivalParticipation : User -> Api.Match -> Api.Participation
rivalParticipation user match =
    if user.id == match.user1.id then
        match.user2
    else
        match.user1


mdlIds =
    { menu = 1
    , closeModal = 2
    }
