module History exposing (Model, init, view)

import Html exposing (Html)


type alias Model =
    {}


init : Model
init =
    {}


view : Model -> Html a
view model =
    Html.h3 [] [ Html.text "Historical" ]
