module Api
    exposing
        ( Ranking
        , fetchRanking
        , History
        , fetchUserHistory
        )

import Http
import Json.Decode as Decode exposing ((:=), list, int, string)
import Task


type alias Ranking =
    List RankingEntry


type alias RankingEntry =
    { name : String, lastMatch : String }


type alias History =
    List Match


type alias Match =
    { id : Int
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


fetchRanking : (Http.Error -> msg) -> (Ranking -> msg) -> Cmd msg
fetchRanking errorTagger okTagger =
    "/api/ranking"
        |> Http.get (list rankingEntryDecoder)
        |> Task.perform errorTagger okTagger


fetchUserHistory : (Http.Error -> msg) -> (History -> msg) -> Cmd msg
fetchUserHistory errorTagger okTagger =
    "/api/history/user"
        |> Http.get (list matchDecoder)
        |> Task.perform errorTagger okTagger


rankingEntryDecoder : Decode.Decoder RankingEntry
rankingEntryDecoder =
    Decode.object2 RankingEntry
        ("name" := string)
        ("lastMatch" := string)


matchDecoder : Decode.Decoder Match
matchDecoder =
    Decode.object3 Match
        ("id" := int)
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
