module Main exposing (..)

import Html exposing (Html)
import Html.App
import Material
import Material.Button as Button
import Material.Grid exposing (grid, cell, size, Device(..))
import Material.Icon as Icon
import Material.Layout as Layout
import Material.Options as Options exposing (css)
import Return


type alias Flags =
    {}


type alias Id =
    Int


type Msg
    = MenuLinkClick Section
    | Navigate Section
    | Mdl (Material.Msg Msg)


type Section
    = Positions
    | History
    | NewMatch


type alias Model =
    { mdl : Material.Model
    , section : Section
    }


main : Program Flags
main =
    Html.App.programWithFlags
        { init = init
        , view = view
        , update = update
        , subscriptions = \model -> Layout.subs Mdl model.mdl
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    Return.singleton
        { mdl = Material.model
        , section = Positions
        }
        |> Return.command (Layout.sub0 Mdl)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MenuLinkClick section ->
            Return.singleton model
                |> andThenUpdate (Layout.toggleDrawer Mdl)
                |> andThenUpdate (Navigate section)

        Navigate section ->
            model
                |> setSection section
                |> Return.singleton

        Mdl msg ->
            Material.update msg model


andThenUpdate : Msg -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
andThenUpdate msg =
    -- This is easier to pipe than using infix `andThen`.
    -- Probably won't make sense after switching to 0.18
    (flip Return.andThen) (update msg)


setSection : Section -> Model -> Model
setSection section model =
    { model | section = section }


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
        menuLink href label section =
            Layout.link
                [ Layout.href href
                , Layout.onClick (MenuLinkClick section)
                , Options.cs "mdl-navigation__link--current"
                    `Options.when` (model.section == section)
                ]
                [ Html.text label ]
    in
        [ Layout.title [] [ Html.text "Juan Edi" ]
        , Layout.navigation []
            [ menuLink "#positions" "Positions" Positions
            , menuLink "#history" "Historical" History
            , Layout.link [] [ Html.text "Logout" ]
            ]
        ]


body : Model -> List (Html Msg)
body model =
    [ grid []
        [ cell [ size Tablet 6, size Desktop 12, size Phone 2 ]
            (case model.section of
                History ->
                    historyView model

                Positions ->
                    positionsView model

                NewMatch ->
                    newMatchView model
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
        , Button.onClick (Navigate NewMatch)
        , Options.cs "corner-btn"
        ]
        [ Icon.i "add" ]


historyView : Model -> List (Html Msg)
historyView model =
    [ Html.h3 [] [ Html.text "Historical" ]
    , newMatchButton 0 model
    ]


positionsView : Model -> List (Html Msg)
positionsView model =
    [ Html.h3 [] [ Html.text "Positions" ]
    , newMatchButton 0 model
    ]


newMatchView : Model -> List (Html Msg)
newMatchView model =
    [ Html.h3 [] [ Html.text "New match" ] ]
