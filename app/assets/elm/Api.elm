module Api exposing (Ranking, fetchRanking)

import Http
import Json.Decode as Decode exposing ((:=))
import Task


type alias RankingEntry =
    { name : String, lastMatch : String }


type alias Ranking =
    List RankingEntry


fetchRanking : (Http.Error -> msg) -> (Ranking -> msg) -> Cmd msg
fetchRanking errorTagger okTagger =
    let
        decoder =
            Decode.list <|
                Decode.object2 RankingEntry
                    ("name" := Decode.string)
                    ("lastMatch" := Decode.string)
    in
        Task.perform errorTagger okTagger (Http.get decoder "/api/ranking")
