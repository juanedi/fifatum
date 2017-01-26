module Stats
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
    | Loaded { stats : Api.Stats, openDetail : Maybe Api.Match }


type alias Model =
    { mdl : Material.Model
    , user : User
    , state : State
    }


type Msg
    = Mdl (Material.Msg Msg)
    | FetchOk Api.Stats
    | FetchFailed
    | MLoaded LoadedMsg


type LoadedMsg
    = OpenMatchDetail Api.Match
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
            Material.update Mdl msg model

        ( Loading, FetchOk stats ) ->
            Return.singleton <|
                { model | state = Loaded { stats = stats, openDetail = Nothing } }

        ( Loading, FetchFailed ) ->
            Return.singleton model

        ( Loaded state, MLoaded msg ) ->
            case msg of
                OpenMatchDetail match ->
                    Return.singleton { model | state = Loaded { state | openDetail = Just match } }

                CloseMatchDetail ->
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
                Shared.noData "You haven't played any matches yet"
            else
                recentMatchesView model.mdl model.user stats.recentMatches openDetail


recentMatchesView : Material.Model -> User -> List Api.Match -> Maybe Api.Match -> Html Msg
recentMatchesView mdl user recentMatches openDetail =
    let
        matchCell match options content =
            Shared.clickableCell (MLoaded <| OpenMatchDetail match) options content
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


matchDetailDialog : Material.Model -> User -> Api.Match -> Html Msg
matchDetailDialog mdl user match =
    let
        own =
            ownParticipation user match

        rival =
            rivalParticipation user match
    in
        Shared.modalDialog mdl
            Mdl
            mdlIds.closeModal
            (MLoaded CloseMatchDetail)
            [ ( "Rival", rival.name )
            , ( "Score", (score user match) )
            , ( "Your team", own.team.name )
            , ( "Rival's team", rival.team.name )
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
