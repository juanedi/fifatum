module Api
    exposing
        ( User
        , fetchUsers
        , Match
        , Participation
        , Ranking
        , fetchRanking
        , Stats
        , RivalStat
        , fetchStats
        , League
        , fetchLeagues
        , Team
        , fetchRecentTeams
        , fetchTeams
        , reportMatch
        )

import Date exposing (Date)
import Http
import Json.Decode as Decode exposing (field, list, dict, int, float, string)
import Json.Encode as Encode
import Task
import Util exposing (unpackResult)


type alias User =
    { id : Int
    , name : String
    }


type alias Ranking =
    List RankingEntry


type alias RankingEntry =
    { name : String
    , lastMatch : String
    }


type alias Match =
    { id : Int
    , date : Date
    , user1 : Participation
    , user2 : Participation
    }


type alias MatchReport =
    ( ParticipationReport, ParticipationReport )


type alias ParticipationReport =
    { user : User, team : Team, goals : Int }


type alias Participation =
    { id : Int
    , name : String
    , team : Team
    , goals : Int
    }


type alias League =
    { id : Int
    , name : String
    }


type alias Team =
    { id : Int
    , name : String
    }


type alias Stats =
    { recentMatches : List Match
    , versus : List RivalStat
    }


type alias RivalStat =
    { rivalName : String
    , won : Int
    , tied : Int
    , lost : Int
    , goalsMade : Int
    , goalsReceived : Int
    }


fetchUsers : (Http.Error -> msg) -> (List User -> msg) -> Cmd msg
fetchUsers errorTagger okTagger =
    Http.get "/api/users" (list userDecoder)
        |> send errorTagger okTagger


fetchRanking : (Http.Error -> msg) -> (Ranking -> msg) -> Cmd msg
fetchRanking errorTagger okTagger =
    Http.get "/api/ranking" (list rankingEntryDecoder)
        |> send errorTagger okTagger


fetchStats : (Http.Error -> msg) -> (Stats -> msg) -> Cmd msg
fetchStats errorTagger okTagger =
    Http.get "/api/stats" statsDecoder
        |> send errorTagger okTagger


fetchLeagues : (Http.Error -> msg) -> (List League -> msg) -> Cmd msg
fetchLeagues errorTagger okTagger =
    Http.get "/api/leagues" (list leagueDecoder)
        |> send errorTagger okTagger


fetchRecentTeams : (Http.Error -> msg) -> (List Team -> msg) -> User -> Cmd msg
fetchRecentTeams errorTagger okTagger user =
    let
        url =
            ("/api/users/" ++ (toString user.id) ++ "/recent_teams")
    in
        Http.get url (list teamDecoder)
            |> send errorTagger okTagger


fetchTeams : (Http.Error -> msg) -> (List Team -> msg) -> League -> Cmd msg
fetchTeams errorTagger okTagger league =
    let
        url =
            ("/api/leagues/" ++ (toString league.id) ++ "/teams")
    in
        Http.get url (list teamDecoder)
            |> send errorTagger okTagger


reportMatch : (Http.Error -> msg) -> msg -> MatchReport -> Cmd msg
reportMatch errorTagger okMsg matchReport =
    let
        request =
            Http.request
                { method = "POST"
                , url = "/api/matches"
                , headers = [ Http.header "Content-Type" "application/json" ]
                , body = Http.jsonBody (encodeReport matchReport)
                , expect = Http.expectString
                , timeout = Nothing
                , withCredentials = False
                }
    in
        request
            |> send errorTagger (always okMsg)


send : (Http.Error -> msg) -> (a -> msg) -> Http.Request a -> Cmd msg
send errorTagger okTagger request =
    Http.send (unpackResult errorTagger okTagger) request


encodeReport : MatchReport -> Encode.Value
encodeReport ( p1, p2 ) =
    Encode.object
        [ ( "own_goals", Encode.int p1.goals )
        , ( "own_team_id", Encode.int p1.team.id )
        , ( "rival_id", Encode.int p2.user.id )
        , ( "rival_goals", Encode.int p2.goals )
        , ( "rival_team_id", Encode.int p2.team.id )
        ]


userDecoder : Decode.Decoder User
userDecoder =
    Decode.map2 User
        (field "id" int)
        (field "name" string)


rankingEntryDecoder : Decode.Decoder RankingEntry
rankingEntryDecoder =
    Decode.map2 RankingEntry
        (field "name" string)
        (field "lastMatch" string)


statsDecoder : Decode.Decoder Stats
statsDecoder =
    Decode.map2 Stats
        (field "recentMatches" (list matchDecoder))
        (field "versus" <|
            list <|
                Decode.map6 RivalStat
                    (field "rivalName" string)
                    (field "won" int)
                    (field "tied" int)
                    (field "lost" int)
                    (field "goalsMade" int)
                    (field "goalsReceived" int)
        )


matchDecoder : Decode.Decoder Match
matchDecoder =
    Decode.map4 Match
        (field "id" int)
        (field "date" (Decode.map ((\x -> x * 1000) >> Date.fromTime) float))
        (field "user1" participationDecoder)
        (field "user2" participationDecoder)


participationDecoder : Decode.Decoder Participation
participationDecoder =
    Decode.map4 Participation
        (field "id" int)
        (field "name" string)
        (field "team" teamDecoder)
        (field "goals" int)


leagueDecoder : Decode.Decoder Team
leagueDecoder =
    Decode.map2 League
        (field "id" int)
        (field "name" string)


teamDecoder : Decode.Decoder Team
teamDecoder =
    Decode.map2 Team
        (field "id" int)
        (field "name" string)
