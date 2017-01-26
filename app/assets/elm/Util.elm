module Util exposing (..)

import Date exposing (Date)
import Return
import String
import Task


dateString : Date -> String
dateString date =
    String.join "-" <|
        List.map toString
            [ Date.year date
            , monthNumber <| Date.month date
            , Date.day date
            ]


monthNumber : Date.Month -> Int
monthNumber month =
    case month of
        Date.Jan ->
            1

        Date.Feb ->
            2

        Date.Mar ->
            3

        Date.Apr ->
            4

        Date.May ->
            5

        Date.Jun ->
            6

        Date.Jul ->
            7

        Date.Aug ->
            8

        Date.Sep ->
            9

        Date.Oct ->
            10

        Date.Nov ->
            11

        Date.Dec ->
            12


unreachable : a -> b
unreachable =
    (\_ -> Debug.crash "This failure cannot happen.")


performMessage : msg -> Cmd msg
performMessage msg =
    Task.perform identity (Task.succeed msg)


perform : msg -> ( model, Cmd msg ) -> ( model, Cmd msg )
perform msg =
    Return.command (performMessage msg)


unpackResult : (x -> r) -> (a -> r) -> Result x a -> r
unpackResult onError onSuccess result =
    case result of
        Ok x ->
            onSuccess x

        Err y ->
            onError y
