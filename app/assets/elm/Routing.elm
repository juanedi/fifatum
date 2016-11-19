module Routing
    exposing
        ( Route(..)
        , parser
        , navigate
        )

import Navigation
import String
import UrlParser exposing (..)


type Route
    = RankingRoute
    | HistoryRoute
    | NewMatchRoute
    | NotFoundRoute


parser : Navigation.Parser (Route)
parser =
    Navigation.makeParser locationParser


locationParser : Navigation.Location -> Route
locationParser location =
    let
        matchers =
            oneOf
                [ format RankingRoute (oneOf [ (s ""), (s "ranking") ])
                , format HistoryRoute (s "history")
                , format NewMatchRoute (s "match")
                ]
    in
        location.hash
            |> String.dropLeft 1
            |> parse identity matchers
            |> Result.withDefault NotFoundRoute


navigate : Route -> Cmd msg
navigate route =
    Navigation.newUrl <| routeToPath route


routeToPath : Route -> String
routeToPath route =
    case route of
        RankingRoute ->
            "#ranking"

        HistoryRoute ->
            "#history"

        NewMatchRoute ->
            "#match"

        NotFoundRoute ->
            "#not_found"
