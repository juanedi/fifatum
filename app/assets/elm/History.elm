module History
    exposing
        ( Model
        , Msg
        , init
        , update
        , view
        )

import Api
import Html exposing (Html)
import Return
import Shared


type State
    = Loading
    | Loaded Api.Stats


type alias Model =
    { state : State }


type Msg
    = FetchOk Api.Stats
    | FetchFailed


init : ( Model, Cmd Msg )
init =
    Return.singleton { state = Loading }
        |> Return.command (Api.fetchStats (always FetchFailed) FetchOk)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    -- TODO
    Return.singleton model


view : Model -> Html a
view model =
    Shared.loading
