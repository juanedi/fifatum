module Routing
    exposing
        ( Route(..)
        , locationParser
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


locationParser : Navigation.Location -> Route
locationParser location =
    let
        matchers =
            oneOf
                [ map StatsRoute (s "stats")
                , map RankingRoute (s "ranking")
                , map NewMatchRoute (s "match")
                ]
    in
        if location.hash == "" then
            StatsRoute
        else
            location
                |> parseHash matchers
                |> Maybe.withDefault NotFoundRoute


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
