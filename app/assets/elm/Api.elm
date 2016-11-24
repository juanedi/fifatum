module Api
    exposing
        ( User
        , fetchUsers
        , Match
        , Participation
        , Ranking
        , fetchRanking
        , Stats
        , fetchStats
        , League
        , fetchLeagues
        , Team
        , fetchRecentTeams
        , fetchTeams
        )

import Date exposing (Date)
import Http
import Json.Decode as Decode exposing ((:=), list, int, float, string)
import Task


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
    { recentMatches : List Match }


fetchUsers : (Http.Error -> msg) -> (List User -> msg) -> Cmd msg
fetchUsers errorTagger okTagger =
    Http.get (list userDecoder) "/api/users"
        |> Task.perform errorTagger okTagger


fetchRanking : (Http.Error -> msg) -> (Ranking -> msg) -> Cmd msg
fetchRanking errorTagger okTagger =
    Http.get (list rankingEntryDecoder) "/api/ranking"
        |> Task.perform errorTagger okTagger


fetchStats : (Http.Error -> msg) -> (Stats -> msg) -> Cmd msg
fetchStats errorTagger okTagger =
    Http.get statsDecoder "/api/stats"
        |> Task.perform errorTagger okTagger


fetchLeagues : (Http.Error -> msg) -> (List League -> msg) -> Cmd msg
fetchLeagues errorTagger okTagger =
    Http.get (list leagueDecoder) "/api/leagues"
        |> Task.perform errorTagger okTagger


fetchRecentTeams : (Http.Error -> msg) -> (List Team -> msg) -> User -> Cmd msg
fetchRecentTeams errorTagger okTagger user =
    let
        url =
            ("/api/users/" ++ (toString user.id) ++ "/recent_teams")

        decoder =
            list teamDecoder
    in
        Http.get decoder url
            |> Task.perform errorTagger okTagger


fetchTeams : (Http.Error -> msg) -> (List Team -> msg) -> League -> Cmd msg
fetchTeams errorTagger okTagger league =
    let
        url =
            ("/api/leagues/" ++ (toString league.id) ++ "/teams")

        decoder =
            list teamDecoder
    in
        Http.get decoder url
            |> Task.perform errorTagger okTagger


userDecoder : Decode.Decoder User
userDecoder =
    Decode.object2 User
        ("id" := int)
        ("name" := string)


rankingEntryDecoder : Decode.Decoder RankingEntry
rankingEntryDecoder =
    Decode.object2 RankingEntry
        ("name" := string)
        ("lastMatch" := string)


statsDecoder : Decode.Decoder Stats
statsDecoder =
    Decode.object1 Stats
        ("recentMatches" := (list matchDecoder))


matchDecoder : Decode.Decoder Match
matchDecoder =
    Decode.object4 Match
        ("id" := int)
        ("date" := (Decode.map ((\x -> x * 1000) >> Date.fromTime) float))
        ("user1" := participationDecoder)
        ("user2" := participationDecoder)


participationDecoder : Decode.Decoder Participation
participationDecoder =
    Decode.object4 Participation
        ("id" := int)
        ("name" := string)
        ("team" := teamDecoder)
        ("goals" := int)


leagueDecoder : Decode.Decoder Team
leagueDecoder =
    Decode.object2 League
        ("id" := int)
        ("name" := string)


teamDecoder : Decode.Decoder Team
teamDecoder =
    Decode.object2 Team
        ("id" := int)
        ("name" := string)
