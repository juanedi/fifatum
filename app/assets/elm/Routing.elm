module Routing
    exposing
        ( Route(..)
        , parser
        , navigate
        , navigateToRoot
        )

import Navigation
import String
import UrlParser exposing (..)


type Route
    = RankingRoute
    | StatsRoute
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
                [ format StatsRoute (s "")
                , format StatsRoute (s "stats")
                , format RankingRoute (s "ranking")
                , format NewMatchRoute (s "match")
                ]
    in
        location.hash
            |> String.dropLeft 1
            |> parse identity matchers
            |> Result.withDefault NotFoundRoute


navigateToRoot : Cmd msg
navigateToRoot =
    Navigation.newUrl <| "/"


navigate : Route -> Cmd msg
navigate route =
    Navigation.newUrl <| routeToPath route


routeToPath : Route -> String
routeToPath route =
    case route of
        RankingRoute ->
            "#ranking"

        StatsRoute ->
            "#stats"

        NewMatchRoute ->
            "#match"

        NotFoundRoute ->
            "#not_found"
