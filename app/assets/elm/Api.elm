module Api
    exposing
        ( User
        , Match
        , Participation
        , Ranking
        , fetchRanking
        , Stats
        , fetchStats
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
    { name : String, lastMatch : String }


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


type alias Team =
    { id : Int
    , name : String
    }


type alias Stats =
    { recentMatches : List Match }


fetchRanking : (Http.Error -> msg) -> (Ranking -> msg) -> Cmd msg
fetchRanking errorTagger okTagger =
    Http.get (list rankingEntryDecoder) "/api/ranking"
        |> Task.perform errorTagger okTagger


fetchStats : (Http.Error -> msg) -> (Stats -> msg) -> Cmd msg
fetchStats errorTagger okTagger =
    Http.get statsDecoder "/api/stats"
        |> Task.perform errorTagger okTagger


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


teamDecoder : Decode.Decoder Team
teamDecoder =
    Decode.object2 Team
        ("id" := int)
        ("name" := string)
