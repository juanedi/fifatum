module NewMatch
    exposing
        ( Model
        , Msg
        , init
        , update
        , view
        )

import Api exposing (User, League, Team)
import Html
import Html exposing (Html, div, text, label, select)
import Html.Attributes exposing (for, id, style, value, selected)
import Material
import Material.Button as Button
import Material.Options as Options
import Return exposing (return, singleton, command)
import Shared


type State
    = Loading
        { ownRecentTeams : Maybe (List Team)
        , otherUsers : Maybe (List User)
        , leagues : Maybe (List League)
        }
    | NoData String
    | TeamSelection TeamSelectionState
    | FullTeamSelection FullTeamSelectionState
    | Scoring
        { rival : User
        , ownTeam : Team
        , rivalTeam : Team
        , ownScore : Int
        , rivalScore : Int
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


type alias FullTeamSelectionState =
    { target : TeamTarget
    , context : TeamSelectionState
    , league : League
    , teams : List Team
    , selection : Maybe Team
    }


type alias Model =
    { mdl : Material.Model
    , user : User
    , state : State
    }


type Msg
    = Mdl (Material.Msg Msg)
    | FetchedOwnRecentTeams (List User)
    | FetchedOtherUsers (List User)
    | FetchedRivalRecentTeams (List User)
    | FetchedLeagues (List League)
    | FetchFailed
    | RivalChanged Int
    | TeamChange TeamTarget Team
    | TeamSelectionDone Team Team
    | TeamFullSelect TeamTarget
    | FullSelect FullSelectMsg


type FullSelectMsg
    = LeagueChange League
    | FullTeamChange Team
    | FetchedTeams (List Team)
    | Done


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
        |> command (Api.fetchUsers (always FetchFailed) FetchedOtherUsers)
        |> command (Api.fetchRecentTeams (always FetchFailed) FetchedOwnRecentTeams user)
        |> command (Api.fetchLeagues (always FetchFailed) FetchedLeagues)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Mdl msg ->
            Material.update msg model

        FetchFailed ->
            -- TODO
            singleton model

        _ ->
            case model.state of
                Loading loadingState ->
                    case msg of
                        FetchedOwnRecentTeams teams ->
                            { model | state = Loading { loadingState | ownRecentTeams = Just (List.sortBy .name teams) } }
                                |> goToSetupIfReady

                        FetchedOtherUsers users ->
                            let
                                otherUsers =
                                    users
                                        |> List.filter (\u -> u.id /= model.user.id)
                                        |> List.sortBy .name
                            in
                                case otherUsers of
                                    [] ->
                                        singleton { model | state = NoData "There are no rivals to play against." }

                                    r :: rs ->
                                        { model | state = Loading { loadingState | otherUsers = Just otherUsers } }
                                            |> goToSetupIfReady

                        FetchedLeagues leagues ->
                            if List.isEmpty leagues then
                                singleton { model | state = NoData "There are no teams." }
                            else
                                { model | state = Loading { loadingState | leagues = Just (List.sortBy .name leagues) } }
                                    |> goToSetupIfReady

                        _ ->
                            singleton model

                NoData _ ->
                    singleton model

                TeamSelection state ->
                    let
                        setState s =
                            singleton { model | state = TeamSelection s }
                    in
                        case msg of
                            FetchedRivalRecentTeams teams ->
                                let
                                    sorted =
                                        List.sortBy .name teams
                                in
                                    setState
                                        { state
                                            | rivalTeam = List.head sorted
                                            , rivalRecentTeams = Just sorted
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
                                                |> command (Api.fetchRecentTeams (always FetchFailed) FetchedRivalRecentTeams rival)

                            TeamChange Own team ->
                                setState { state | ownTeam = Just team }

                            TeamChange Rival team ->
                                setState { state | rivalTeam = Just team }

                            TeamFullSelect target ->
                                initFullSelection model state target

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

                            _ ->
                                singleton model

                FullTeamSelection state ->
                    let
                        setState s =
                            singleton { model | state = FullTeamSelection s }
                    in
                        case msg of
                            FullSelect msg ->
                                case msg of
                                    LeagueChange league ->
                                        setState { state | league = league, selection = Nothing }
                                            |> command (Api.fetchTeams (always FetchFailed) (FullSelect << FetchedTeams) league)

                                    FullTeamChange team ->
                                        setState { state | selection = Just team }

                                    FetchedTeams teams ->
                                        let
                                            sorted =
                                                List.sortBy .name teams
                                        in
                                            setState { state | teams = sorted, selection = List.head sorted }

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

                            _ ->
                                Debug.crash "Invalid state"

                Scoring _ ->
                    -- TODO
                    singleton model


initFullSelection : Model -> TeamSelectionState -> TeamTarget -> ( Model, Cmd Msg )
initFullSelection model state target =
    case state.leagues of
        [] ->
            Debug.crash "Invalid state"

        l :: _ ->
            singleton
                { model
                    | state =
                        FullTeamSelection
                            { target = target
                            , context = state
                            , league = l
                            , teams = []
                            , selection = Nothing
                            }
                }
                |> command (Api.fetchTeams (always FetchFailed) (FullSelect << FetchedTeams) l)


goToSetupIfReady : Model -> ( Model, Cmd Msg )
goToSetupIfReady model =
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
                        |> command (Api.fetchRecentTeams (always FetchFailed) FetchedRivalRecentTeams r)

                _ ->
                    singleton model

        _ ->
            singleton model


view : Model -> Html Msg
view model =
    let
        column =
            div
                [ style
                    [ ( "display", "flex" )
                    , ( "flex-direction", "column" )
                    , ( "padding-top", "40px" )
                    , ( "min-height", "400px" )
                    ]
                ]
    in
        case model.state of
            Loading _ ->
                Shared.loading

            NoData msg ->
                text msg

            TeamSelection state ->
                column <|
                    teamSelectionView model state

            FullTeamSelection state ->
                column <|
                    fullTeamSelectionView model state

            Scoring state ->
                column <|
                    [ div [ style [ ( "flex-grow", "1" ) ] ]
                        [ Html.h4 [] [ text "TODO :)" ]
                        , fieldLabel "f1" "Your Team"
                        , text state.ownTeam.name
                        , Html.hr [] []
                        , fieldLabel "f2" "Rival"
                        , text state.rival.name
                        , Html.hr [] []
                        , fieldLabel "f3" "Rival's team"
                        , text state.rivalTeam.name
                        , Html.hr [] []
                        , fieldLabel "f4" "Score"
                        , text (toString state.ownScore ++ " - " ++ toString state.rivalScore)
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
                        , Options.css "width" "100%"
                        , Options.css "height" "55px"
                        , Options.css "margin-bottom" "20px"
                        , Button.disabled
                            `Options.when` disabled
                        , Button.onClick
                            (TeamFullSelect target)
                        ]
                        [ text "Select" ]
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
                                    [ text "Other" ]

                            onSelect id =
                                List.filter (\t -> t.id == id) teams
                                    |> List.head
                                    |> Maybe.map (TeamChange target)
                                    |> Maybe.withDefault (TeamFullSelect target)
                        in
                            select [ id comboId, style comboStyles, Shared.onSelect onSelect ] <|
                                (List.map teamComboOption teams)
                                    ++ [ otherComboOption ]
    in
        [ div [ style [ ( "flex-grow", "1" ) ] ]
            [ fieldLabel "select-team1" "Your Team"
            , teamSelect Own state.ownTeam mdlIds.teamSelection1 "select-team1" (Just state.ownRecentTeams)
            ]
        , div [ style [ ( "flex-grow", "1" ) ] ]
            [ fieldLabel "select-rival" "Rival"
            , Html.select [ id "select-rival", style comboStyles, Shared.onSelect RivalChanged ] <|
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
            [ style [ ( "text-align", "center" ), ( "margin-top", "40px" ) ]
            ]
            [ let
                attributes =
                    case ( state.ownTeam, state.rivalTeam ) of
                        ( Just ot, Just rt ) ->
                            [ Button.onClick (TeamSelectionDone ot rt) ]

                        _ ->
                            [ Button.disabled ]
              in
                mainActionButton model.mdl mdlIds.teamSelectionDone "Next" attributes
            ]
        ]


fullTeamSelectionView : Model -> FullTeamSelectionState -> List (Html Msg)
fullTeamSelectionView model state =
    let
        onLeagueSelect id =
            case (List.filter (\l -> l.id == id) state.context.leagues |> List.head) of
                Just l ->
                    FullSelect <| LeagueChange l

                Nothing ->
                    Debug.crash "invalid option"

        leagueSelect =
            Html.select [ id "select-league", style comboStyles, Shared.onSelect onLeagueSelect ] <|
                List.map
                    (\league ->
                        Html.option
                            [ value (toString league.id), selected (state.league.id == league.id) ]
                            [ text league.name ]
                    )
                    state.context.leagues

        onTeamSelect id =
            case (List.filter (\t -> t.id == id) state.teams |> List.head) of
                Just l ->
                    FullSelect <| FullTeamChange l

                Nothing ->
                    Debug.crash "invalid option"

        teamSelect =
            Html.select [ id "select-team", style comboStyles, Shared.onSelect onTeamSelect ] <|
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
                    state.teams
    in
        [ div [ style [ ( "flex-grow", "1" ) ] ]
            [ fieldLabel "select-league" "Leage"
            , leagueSelect
            ]
        , div [ style [ ( "flex-grow", "1" ) ] ]
            [ fieldLabel "team" "Team"
            , teamSelect
            ]
        , div
            [ style [ ( "text-align", "center" ), ( "margin-top", "40px" ) ]
            ]
            [ mainActionButton model.mdl mdlIds.teamSelectionDone "Done" [ Button.onClick (FullSelect Done) ] ]
        ]


mainActionButton mdl mdlId t attrs =
    Button.render Mdl
        [ mdlId ]
        mdl
        (attrs ++ [ Button.colored, Button.raised, Options.css "width" "70%" ])
        [ text t ]


fieldLabel : String -> String -> Html a
fieldLabel forId t =
    label
        [ for forId
        , style
            [ ( "display", "block" )
            , ( "text-transform", "uppercase" )
            , ( "font-size", "12px" )
            , ( "margin-bottom", "20px" )
            ]
        ]
        [ text t ]


comboStyles : List ( String, String )
comboStyles =
    [ ( "-webkit-appearance", "none" )
    , ( "width", "100%" )
    , ( "font-size", "18px" )
    , ( "text-align-last", "center" )
    , ( "height", "55px" )
    , ( "background-color", "#EEEEEE" )
    , ( "margin-bottom", "20px" )
    ]


mdlIds =
    { teamSelectionDone = 1
    , teamSelection1 = 2
    , teamSelection2 = 3
    }
