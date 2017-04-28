module Ranking
    exposing
        ( Model
        , Msg
        , init
        , update
        , view
        )

import Api
import Html exposing (Html, div, text)
import I18n exposing (..)
import Material
import Material.Options as Options
import Return
import Shared


type State
    = Loading
    | Loaded Api.Ranking


type alias Model =
    { mdl : Material.Model
    , state : State
    }


type Msg
    = Mdl (Material.Msg Msg)
    | FetchOk Api.Ranking
    | FetchFailed


init : ( Model, Cmd Msg )
init =
    Return.singleton
        { mdl = Material.model
        , state = Loading
        }
        |> Return.command (Api.fetchRanking (always FetchFailed) FetchOk)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Mdl msg ->
            Material.update Mdl msg model

        FetchOk ranking ->
            Return.singleton { model | state = Loaded ranking }

        FetchFailed ->
            -- TODO
            Return.singleton model


view : Model -> Html Msg
view model =
    let
        center =
            Options.css "text-align" "center"
    in
        case model.state of
            Loading ->
                Shared.loading

            Loaded ranking ->
                Shared.noData (t RankingNothingHere)
