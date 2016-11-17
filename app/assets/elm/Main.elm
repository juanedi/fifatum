module Main exposing (..)

import Html exposing (Html)
import Html.App
import Material
import Material.Button as Button
import Material.Icon as Icon
import Material.Layout as Layout
import Material.Options as Options exposing (css)
import Return


type alias Flags =
    {}


type alias Id =
    Int


type Msg
    = NoOp
    | Navigate Section
    | Mdl (Material.Msg Msg)


type Section
    = Positions
    | History


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
        , subscriptions = always Sub.none
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    Return.singleton
        { mdl = Material.model, section = History }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            Return.singleton model

        Navigate section ->
            model
                |> update (Layout.toggleDrawer Mdl)
                |> Return.map (setSection section)

        Mdl msg ->
            Material.update msg model


setSection : Section -> Model -> Model
setSection section model =
    { model | section = section }


view : Model -> Html Msg
view model =
    Layout.render Mdl
        model.mdl
        [ Layout.fixedHeader ]
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
    [ Layout.title [] [ Html.text "Juan Edi" ]
    , Layout.navigation []
        [ Layout.link [ Layout.onClick (Navigate Positions) ] [ Html.text "Positions" ]
        , Layout.link [ Layout.onClick (Navigate History) ] [ Html.text "History" ]
        , Layout.link [] [ Html.text "Logout" ]
        ]
    ]


body : Model -> List (Html Msg)
body model =
    [ newMatchButton 0 model
    , case model.section of
        History ->
            historyView

        Positions ->
            positionsView
    ]


newMatchButton : Id -> Model -> Html Msg
newMatchButton id model =
    Button.render Mdl
        [ id ]
        model.mdl
        [ Button.fab
        , Button.colored
        , Button.onClick NoOp
        , Options.cs "corner-btn"
        ]
        [ Icon.i "add" ]


historyView : Html Msg
historyView =
    Html.h1 [] [ Html.text "History" ]


positionsView : Html Msg
positionsView =
    Html.h1 [] [ Html.text "Positions" ]
