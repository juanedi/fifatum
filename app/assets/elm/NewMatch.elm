module NewMatch
    exposing
        ( Model
        , Msg(Event)
        , NewMatchEvent(..)
        , init
        , update
        , view
        )

import Api exposing (User, League, Team)
import Html
import Html exposing (Html, div, text, label, select)
import Html.Attributes exposing (for, id, style, value, selected, disabled, class)
import I18n exposing (..)
import Material
import Material.Button as Button
import Material.Grid exposing (grid, cell, size, Device(..))
import Material.Options as Options
import Return exposing (return, singleton, command)
import Shared
import Util


type State
    = Loading LoadingState
    | NoData String
    | TeamSelection TeamSelectionState
    | ExpandedSelection ExpandedSelectionState
    | Scoring ScoringState
    | Submitted


type alias LoadingState =
    { ownRecentTeams : Maybe (List Team)
    , otherUsers : Maybe (List User)
    , leagues : Maybe (List League)
    }


type alias TeamSelectionState =
    { leagues : List League
    , ownRecentTeams : List Team
    , ownTeam : Maybe Team
    , otherUsers : List User
    , rival : User
    , rivalRecentTeams : Maybe (List Team)
    , rivalTeam : Maybe Team
    }


type alias ExpandedSelectionState =
    { target : TeamTarget
    , context : TeamSelectionState
    , league : League
    , teams : Maybe (List Team)
    , selection : Maybe Team
    }


type alias ScoringState =
    { rival : User
    , ownTeam : Team
    , rivalTeam : Team
    , ownScore : Int
    , rivalScore : Int
    }


type alias Model =
    { mdl : Material.Model
    , user : User
    , state : State
    }


type Msg
    = Event NewMatchEvent
    | Mdl (Material.Msg Msg)
    | FetchFailed
    | MLoading LoadingMsg
    | MTeamSelection TeamSelectMsg
    | MExpandedSelection ExpandedSelectionMsg
    | MScoring ScoringMsg
    | MSubmitted SubmittedMsg


type NewMatchEvent
    = MatchReportOk


type LoadingMsg
    = FetchedOtherUsers Api.UsersResponse
    | FetchedOwnRecentTeams (List Team)
    | FetchedLeagues (List League)


type TeamSelectMsg
    = FetchedRivalRecentTeams (List Team)
    | RivalChanged Int
    | TeamChange TeamTarget Team
    | TeamSelectionDone Team Team
    | ExpandSelection TeamTarget


type ExpandedSelectionMsg
    = LeagueChange League
    | TeamChangedExpanded Team
    | FetchedTeams (List Team)
    | Done


type ScoringMsg
    = Goal TeamTarget
    | Reset
    | Report


type SubmittedMsg
    = ReportFailed
    | ReportOk


type TeamTarget
    = Own
    | Rival


init : User -> ( Model, Cmd Msg )
init user =
    singleton
        { mdl = Material.model
        , user = user
        , state = Loading { ownRecentTeams = Nothing, otherUsers = Nothing, leagues = Nothing }
        }
        |> command (Api.fetchUsers (always FetchFailed) (MLoading << FetchedOtherUsers))
        |> command (Api.fetchRecentTeams (always FetchFailed) (MLoading << FetchedOwnRecentTeams) user)
        |> command (Api.fetchLeagues (always FetchFailed) (MLoading << FetchedLeagues))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Event _ ->
            singleton model

        Mdl msg ->
            Material.update Mdl msg model

        FetchFailed ->
            -- TODO
            singleton model

        _ ->
            case ( model.state, msg ) of
                ( Loading state, MLoading msg ) ->
                    updateLoading model state msg

                ( NoData _, _ ) ->
                    singleton model

                ( TeamSelection state, MTeamSelection msg ) ->
                    updateTeamSelection model state msg

                ( ExpandedSelection state, MExpandedSelection msg ) ->
                    updateExpandedSelection model state msg

                ( Scoring state, MScoring msg ) ->
                    case msg of
                        Goal target ->
                            let
                                updatedState =
                                    case target of
                                        Own ->
                                            { state | ownScore = state.ownScore + 1 }

                                        Rival ->
                                            { state | rivalScore = state.rivalScore + 1 }
                            in
                                singleton { model | state = Scoring updatedState }

                        Reset ->
                            singleton { model | state = Scoring { state | ownScore = 0, rivalScore = 0 } }

                        Report ->
                            let
                                report =
                                    ( { user = model.user, team = state.ownTeam, goals = state.ownScore }
                                    , { user = state.rival, team = state.rivalTeam, goals = state.rivalScore }
                                    )
                            in
                                singleton { model | state = Submitted }
                                    |> command (Api.reportMatch (always (MSubmitted ReportFailed)) (MSubmitted ReportOk) report)

                ( Submitted, MSubmitted msg ) ->
                    case msg of
                        ReportOk ->
                            singleton model
                                |> Util.perform (Event MatchReportOk)

                        ReportFailed ->
                            -- TODO
                            singleton model

                _ ->
                    Debug.crash "invalid state"


updateLoading : Model -> LoadingState -> LoadingMsg -> ( Model, Cmd Msg )
updateLoading model state msg =
    initTeamSelectionWhenReady <|
        case msg of
            FetchedOwnRecentTeams teams ->
                { model | state = Loading { state | ownRecentTeams = Just teams } }

            FetchedOtherUsers { users, lastRivalId } ->
                let
                    otherUsers =
                        users
                            |> List.filter (\u -> u.id /= model.user.id)
                            |> List.sortBy (rivalSortCriteria lastRivalId)
                in
                    if List.isEmpty otherUsers then
                        { model | state = NoData (t NewMatchNoRivals) }
                    else
                        { model | state = Loading { state | otherUsers = Just otherUsers } }

            FetchedLeagues leagues ->
                if List.isEmpty leagues then
                    { model | state = NoData (t NewMatchNoTeams) }
                else
                    { model | state = Loading { state | leagues = Just (List.sortBy .name leagues) } }


rivalSortCriteria : Maybe Int -> User -> ( Int, String )
rivalSortCriteria lastRivalId =
    let
        boolToInt b =
            if b then
                0
            else
                1

        isLastRival user =
            lastRivalId
                |> Maybe.map ((==) user.id)
                |> Maybe.withDefault False
                |> boolToInt
    in
        \u -> ( isLastRival u, u.name )


updateTeamSelection : Model -> TeamSelectionState -> TeamSelectMsg -> ( Model, Cmd Msg )
updateTeamSelection model state msg =
    let
        setState s =
            singleton { model | state = TeamSelection s }
    in
        case msg of
            FetchedRivalRecentTeams teams ->
                setState
                    { state
                        | rivalTeam = List.head teams
                        , rivalRecentTeams = Just teams
                    }

            RivalChanged userId ->
                let
                    rival =
                        state.otherUsers
                            |> List.filter (\u -> u.id == userId)
                            |> List.head
                in
                    case rival of
                        Nothing ->
                            Debug.crash "Selected an invalid option"

                        Just rival ->
                            setState { state | rival = rival, rivalRecentTeams = Nothing }
                                |> command (Api.fetchRecentTeams (always FetchFailed) (MTeamSelection << FetchedRivalRecentTeams) rival)

            TeamChange Own team ->
                setState { state | ownTeam = Just team }

            TeamChange Rival team ->
                setState { state | rivalTeam = Just team }

            ExpandSelection target ->
                initExpandedSelection model state target

            TeamSelectionDone ownTeam rivalTeam ->
                singleton
                    { model
                        | state =
                            Scoring
                                { rival = state.rival
                                , ownTeam = ownTeam
                                , rivalTeam = rivalTeam
                                , ownScore = 0
                                , rivalScore = 0
                                }
                    }


updateExpandedSelection : Model -> ExpandedSelectionState -> ExpandedSelectionMsg -> ( Model, Cmd Msg )
updateExpandedSelection model state msg =
    let
        setState s =
            singleton { model | state = ExpandedSelection s }
    in
        case msg of
            LeagueChange league ->
                setState { state | league = league, teams = Nothing, selection = Nothing }
                    |> command (Api.fetchTeams (always FetchFailed) (MExpandedSelection << FetchedTeams) league)

            TeamChangedExpanded team ->
                setState { state | selection = Just team }

            FetchedTeams teams ->
                let
                    sorted =
                        List.sortBy .name teams
                in
                    setState { state | teams = Just sorted, selection = List.head sorted }

            Done ->
                let
                    context =
                        state.context

                    setState s =
                        singleton { model | state = TeamSelection s }

                    addTeam team maybeList =
                        Maybe.withDefault [] maybeList
                            |> (\l ->
                                    if (List.member team l) then
                                        l
                                    else
                                        team :: l
                               )
                            |> List.sortBy .name
                in
                    case state.selection of
                        Nothing ->
                            Debug.crash "invalid state"

                        Just team ->
                            case state.target of
                                Own ->
                                    setState
                                        { context
                                            | ownRecentTeams = addTeam team (Just state.context.ownRecentTeams)
                                            , ownTeam = state.selection
                                        }

                                Rival ->
                                    setState
                                        { context
                                            | rivalRecentTeams = Just (addTeam team (state.context.rivalRecentTeams))
                                            , rivalTeam = state.selection
                                        }


initExpandedSelection : Model -> TeamSelectionState -> TeamTarget -> ( Model, Cmd Msg )
initExpandedSelection model state target =
    case state.leagues of
        [] ->
            Debug.crash "Invalid state"

        l :: _ ->
            singleton
                { model
                    | state =
                        ExpandedSelection
                            { target = target
                            , context = state
                            , league = l
                            , teams = Nothing
                            , selection = Nothing
                            }
                }
                |> command (Api.fetchTeams (always FetchFailed) (MExpandedSelection << FetchedTeams) l)


initTeamSelectionWhenReady : Model -> ( Model, Cmd Msg )
initTeamSelectionWhenReady model =
    case model.state of
        Loading { ownRecentTeams, otherUsers, leagues } ->
            case ( ownRecentTeams, otherUsers, leagues ) of
                ( Just ts, Just (r :: rs), Just ls ) ->
                    singleton
                        { model
                            | state =
                                TeamSelection
                                    { leagues = ls
                                    , ownRecentTeams = ts
                                    , ownTeam = List.head ts
                                    , otherUsers = r :: rs
                                    , rival = r
                                    , rivalRecentTeams = Nothing
                                    , rivalTeam = Nothing
                                    }
                        }
                        |> command (Api.fetchRecentTeams (always FetchFailed) (MTeamSelection << FetchedRivalRecentTeams) r)

                _ ->
                    singleton model

        _ ->
            singleton model


view : Model -> Html Msg
view model =
    grid []
        [ cell [ size Tablet 6, size Desktop 12, size Phone 4 ]
            [ case model.state of
                Loading _ ->
                    Shared.loading

                NoData msg ->
                    Shared.noData msg

                TeamSelection state ->
                    div [ id "new-match" ] <|
                        teamSelectionView model state

                ExpandedSelection state ->
                    div [ id "new-match" ] <|
                        expandedSelectionView model state

                Scoring state ->
                    div [ id "new-match" ] <|
                        scoringView model state

                Submitted ->
                    Shared.loading
            ]
        ]


teamSelectionView : Model -> TeamSelectionState -> List (Html Msg)
teamSelectionView model state =
    let
        teamSelect target currentSelection mdlId comboId recentTeams =
            let
                selectTeamButton disabled =
                    Button.render Mdl
                        [ mdlId ]
                        model.mdl
                        [ Button.raised
                        , Options.cs "select-team-btn"
                        , Button.disabled |> Options.when disabled
                        , Options.onClick
                            (MTeamSelection (ExpandSelection target))
                        ]
                        [ text (t UISelect) ]
            in
                case recentTeams of
                    Nothing ->
                        selectTeamButton True

                    Just [] ->
                        selectTeamButton False

                    Just teams ->
                        let
                            isSelected id =
                                currentSelection
                                    |> Maybe.map (\team -> team.id == id)
                                    |> Maybe.withDefault False

                            teamComboOption team =
                                Html.option
                                    [ value (toString team.id), selected (isSelected team.id) ]
                                    [ text team.name ]

                            otherComboOption =
                                Html.option
                                    [ value "0", selected False ]
                                    [ text (t UIOther) ]

                            onSelect id =
                                List.filter (\t -> t.id == id) teams
                                    |> List.head
                                    |> Maybe.map (MTeamSelection << TeamChange target)
                                    |> Maybe.withDefault (MTeamSelection (ExpandSelection target))
                        in
                            select [ id comboId, Shared.onSelect onSelect ] <|
                                (List.map teamComboOption teams)
                                    ++ [ otherComboOption ]
    in
        [ div [ style [ ( "flex-grow", "1" ) ] ]
            [ label [ for "select-team1" ] [ text (t NewMatchYourTeam) ]
            , teamSelect Own state.ownTeam mdlIds.teamSelection1 "select-team1" (Just state.ownRecentTeams)
            ]
        , div [ style [ ( "flex-grow", "1" ) ] ]
            [ label [ for "select-rival" ] [ text (t NewMatchRivalTeam) ]
            , Html.select [ id "select-rival", Shared.onSelect (MTeamSelection << RivalChanged) ] <|
                List.map
                    (\user ->
                        Html.option
                            [ value (toString user.id), selected (state.rival.id == user.id) ]
                            [ text user.name ]
                    )
                    state.otherUsers
            , teamSelect Rival state.rivalTeam mdlIds.teamSelection2 "select-team2" state.rivalRecentTeams
            ]
        , div
            [ class "actions" ]
            [ let
                attributes =
                    case ( state.ownTeam, state.rivalTeam ) of
                        ( Just ot, Just rt ) ->
                            [ Options.onClick (MTeamSelection (TeamSelectionDone ot rt)) ]

                        _ ->
                            [ Button.disabled ]
              in
                mainActionButton model.mdl mdlIds.teamSelectionDone (t UINext) attributes
            ]
        ]


expandedSelectionView : Model -> ExpandedSelectionState -> List (Html Msg)
expandedSelectionView model state =
    let
        onLeagueSelect id =
            case (List.filter (\l -> l.id == id) state.context.leagues |> List.head) of
                Just l ->
                    MExpandedSelection <| LeagueChange l

                Nothing ->
                    Debug.crash "invalid option"

        leagueSelect =
            Html.select [ id "select-league", Shared.onSelect onLeagueSelect ] <|
                List.map
                    (\league ->
                        Html.option
                            [ value (toString league.id), selected (state.league.id == league.id) ]
                            [ text league.name ]
                    )
                    state.context.leagues

        onTeamSelect id =
            let
                selection =
                    state.teams
                        |> Maybe.withDefault []
                        |> List.filter (\t -> t.id == id)
                        |> List.head
            in
                case selection of
                    Just l ->
                        MExpandedSelection <| TeamChangedExpanded l

                    Nothing ->
                        Debug.crash "invalid option"

        teamSelect =
            Html.select
                [ id "select-team"
                , disabled (state.teams == Nothing)
                , Shared.onSelect onTeamSelect
                ]
            <|
                List.map
                    (\team ->
                        Html.option
                            [ value (toString team.id)
                            , selected
                                (state.selection
                                    |> Maybe.map (\t -> t.id == team.id)
                                    |> Maybe.withDefault False
                                )
                            ]
                            [ text team.name ]
                    )
                    (Maybe.withDefault [] state.teams)
    in
        [ div [ style [ ( "flex-grow", "1" ) ] ]
            [ label [ for "select-league" ] [ text (t LangLeague) ]
            , leagueSelect
            ]
        , div [ style [ ( "flex-grow", "1" ) ] ]
            [ label [ for "team" ] [ text (t LangTeam) ]
            , teamSelect
            ]
        , div
            [ class "actions" ]
            [ mainActionButton model.mdl mdlIds.expandedSelectionDone (t UIDone) [ Options.onClick (MExpandedSelection Done) ] ]
        ]


scoringView : Model -> ScoringState -> List (Html Msg)
scoringView model state =
    let
        teamDisplay target =
            let
                halfWidthColumn content =
                    cell [ size Tablet 3, size Desktop 6, size Phone 2 ]
                        [ div
                            [ class "score-column vertical-center-container" ]
                            [ div [ class "vertical-center" ] content ]
                        ]

                ( name, teamName, score, goalButtonId ) =
                    case target of
                        Own ->
                            ( "You", state.ownTeam.name, state.ownScore, mdlIds.ownTeamGoal )

                        Rival ->
                            ( state.rival.name, state.rivalTeam.name, state.rivalScore, mdlIds.rivalTeamGoal )

                goalButton =
                    Button.render Mdl
                        [ goalButtonId ]
                        model.mdl
                        [ Options.onClick (MScoring <| Goal target)
                        , Button.raised
                        , Options.cs "goal-btn"
                        ]
                        [ text (t LangGoal) ]
            in
                grid []
                    [ halfWidthColumn
                        [ Html.p [ class "name" ] [ text name ]
                        , Html.p [ class "team" ] [ text teamName ]
                        ]
                    , halfWidthColumn
                        [ Html.p [ class "score" ] [ text (toString score) ]
                        , goalButton
                        ]
                    ]

        resetButton =
            Button.render Mdl
                [ mdlIds.reportMatch ]
                model.mdl
                [ Options.onClick (MScoring Reset)
                , Button.colored
                , Button.raised
                , Options.cs "action-btn"
                ]
                [ text (t NewMatchReset) ]

        reportButton =
            Button.render Mdl
                [ mdlIds.reportMatch ]
                model.mdl
                [ Options.onClick (MScoring Report)
                , Button.colored
                , Button.raised
                , Options.cs "action-btn"
                ]
                [ text (t NewMatchReport) ]
    in
        [ div [ style [ ( "flex-grow", "1" ) ] ]
            [ teamDisplay Own ]
        , div [ style [ ( "flex-grow", "1" ) ] ]
            [ teamDisplay Rival ]
        , div
            [ class "actions" ]
            [ resetButton
            , reportButton
            ]
        ]


mainActionButton mdl mdlId label attrs =
    Button.render Mdl
        [ mdlId ]
        mdl
        (attrs ++ [ Button.colored, Button.raised, Options.cs "main-action-btn" ])
        [ text label ]


mdlIds =
    { teamSelectionDone = 1
    , teamSelection1 = 2
    , teamSelection2 = 3
    , expandedSelectionDone = 4
    , ownTeamGoal = 5
    , rivalTeamGoal = 6
    , reportMatch = 7
    }
