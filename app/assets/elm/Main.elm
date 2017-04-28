module Main exposing (..)

import Api
import Html exposing (Html, div, text)
import I18n exposing (..)
import Material
import Material.Layout as Layout
import Material.Options as Options exposing (css)
import Navigation exposing (Location)
import NewMatch
import Ranking
import Return
import Routing exposing (locationParser, Route(..))
import Shared
import Stats
import Versus


type alias Flags =
    { user : Api.User }


type Msg
    = Navigate Route
    | UrlChange Route
    | Mdl (Material.Msg Msg)
    | RankingMsg Ranking.Msg
    | StatsMsg Stats.Msg
    | VersusMsg Versus.Msg
    | NewMatchMsg NewMatch.Msg


type PageModel
    = NotFound
    | VersusModel Versus.Model
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


main : Program Flags Model Msg
main =
    Navigation.programWithFlags
        (locationParser >> UrlChange)
        { init = init
        , view = view
        , update = update
        , subscriptions = Material.subscriptions Mdl
        }


init : Flags -> Location -> ( Model, Cmd Msg )
init flags location =
    location
        |> locationParser
        |> initPage flags


initPage : Flags -> Route -> ( Model, Cmd Msg )
initPage flags route =
    let
        initModel pageModel =
            { mdl = Material.model
            , user = flags.user
            , route = route
            , pageModel = pageModel
            }

        pageInit =
            case route of
                NotFoundRoute ->
                    Return.singleton (initModel NotFound)

                VersusRoute ->
                    Versus.init flags.user
                        |> Return.mapBoth VersusMsg (VersusModel >> initModel)

                StatsRoute ->
                    Stats.init flags.user
                        |> Return.mapBoth StatsMsg (StatsModel >> initModel)

                RankingRoute ->
                    Ranking.init
                        |> Return.mapBoth RankingMsg (RankingModel >> initModel)

                NewMatchRoute ->
                    NewMatch.init flags.user
                        |> Return.mapBoth NewMatchMsg (NewMatchModel >> initModel)
    in
        pageInit
            |> Return.command (Material.init Mdl)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Navigate route ->
            model
                |> Return.singleton
                |> Return.command (Routing.navigate route)

        UrlChange route ->
            initPage { user = model.user } route

        Mdl msg ->
            Material.update Mdl msg model

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

                    ( VersusModel pModel, VersusMsg pMsg ) ->
                        case pMsg of
                            Versus.Event Versus.NewMatch ->
                                ( model, Routing.navigate NewMatchRoute )

                            _ ->
                                Versus.update pMsg pModel
                                    |> Return.map (setPageModel VersusModel)
                                    |> Return.mapCmd VersusMsg

                    ( StatsModel pModel, StatsMsg pMsg ) ->
                        Stats.update pMsg pModel
                            |> Return.map (setPageModel StatsModel)
                            |> Return.mapCmd StatsMsg

                    ( NewMatchModel pModel, NewMatchMsg pMsg ) ->
                        case pMsg of
                            NewMatch.Event NewMatch.MatchReportOk ->
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
        menuLink label route =
            Layout.link
                [ Layout.href (Routing.routeToPath route)
                , Options.onClick (Layout.toggleDrawer Mdl)
                , Options.cs "mdl-navigation__link--current" |> Options.when (model.route == route)
                ]
                [ text label ]
    in
        [ Layout.title [] [ text model.user.name ]
        , Layout.navigation []
            [ menuLink (t MenuRivals) VersusRoute
            , menuLink (t MenuMatches) StatsRoute
            , menuLink (t MenuRanking) RankingRoute
            , Html.hr [] []
            , Layout.link [ Layout.href "/logout" ] [ text (t MenuLogout) ]
            ]
        ]


header : Model -> List (Html Msg)
header model =
    case model.pageModel of
        NotFound ->
            []

        VersusModel versusModel ->
            Shared.titleHeader (t MenuRivals)

        StatsModel statsModel ->
            Shared.titleHeader (t MenuMatches)

        RankingModel rankingModel ->
            Shared.titleHeader (t MenuRanking)

        NewMatchModel newMatchModel ->
            Shared.titleHeader (t MenuFriendlyMatch)


body : Model -> List (Html Msg)
body model =
    case model.pageModel of
        NotFound ->
            [ div [] [ text "ooops" ] ]

        VersusModel versusModel ->
            [ Html.map VersusMsg (Versus.view versusModel)
            ]

        StatsModel statsModel ->
            [ Html.map StatsMsg (Stats.view statsModel)
            , newMatchButton model.mdl
            ]

        RankingModel rankingModel ->
            [ Html.map RankingMsg (Ranking.view rankingModel)
            , newMatchButton model.mdl
            ]

        NewMatchModel newMatchModel ->
            [ Html.map NewMatchMsg (NewMatch.view newMatchModel) ]


newMatchButton : Material.Model -> Html Msg
newMatchButton mdl =
    Shared.newMatchButton 0 mdl Mdl (Navigate Routing.NewMatchRoute)
