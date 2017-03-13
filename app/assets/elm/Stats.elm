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
import Html.Attributes exposing (id, class, style)
import Html.Events as Events
import Material
import Material.Options as Options exposing (cs, css)
import Return
import SelectList exposing (include, maybe)
import Shared
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
    = OpenDetail Api.Match
    | Close


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
                OpenDetail match ->
                    Return.singleton { model | state = Loaded { state | openDetail = Just match } }

                Close ->
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
    div [ id "stats" ] <|
        SelectList.select
            [ maybe <|
                Maybe.map
                    (matchDetailDialog mdl user)
                    openDetail
            , include <|
                matchesListing user recentMatches
            ]


matchesListing : User -> List Api.Match -> Html Msg
matchesListing user matches =
    let
        matchRow match =
            Html.li
                [ Events.onClick (MLoaded <| OpenDetail match) ]
                [ span [ class "item-main" ]
                    [ div [] [ text (rivalName user match) ]
                    , span [ class "item-sub" ] [ text (dateString match.date) ]
                    ]
                , span [ class "icon", style [ ( "min-width", "47px" ) ] ] [ text (score user match) ]
                ]
    in
        Html.ul [ class "listing" ] <|
            List.map matchRow matches


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
            (MLoaded Close)
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
