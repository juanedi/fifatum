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
import Html.Attributes exposing (class)
import Html.Events
import Material
import Material.Button as Button
import Material.Layout as Layout
import Material.Menu as Menu
import Material.Options as Options exposing (css)
import Material.Table as Table
import Return
import SelectList exposing (include, maybe)
import Shared
import String
import Util exposing (dateString)


type State
    = Loading
    | RecentMatches { stats : Api.Stats, openDetail : Maybe Api.Match }


type alias Model =
    { mdl : Material.Model
    , user : User
    , state : State
    }


type Msg
    = Mdl (Material.Msg Msg)
    | FetchOk Api.Stats
    | FetchFailed
    | OpenMatchDetail Api.Match
    | CloseMatchDetail


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
            Return.singleton
                { model | state = RecentMatches { stats = stats, openDetail = Nothing } }

        ( Loading, FetchFailed ) ->
            Return.singleton model

        ( RecentMatches state, OpenMatchDetail match ) ->
            Return.singleton { model | state = RecentMatches { state | openDetail = Just match } }

        ( RecentMatches state, CloseMatchDetail ) ->
            Return.singleton { model | state = RecentMatches { state | openDetail = Nothing } }

        _ ->
            Debug.crash "Invalid state"


header : Model -> List (Html Msg)
header model =
    let
        menu =
            Menu.render Mdl
                [ mdlIds.menu ]
                model.mdl
                [ Menu.ripple
                , Menu.bottomRight
                , css "position" "absolute"
                , css "right" "16px"
                ]
                [ Menu.item
                    [ Menu.disabled ]
                    [ text "Versus" ]
                , Menu.item
                    [ Menu.disabled ]
                    [ text "Awards" ]
                ]
    in
        [ Layout.row []
            [ Layout.title [] [ text "Stats" ]
            , Options.div
                [ css "box-sizing" "border-box"
                , css "width" "100%"
                , css "padding" "16px"
                , css "height" "64px"
                ]
                [ Options.div
                    [ css "box-sizing" "border-box"
                    , css "position" "absolute"
                    , css "right" "16px"
                    ]
                    [ menu ]
                ]
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


recentMatchesView : Material.Model -> User -> List Api.Match -> Maybe Api.Match -> Html Msg
recentMatchesView mdl user recentMatches openDetail =
    let
        matchCell match content =
            Table.td []
                [ div
                    [ Html.Events.onClick (OpenMatchDetail match) ]
                    content
                ]
    in
        div [] <|
            SelectList.select
                [ include <| Html.h4 [] [ text "Last matches" ]
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
                                , Table.th [] [ text "Result" ]
                                ]
                            ]
                        , Table.tbody []
                            (recentMatches
                                |> List.indexedMap
                                    (\index match ->
                                        Table.tr
                                            []
                                            [ matchCell match [ text (dateString match.date) ]
                                            , matchCell match [ text (rivalName user match) ]
                                            , matchCell match [ text (score user match) ]
                                            ]
                                    )
                            )
                        ]
                ]


matchDetailDialog : Material.Model -> User -> Api.Match -> Html Msg
matchDetailDialog mdl user match =
    let
        own =
            ownParticipation user match

        rival =
            rivalParticipation user match

        modalCloseButton =
            Button.render Mdl
                [ mdlIds.closeModal ]
                mdl
                [ Button.onClick CloseMatchDetail ]
                [ text "Close" ]

        field name value =
            div [ class "matchDetailField" ]
                [ span [ class "fieldName" ] [ text name ]
                , span [ class "fieldValue" ] [ text value ]
                ]
    in
        div [ class "matchDetailDialogContainer" ]
            [ div [ class "matchDetailDialog" ]
                [ div [ class "content" ]
                    [ field "Rival" rival.name
                    , field "Score" (score user match)
                    , field "Your team" own.team.name
                    , field "Rival's team" rival.team.name
                    ]
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
