module NewMatch
    exposing
        ( Model
        , Msg
        , init
        , view
        )

import Html exposing (Html)


type alias Model =
    {}


type alias Msg =
    ()


init : ( Model, Cmd Msg )
init =
    {} ! []


view : Model -> Html a
view model =
    Html.h4 [] [ Html.text "TO-DO :)" ]
