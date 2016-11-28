module Main exposing (..)

import Api
import Html exposing (Html, div, text)
import Html.App
import Material
import Material.Button as Button
import Material.Grid exposing (grid, cell, size, Device(..))
import Material.Icon as Icon
import Material.Layout as Layout
import Material.Options as Options exposing (css)
import Navigation
import NewMatch
import Ranking
import Return
import Routing exposing (parser, Route(..))
import Shared
import Stats


type alias Flags =
    { user : Api.User }


type Msg
    = Navigate Route
    | Mdl (Material.Msg Msg)
    | RankingMsg Ranking.Msg
    | StatsMsg Stats.Msg
    | NewMatchMsg NewMatch.Msg


type PageModel
    = NotFound
    | StatsModel Stats.Model
    | RankingModel Ranking.Model
    | NewMatchModel NewMatch.Model


type alias Model =
    { mdl : Material.Model
    , user : Api.User
    , route : Route
    , pageModel : PageModel
    }


type alias Id =
    Int


main : Program Flags
main =
    Navigation.programWithFlags parser
        { init = init
        , view = view
        , update = update
        , urlUpdate = \route model -> init { user = model.user } route
        , subscriptions = \model -> Layout.subs Mdl model.mdl
        }


init : Flags -> Route -> ( Model, Cmd Msg )
init flags route =
    initPage flags route
        |> Return.command (Layout.sub0 Mdl)


initPage : Flags -> Route -> ( Model, Cmd Msg )
initPage flags route =
    let
        initModel pageModel =
            { mdl = Material.model
            , user = flags.user
            , route = route
            , pageModel = pageModel
            }
    in
        case route of
            NotFoundRoute ->
                Return.singleton (initModel NotFound)

            StatsRoute ->
                Stats.init flags.user
                    |> Return.mapBoth StatsMsg (StatsModel >> initModel)

            RankingRoute ->
                Ranking.init
                    |> Return.mapBoth RankingMsg (RankingModel >> initModel)

            NewMatchRoute ->
                NewMatch.init flags.user
                    |> Return.mapBoth NewMatchMsg (NewMatchModel >> initModel)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Navigate route ->
            model
                |> Return.singleton
                |> Return.command (Routing.navigate route)

        Mdl msg ->
            Material.update msg model

        _ ->
            let
                setPageModel tagger pModel =
                    { model | pageModel = (tagger pModel) }
            in
                case ( model.pageModel, msg ) of
                    ( RankingModel pModel, RankingMsg pMsg ) ->
                        Ranking.update pMsg pModel
                            |> Return.map (setPageModel RankingModel)
                            |> Return.mapCmd RankingMsg

                    ( StatsModel pModel, StatsMsg pMsg ) ->
                        Stats.update pMsg pModel
                            |> Return.map (setPageModel StatsModel)
                            |> Return.mapCmd StatsMsg

                    ( NewMatchModel pModel, NewMatchMsg pMsg ) ->
                        case pMsg of
                            NewMatch.Event (NewMatch.MatchReportOk) ->
                                Return.singleton model
                                    |> Return.command (Routing.navigateToRoot)

                            _ ->
                                NewMatch.update pMsg pModel
                                    |> Return.map (setPageModel NewMatchModel)
                                    |> Return.mapCmd NewMatchMsg

                    _ ->
                        Return.singleton model


setRoute : Route -> Model -> Model
setRoute route model =
    { model | route = route }


view : Model -> Html Msg
view model =
    Layout.render Mdl
        model.mdl
        [ Layout.fixedHeader
        , Layout.fixedDrawer
        ]
        { header = header model
        , drawer = drawer model
        , tabs = ( [], [] )
        , main = body model
        }


drawer : Model -> List (Html Msg)
drawer model =
    let
        menuLink href label route =
            Layout.link
                [ Layout.href href
                , Layout.onClick (Layout.toggleDrawer Mdl)
                , Options.cs "mdl-navigation__link--current"
                    `Options.when` (model.route == route)
                ]
                [ text label ]
    in
        [ Layout.title [] [ text model.user.name ]
        , Layout.navigation []
            [ menuLink "#stats" "Stats" StatsRoute
            , menuLink "#ranking" "Ranking" RankingRoute
            , Html.hr [] []
            , Layout.link [ Layout.href "/logout" ] [ text "Logout" ]
            ]
        ]


header : Model -> List (Html Msg)
header model =
    case model.pageModel of
        NotFound ->
            []

        StatsModel statsModel ->
            Stats.header statsModel
                |> List.map (Html.App.map StatsMsg)

        RankingModel rankingModel ->
            Shared.titleHeader "Ranking"

        NewMatchModel newMatchModel ->
            Shared.titleHeader "Friendly match"


body : Model -> List (Html Msg)
body model =
    [ grid []
        [ cell [ size Tablet 6, size Desktop 12, size Phone 4 ]
            (case model.pageModel of
                NotFound ->
                    [ div [] [ text "ooops" ] ]

                StatsModel statsModel ->
                    [ Html.App.map StatsMsg (Stats.view statsModel)
                    , newMatchButton 0 model
                    ]

                RankingModel rankingModel ->
                    [ Html.App.map RankingMsg (Ranking.view rankingModel)
                    , newMatchButton 0 model
                    ]

                NewMatchModel newMatchModel ->
                    [ Html.App.map NewMatchMsg (NewMatch.view newMatchModel) ]
            )
        ]
    ]


newMatchButton : Id -> Model -> Html Msg
newMatchButton id model =
    Button.render Mdl
        [ id ]
        model.mdl
        [ Button.fab
        , Button.colored
        , Button.onClick (Navigate Routing.NewMatchRoute)
        , Options.cs "corner-btn"
        ]
        [ Icon.i "add" ]
