module I18n exposing (KeyText(..), t)


type alias Language =
    Translations -> String


type alias Translations =
    { english : String
    , spanish : String
    }


t : KeyText -> String
t key =
    defaultLanguage (translations key)


type KeyText
    = -- General UI messages
      UISelect
    | UINext
    | UIOther
    | UIClose
    | UIDone
      -- General domain vocabulary
    | LangLeague
    | LangTeam
    | LangGoal
    | LangRival
    | LangScore
      -- Menu Items
    | MenuRivals
    | MenuMatches
    | MenuRanking
    | MenuFriendlyMatch
    | MenuLogout
      -- New match screen
    | NewMatchYourTeam
    | NewMatchRivalTeam
    | NewMatchNoRivals
    | NewMatchNoTeams
    | NewMatchReset
    | NewMatchReport
      -- Stats screen
    | StatsNoMatches
      -- Ranking screen
    | RankingNothingHere
    | RankingYourTeam
    | RankingRivalsTeam
      -- Versus
    | VersusBalance
    | VersusMatches
    | VersusRecord
    | VersusRecordVal { won : Int, tied : Int, lost : Int }
    | VersusGoalsMade
    | VersusGoalsReceived


defaultLanguage : Language
defaultLanguage =
    .spanish


translations : KeyText -> Translations
translations key =
    case key of
        UISelect ->
            { english = "Select"
            , spanish = "Seleccionar"
            }

        UINext ->
            { english = "Next"
            , spanish = "Siguiente"
            }

        UIOther ->
            { english = "Other"
            , spanish = "Otro"
            }

        UIClose ->
            { english = "Close"
            , spanish = "Cerrar"
            }

        UIDone ->
            { english = "Done"
            , spanish = "Hecho"
            }

        LangLeague ->
            { english = "League"
            , spanish = "Liga"
            }

        LangTeam ->
            { english = "Team"
            , spanish = "Equipo"
            }

        LangGoal ->
            { english = "Goal"
            , spanish = "Gol"
            }

        LangRival ->
            { english = "Rival"
            , spanish = "Rival"
            }

        LangScore ->
            { english = "Score"
            , spanish = "Resultado"
            }

        MenuRivals ->
            { english = "Rivals"
            , spanish = "Rivales"
            }

        MenuMatches ->
            { english = "Matches"
            , spanish = "Partidos"
            }

        MenuRanking ->
            { english = "Ranking"
            , spanish = "Ranking"
            }

        MenuFriendlyMatch ->
            { english = "Friendly match"
            , spanish = "Amistoso"
            }

        MenuLogout ->
            { english = "Logout"
            , spanish = "Salir"
            }

        NewMatchYourTeam ->
            { english = "Your Team"
            , spanish = "Tu equipo"
            }

        NewMatchRivalTeam ->
            { english = "Rival"
            , spanish = "Rival"
            }

        NewMatchNoRivals ->
            { english = "There are no rivals to play against."
            , spanish = "No hay rivales para jugar."
            }

        NewMatchNoTeams ->
            { english = "There are no teams."
            , spanish = "No hay equipos."
            }

        NewMatchReset ->
            { english = "Reset"
            , spanish = "Resetear"
            }

        NewMatchReport ->
            { english = "Report"
            , spanish = "Reportar"
            }

        StatsNoMatches ->
            { english = "You haven't played any matches yet"
            , spanish = "Todavía no jugaste ningún partido"
            }

        RankingNothingHere ->
            { english = "Nothing here yet :)"
            , spanish = "Nada por aquí :)"
            }

        RankingYourTeam ->
            { english = "Your team"
            , spanish = "Tu equipo"
            }

        RankingRivalsTeam ->
            { english = "Rival's team"
            , spanish = "Equipo rival"
            }

        VersusBalance ->
            { english = "Balance"
            , spanish = "Balance"
            }

        VersusMatches ->
            { english = "Matches"
            , spanish = "Partidos"
            }

        VersusRecord ->
            { english = "Record"
            , spanish = "Record"
            }

        VersusRecordVal { won, tied, lost } ->
            { english = toString won ++ " W / " ++ toString tied ++ " T / " ++ toString lost ++ " L"
            , spanish = toString won ++ " G / " ++ toString tied ++ " E / " ++ toString lost ++ " P"
            }

        VersusGoalsMade ->
            { english = "Goals made"
            , spanish = "Goles a favor"
            }

        VersusGoalsReceived ->
            { english = "Goals received"
            , spanish = "Goles en contra"
            }
