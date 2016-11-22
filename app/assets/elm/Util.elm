module Util exposing (..)

import Date exposing (Date)
import String


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
