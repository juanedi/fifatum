module Main exposing (..)

import Html exposing (Html)
import Material
import Material.Button as Button
import Material.Grid exposing (grid, cell, size, Device(..))
import Material.Icon as Icon
import Material.Layout as Layout
import Material.Options as Options exposing (css)
import Navigation
import Return
import Routing exposing (parser, Route(..))
import History
import Positions
import NewMatch


type Msg
    = Navigate Route
    | Mdl (Material.Msg Msg)


type PageModel
    = NotFound
    | HistoryModel History.Model
    | PositionsModel Positions.Model
    | NewMatchModel NewMatch.Model


type alias Model =
    { mdl : Material.Model
    , route : Route
    , pageModel : PageModel
    }


type alias Id =
    Int


main : Program Never
main =
    Navigation.program parser
        { init = init
        , view = view
        , update = update
        , urlUpdate = urlUpdate
        , subscriptions = \model -> Layout.subs Mdl model.mdl
        }


init : Route -> ( Model, Cmd Msg )
init route =
    Return.singleton
        { mdl = Material.model
        , route = route
        , pageModel = initModel route
        }
        |> Return.command (Layout.sub0 Mdl)


initModel : Route -> PageModel
initModel route =
    case route of
        NotFoundRoute ->
            NotFound

        HistoryRoute ->
            HistoryModel History.init

        PositionsRoute ->
            PositionsModel Positions.init

        NewMatchRoute ->
            NewMatchModel NewMatch.init


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Navigate route ->
            model
                |> Return.singleton
                |> Return.command (Routing.navigate route)

        Mdl msg ->
            Material.update msg model


urlUpdate : Route -> Model -> ( Model, Cmd Msg )
urlUpdate route model =
    Return.singleton
        { mdl = Material.model
        , route = route
        , pageModel = initModel route
        }
        |> Return.command (Layout.sub0 Mdl)


andThenUpdate : Msg -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
andThenUpdate msg =
    -- This is easier to pipe than using infix `andThen`.
    -- Probably won't make sense after switching to 0.18
    (flip Return.andThen) (update msg)


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
        [ Layout.title [] [ Html.text "fifa-stats" ]
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
                [ Html.text label ]
    in
        [ Layout.title [] [ Html.text "Juan Edi" ]
        , Layout.navigation []
            [ menuLink "#positions" "Positions" PositionsRoute
            , menuLink "#history" "Historical" HistoryRoute
            , Layout.link [] [ Html.text "Logout" ]
            ]
        ]


body : Model -> List (Html Msg)
body model =
    [ grid []
        [ cell [ size Tablet 6, size Desktop 12, size Phone 2 ]
            (case model.pageModel of
                NotFound ->
                    [ Html.div [] [ Html.text "ooops" ] ]

                HistoryModel historyModel ->
                    [ History.view historyModel
                    , newMatchButton 0 model
                    ]

                PositionsModel positionsModel ->
                    [ Positions.view positionsModel
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
