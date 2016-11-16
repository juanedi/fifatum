module Main exposing (..)

import Html exposing (Html)
import Html.App


type alias Flags =
    {}


type alias Msg =
    ()


type alias Model =
    ()


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
    ( (), Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update () model =
    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    Html.div [] [ Html.text "Hello Elm!" ]
