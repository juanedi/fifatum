module Main exposing (..)

import History
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


type alias Flags =
    { username : String }


type Msg
    = Navigate Route
    | Mdl (Material.Msg Msg)
    | RankingMsg Ranking.Msg
    | HistoryMsg History.Msg
    | NewMatchMsg NewMatch.Msg


type PageModel
    = NotFound
    | HistoryModel History.Model
    | RankingModel Ranking.Model
    | NewMatchModel NewMatch.Model


type alias Model =
    { mdl : Material.Model
    , username : String
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
        , urlUpdate = \route model -> init { username = model.username } route
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
            , username = flags.username
            , route = route
            , pageModel = pageModel
            }

        lift modelTag cmdTag init =
            init
                |> Return.map (modelTag >> initModel)
                |> Return.mapCmd cmdTag
    in
        case route of
            NotFoundRoute ->
                NotFound
                    |> initModel
                    |> Return.singleton

            HistoryRoute ->
                History.init
                    |> lift HistoryModel HistoryMsg

            RankingRoute ->
                Ranking.init
                    |> lift RankingModel RankingMsg

            NewMatchRoute ->
                NewMatch.init
                    |> lift NewMatchModel NewMatchMsg


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

                    ( HistoryModel pModel, HistoryMsg pMsg ) ->
                        Return.singleton model

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


header : Model -> List (Html Msg)
header model =
    [ Layout.row []
        [ Layout.title [] [ text "fifa-stats" ]
        ]
    ]


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
        [ Layout.title [] [ text model.username ]
        , Layout.navigation []
            [ menuLink "#ranking" "Ranking" RankingRoute
            , menuLink "#history" "Historical" HistoryRoute
            , Layout.link [ Layout.href "/logout" ] [ text "Logout" ]
            ]
        ]


body : Model -> List (Html Msg)
body model =
    [ grid []
        [ cell [ size Tablet 6, size Desktop 12, size Phone 4 ]
            (case model.pageModel of
                NotFound ->
                    [ div [] [ text "ooops" ] ]

                HistoryModel historyModel ->
                    [ History.view historyModel
                    , newMatchButton 0 model
                    ]

                RankingModel rankingModel ->
                    [ Html.App.map RankingMsg (Ranking.view rankingModel)
                    , newMatchButton 0 model
                    ]

                NewMatchModel newMatchModel ->
                    [ NewMatch.view newMatchModel ]
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
