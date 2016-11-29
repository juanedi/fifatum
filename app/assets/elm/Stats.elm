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
import Html exposing (Html, div, text)
import Material
import Material.Layout as Layout
import Material.Menu as Menu
import Material.Options as Options exposing (css)
import Material.Table as Table
import Return
import Shared
import String
import Util exposing (dateString)


type State
    = Loading
    | Loaded Api.Stats


type alias Model =
    { mdl : Material.Model
    , user : User
    , state : State
    }


type Msg
    = Mdl (Material.Msg Msg)
    | FetchOk Api.Stats
    | FetchFailed


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
    case msg of
        Mdl msg ->
            Material.update msg model

        FetchOk stats ->
            Return.singleton
                { model | state = Loaded stats }

        FetchFailed ->
            -- TODO
            Return.singleton model


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

            Loaded stats ->
                recentMatchesView model.user stats.recentMatches


recentMatchesView : User -> List Api.Match -> Html Msg
recentMatchesView user recentMatches =
    div
        []
        [ Html.h4 [] [ text "Last matches" ]
        , Table.table [ Options.id "stats-table" ]
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
                            Table.tr []
                                [ Table.td [] [ text (dateString match.date) ]
                                , Table.td [] [ text (rivalName user match) ]
                                , Table.td [] [ text (score user match) ]
                                ]
                        )
                )
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
    }
