module PokemonViewer exposing (..)

{-
   Culminating demo for my blog post, "Elm Applicatives & Json
   Decoders: Mapping & Applying Our Way to Deserialization Victory",
   explaining how Elm's `Json.Decode.Decoder` is an applicative
   functor. This example renders Pokémon (its ID, name, picture, and
   stats) from a public API. This is an entire Elm application--with
   model, update, and view.

   https://toast.al/posts/2016-08-12-elm-applicatives-and-json-decoders.html

   Running example: https://codepen.io/toastal/pen/kXAKPk
-}

import Dict exposing (Dict)
import Html exposing (Html, abbr, button, div, a, dd, dl, dt, footer, h1, img, li, node, text)
import Html.Attributes as Attr exposing (alt, class, href, rel, src, style, target, title, type_)
import Html.Events exposing (onClick)
import Html.Keyed
import Http exposing (Request)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode exposing ((|:))
import List.Extra as List
import Regex
import Result.Extra as Result
import String
import String.Extra as String
import Task exposing (Task)


-- MAIN


initOffset : Int
initOffset =
    24


main : Program Never Model Msg
main =
    Html.program
        { init =
            ( Model initOffset [], getPokemonsBetween 1 initOffset )
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }



-- TYPES


{-| Though the API provides much, much more data, these are the only
fields we're going to look at for the demo.
-}
type alias Pokemon =
    { id : Int
    , name : String
    , sprite : String
    , stats : Dict String Int
    , types : List String
    }


{-| Using an Applicative-style Json.Decoder provided by
`Json.Decoder.Extra` as it scales infinitely, regardless of the size
of the record trying that is trying to be decoded... We may not need
a number outside `map8` but that is the point of this demo -- to
demonstate Applicatives + Json Decoding.

Relevant sample JSON:

    {
      "stats":[
        {
          "stat":{
            "url":"https:\/\/pokeapi.co\/api\/v2\/stat\/6\/",
            "name":"speed"
          },
          "effort":0,
          "base_stat":45
        },
        {
          "stat":{
            "url":"https:\/\/pokeapi.co\/api\/v2\/stat\/5\/",
            "name":"special-defense"
          },
          "effort":0,
          "base_stat":65
        },
        {
          "stat":{
            "url":"https:\/\/pokeapi.co\/api\/v2\/stat\/4\/",
            "name":"special-attack"
          },
          "effort":1,
          "base_stat":65
        },
        {
          "stat":{
            "url":"https:\/\/pokeapi.co\/api\/v2\/stat\/3\/",
            "name":"defense"
          },
          "effort":0,
          "base_stat":49
        },
        {
          "stat":{
            "url":"https:\/\/pokeapi.co\/api\/v2\/stat\/2\/",
            "name":"attack"
          },
          "effort":0,
          "base_stat":49
        },
        {
          "stat":{
            "url":"https:\/\/pokeapi.co\/api\/v2\/stat\/1\/",
            "name":"hp"
          },
          "effort":0,
          "base_stat":45
        }
      ],
      "name":"bulbasaur",
      "sprites":{
        "back_female":null,
        "back_shiny_female":null,
        "back_default":"http:\/\/pokeapi.co\/media\/sprites\/pokemon\/back\/1.png",
        "front_female":null,
        "front_shiny_female":null,
        "back_shiny":"http:\/\/pokeapi.co\/media\/sprites\/pokemon\/back\/shiny\/1.png",
        "front_default":"http:\/\/pokeapi.co\/media\/sprites\/pokemon\/1.png",
        "front_shiny":"http:\/\/pokeapi.co\/media\/sprites\/pokemon\/shiny\/1.png"
      },
      "id":1,
      "types":[
        {
          "slot":2,
          "type":{
            "url":"https:\/\/pokeapi.co\/api\/v2\/type\/4\/",
            "name":"poison"
          }
        },
        {
          "slot":1,
          "type":{
            "url":"https:\/\/pokeapi.co\/api\/v2\/type\/12\/",
            "name":"grass"
          }
        }
      ]
    }
-}
pokemonDecoder : Decoder Pokemon
pokemonDecoder =
    -- using Pokemon as a constructor to apply our 5 fields to
    Decode.succeed Pokemon
        |: Decode.field "id" Decode.int
        |: Decode.field "name" Decode.string
        |: (Decode.at [ "sprites", "front_default" ] Decode.string
                -- Mapping to remove the protocol
                |>
                    Decode.map
                        (Regex.replace (Regex.AtMost 1)
                            (Regex.regex "^http(s)?:")
                            (always "")
                        )
           )
        |: Decode.field "stats"
            (Decode.list
                -- Applying into a tuple constructor
                (Decode.succeed (,)
                    |: Decode.at [ "stat", "name" ] Decode.string
                    |: Decode.field "base_stat" Decode.int
                )
                -- Mapping our tuple list into a Dict
                |>
                    Decode.map Dict.fromList
            )
        |: Decode.field "types"
            (Decode.list <| Decode.at [ "type", "name" ] Decode.string)



-- MODEL


type alias Model =
    { offset : Int
    , pokemon : List Pokemon
    }



-- UPDATE


type Msg
    = FetchMore Int
    | FetchPokemon (Result Http.Error Pokemon)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchMore m ->
            ( { model | offset = model.offset + m }
            , getPokemonsBetween (model.offset + 1) (model.offset + m)
            )

        -- Swallowing error, because this is just a demo
        FetchPokemon rpkmn ->
            Result.unpack (always ( model, Cmd.none ))
                (\pkmn ->
                    ( { model
                        | pokemon = List.sortBy .id <| model.pokemon ++ [ pkmn ]
                      }
                    , Cmd.none
                    )
                )
                rpkmn



-- REQUESTS


{-| Given an id, build a Request for the JSON GET
-}
getPokemon : Int -> Request Pokemon
getPokemon id =
    Http.get ("https://pokeapi.co/api/v2/pokemon/" ++ toString id ++ "/")
        pokemonDecoder


{-| Builds a list from the first Pokémon, Bulbasaur, to the specified
limit.  The list is reversed because the Requests get queued in the
opposite order and in Elm, we can't do List.range with descending :\
-}
getPokemonsBetween : Int -> Int -> Cmd Msg
getPokemonsBetween offset limit =
    List.range offset limit
        |> List.reverse
        |> List.map (getPokemon >> Http.send FetchPokemon)
        |> Cmd.batch



-- VIEW


{-| Matches stat key with the max from Bulbapedia
-}
statsWithMax : List ( String, Float )
statsWithMax =
    [ ( "hp", 255 )
    , ( "attack", 190 )
    , ( "defense", 230 )
    , ( "special-attack", 194 )
    , ( "special-defense", 230 )
    , ( "speed", 180 )
    ]


{-| Could be more efficient by memoizing label since we know that the
same strings will be passing through, but that would add complexity
to this simple example
-}
viewStatBar : ( String, Float, Int ) -> Html Msg
viewStatBar ( key, max, val ) =
    let
        label : String
        label =
            String.split "-" key
                |> List.map String.toTitleCase
                |> String.join " "
                |> Regex.replace (Regex.AtMost 1)
                    (Regex.regex "^Special")
                    (always "Sp.")

        perc : Float
        perc =
            toFloat val / max

        bgColor : String
        bgColor =
            "hsl(190, 80%, " ++ toString ((70 * perc) + 30) ++ "%)"
    in
        div
            [ title <| label ++ ": " ++ toString val
            , class "pokemon-stat-bar"
            , style
                [ ( "max-width", toString ((95 * perc) + 5) ++ "%" )
                , ( "backgroundColor", bgColor )
                ]
            ]
            [ text label ]


{-| A grid item for the Pokémon
-}
viewPokemon : Pokemon -> ( String, Html Msg )
viewPokemon { id, name, sprite, stats, types } =
    let
        id_ : String
        id_ =
            toString id

        name_ : String
        name_ =
            String.toTitleCase name

        getStat : String -> Int
        getStat =
            flip Dict.get stats >> Maybe.withDefault 0

        makeBarData : ( String, Float ) -> ( String, Float, Int )
        makeBarData ( key, max ) =
            ( key, max, getStat key )
    in
        ( id_
        , li [ class "pokemon-list-item" ]
            [ dl []
                [ dt []
                    [ abbr
                        [ title "National Pokédex identification number"
                        ]
                        [ text "ID" ]
                    ]
                , dd [] [ text <| String.padLeft 3 '0' id_ ]
                , dt [] [ text "Name" ]
                , dd [] [ text name_ ]
                , dt [ style [ ( "display", "none" ) ] ]
                    [ text "Sprite" ]
                , dd []
                    [ img
                        [ src sprite
                        , alt ("Sprite of " ++ name_)
                        , title name_
                        ]
                        []
                    ]
                , dt []
                    [ text <|
                        if List.length types < 2 then
                            "Type"
                        else
                            "Types"
                    ]
                , dd []
                    [ text
                        << String.join ", "
                      <|
                        List.map String.toTitleCase types
                    ]
                , dt [] [ text "Stats" ]
                , dd [] <|
                    List.map (makeBarData >> viewStatBar) statsWithMax
                ]
            ]
        )


{-| We're going to start with a container <div> that will give us a
place to add a <link> for the Google Font, as well as a <style>
element with, as well as the Keyed <ol> for the list of Pokémon. A
case statement is going to check for the empty list and render a
loading indicator for until at least one element is in the list. The
API itself is a little slow so this works well enough.
-}
view : Model -> Html Msg
view { pokemon } =
    div [ class "container" ]
        [ node "link"
            [ href "https://fonts.googleapis.com/css?family=Teko:400,600"
            , rel "stylesheet"
            ]
            []
        , h1
            [ style
                [ ( "textAlign", "center" ), ( "marginTop", "0" ) ]
            ]
            [ text "Applicative-Style Elm JSON Decoding - "
            , a
                [ href "https://github.com/toastal/elm-applicatives-and-json-decoders/blob/master/demo/PokemonViewer.elm"
                , target "_blank"
                ]
                [ text "Source Code" ]
            ]
        , node "style"
            [ type_ "text/css" ]
            [ text stylez ]
        , if List.isEmpty pokemon then
            div [ class "loader" ] []
          else
            div []
                [ Html.Keyed.ol [ class "pokemon-list" ] <|
                    List.map viewPokemon pokemon
                , footer [ class "more-footer" ]
                    [ button
                        [ type_ "button", onClick <| FetchMore 12 ]
                        [ text "Fetch 12 More Pokémon" ]
                    ]
                ]
        ]



-- STYLES


{-| In leiu of a real stylesheet, a string is good enough for a demo.
-}
stylez : String
stylez =
    """
    html { box-sizing: border-box; background-color: #111; color: #fff; font-family: "Teko", sans-serif; text-rendering: optimizeLegibility; -webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale }
    *, *::before, *::after { box-sizing: inherit }
    a { color: hsl(190, 80%, 60%); transition: color 300ms ease-out }
    a:hover, a:focus { color: hsl(190, 90%, 74%) }
    dl dt, dl dd { display: inline }
    dl dt { vertical-align: top; font-weight: 600; color: hsl(190, 80%, 60%) }
    dl dt::after { content: ": "; vertical-align: top }
    dl dd { margin: 0; white-space: pre-wrap }
    dl dd::after { content: "\\A" }
    button { -webkit-appearance: none; -moz-appearance: none; appearance: none; border: 2px solid hsl(190, 80%, 60%); background: transparent; color: hsl(190, 80%, 60%); font-family: inherit; font-size: 16px; cursor: pointer; transition-property: border-color, background-color, color; transition-duration: 300ms; transition-timing-function: ease-out }
    button:hover, button:focus { background-color: hsl(190, 80%, 60%); color: #111 }
    button:focus, button:-moz-focusring { outline: none }
    button:active { background-color: #fff; border-color: #fff }
    .container { display: flex; flex-flow: column nowrap; justify-content: center; padding: 1.2em }
    .pokemon-list { will-change: contents; display: flex; flex-flow: row wrap; list-style: none; margin: 1px 0 0 1px; padding: 0; font-size: 1.3em }
    .pokemon-list-item { display: flex; justify-content: center; align-content: center; position: relative; will-change: opacity; min-width: 13em; min-height: 13em; padding: 1.5em; margin-left: -1px; margin-top: -1px; border: 1px solid hsl(190, 80%, 28%); transition: border-color 300ms ease-out; animation: fadein 450ms ease-out 0s normal 1 both }
    .pokemon-list-item:hover { z-index: 1; border-color: hsl(190, 80%, 48%) }
    .pokemon-stat-bar { will-change: opacity, width; overflow: hidden; height: 1.1em; min-width: 5%; padding: 0 0.25em; background-color: hsl(190, 80%, 30%); font-size: 0.7em; line-height: 1.3; color: hsla(0, 0%, 0%, 0.34); text-transform: uppercase; white-space: nowrap; cursor: help; -webkit-user-select: none; -moz-user-select: none; -ms-user-select: none; user-select: none; animation: barin 350ms ease-in 275ms normal 1 both }
    .pokemon-stat-bar:nth-child(2) { animation-delay: 300ms }
    .pokemon-stat-bar:nth-child(3) { animation-delay: 325ms }
    .pokemon-stat-bar:nth-child(4) { animation-delay: 350ms }
    .pokemon-stat-bar:nth-child(5) { animation-delay: 375ms }
    .pokemon-stat-bar:nth-child(6) { animation-delay: 400ms }
    @keyframes fadein { 0% { opacity: 0 } 100% { opacity: 1 } }
    @keyframes barin { 0% { opacity: 0; width: 5% } 30% { opacity: 1 } 100% { width: 100% } }
    .more-footer { padding: 0.5em 1em; text-align: center }
    .loader { position: absolute; z-index: 10; top: 0; bottom: 0; left: 0; right: 0; margin: auto; height: 16vmin; width: 16vmin; min-height: 12px; min-width: 12px; max-width: 110px; max-height: 110px; background-repeat: no-repeat; background-position: 50% 50%; background-size: contain; background-image: url('data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz48c3ZnIHdpZHRoPSIxMjBweCIgaGVpZ2h0PSIxMjBweCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB2aWV3Qm94PSIwIDAgMTAwIDEwMCIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pZFlNaWQiIGNsYXNzPSJ1aWwtc3F1YXJlcyI+PHJlY3QgeD0iMCIgeT0iMCIgd2lkdGg9IjEwMCIgaGVpZ2h0PSIxMDAiIGZpbGw9Im5vbmUiIGNsYXNzPSJiayI+PC9yZWN0PjxyZWN0IHg9IjE1IiB5PSIxNSIgd2lkdGg9IjIwIiBoZWlnaHQ9IjIwIiBmaWxsPSIjMGY3NTg5IiBjbGFzcz0ic3EiPjxhbmltYXRlIGF0dHJpYnV0ZU5hbWU9ImZpbGwiIGZyb209IiMwZjc1ODkiIHRvPSIjNDdjZmVhIiByZXBlYXRDb3VudD0iaW5kZWZpbml0ZSIgZHVyPSIxcyIgYmVnaW49IjAuMHMiIHZhbHVlcz0iIzQ3Y2ZlYTsjNDdjZmVhOyMwZjc1ODk7IzBmNzU4OSIga2V5VGltZXM9IjA7MC4xOzAuMjsxIj48L2FuaW1hdGU+PC9yZWN0PjxyZWN0IHg9IjQwIiB5PSIxNSIgd2lkdGg9IjIwIiBoZWlnaHQ9IjIwIiBmaWxsPSIjMGY3NTg5IiBjbGFzcz0ic3EiPjxhbmltYXRlIGF0dHJpYnV0ZU5hbWU9ImZpbGwiIGZyb209IiMwZjc1ODkiIHRvPSIjNDdjZmVhIiByZXBlYXRDb3VudD0iaW5kZWZpbml0ZSIgZHVyPSIxcyIgYmVnaW49IjAuMTI1cyIgdmFsdWVzPSIjNDdjZmVhOyM0N2NmZWE7IzBmNzU4OTsjMGY3NTg5IiBrZXlUaW1lcz0iMDswLjE7MC4yOzEiPjwvYW5pbWF0ZT48L3JlY3Q+PHJlY3QgeD0iNjUiIHk9IjE1IiB3aWR0aD0iMjAiIGhlaWdodD0iMjAiIGZpbGw9IiMwZjc1ODkiIGNsYXNzPSJzcSI+PGFuaW1hdGUgYXR0cmlidXRlTmFtZT0iZmlsbCIgZnJvbT0iIzBmNzU4OSIgdG89IiM0N2NmZWEiIHJlcGVhdENvdW50PSJpbmRlZmluaXRlIiBkdXI9IjFzIiBiZWdpbj0iMC4yNXMiIHZhbHVlcz0iIzQ3Y2ZlYTsjNDdjZmVhOyMwZjc1ODk7IzBmNzU4OSIga2V5VGltZXM9IjA7MC4xOzAuMjsxIj48L2FuaW1hdGU+PC9yZWN0PjxyZWN0IHg9IjE1IiB5PSI0MCIgd2lkdGg9IjIwIiBoZWlnaHQ9IjIwIiBmaWxsPSIjMGY3NTg5IiBjbGFzcz0ic3EiPjxhbmltYXRlIGF0dHJpYnV0ZU5hbWU9ImZpbGwiIGZyb209IiMwZjc1ODkiIHRvPSIjNDdjZmVhIiByZXBlYXRDb3VudD0iaW5kZWZpbml0ZSIgZHVyPSIxcyIgYmVnaW49IjAuODc1cyIgdmFsdWVzPSIjNDdjZmVhOyM0N2NmZWE7IzBmNzU4OTsjMGY3NTg5IiBrZXlUaW1lcz0iMDswLjE7MC4yOzEiPjwvYW5pbWF0ZT48L3JlY3Q+PHJlY3QgeD0iNjUiIHk9IjQwIiB3aWR0aD0iMjAiIGhlaWdodD0iMjAiIGZpbGw9IiMwZjc1ODkiIGNsYXNzPSJzcSI+PGFuaW1hdGUgYXR0cmlidXRlTmFtZT0iZmlsbCIgZnJvbT0iIzBmNzU4OSIgdG89IiM0N2NmZWEiIHJlcGVhdENvdW50PSJpbmRlZmluaXRlIiBkdXI9IjFzIiBiZWdpbj0iMC4zNzUiIHZhbHVlcz0iIzQ3Y2ZlYTsjNDdjZmVhOyMwZjc1ODk7IzBmNzU4OSIga2V5VGltZXM9IjA7MC4xOzAuMjsxIj48L2FuaW1hdGU+PC9yZWN0PjxyZWN0IHg9IjE1IiB5PSI2NSIgd2lkdGg9IjIwIiBoZWlnaHQ9IjIwIiBmaWxsPSIjMGY3NTg5IiBjbGFzcz0ic3EiPjxhbmltYXRlIGF0dHJpYnV0ZU5hbWU9ImZpbGwiIGZyb209IiMwZjc1ODkiIHRvPSIjNDdjZmVhIiByZXBlYXRDb3VudD0iaW5kZWZpbml0ZSIgZHVyPSIxcyIgYmVnaW49IjAuNzVzIiB2YWx1ZXM9IiM0N2NmZWE7IzQ3Y2ZlYTsjMGY3NTg5OyMwZjc1ODkiIGtleVRpbWVzPSIwOzAuMTswLjI7MSI+PC9hbmltYXRlPjwvcmVjdD48cmVjdCB4PSI0MCIgeT0iNjUiIHdpZHRoPSIyMCIgaGVpZ2h0PSIyMCIgZmlsbD0iIzBmNzU4OSIgY2xhc3M9InNxIj48YW5pbWF0ZSBhdHRyaWJ1dGVOYW1lPSJmaWxsIiBmcm9tPSIjMGY3NTg5IiB0bz0iIzQ3Y2ZlYSIgcmVwZWF0Q291bnQ9ImluZGVmaW5pdGUiIGR1cj0iMXMiIGJlZ2luPSIwLjYyNXMiIHZhbHVlcz0iIzQ3Y2ZlYTsjNDdjZmVhOyMwZjc1ODk7IzBmNzU4OSIga2V5VGltZXM9IjA7MC4xOzAuMjsxIj48L2FuaW1hdGU+PC9yZWN0PjxyZWN0IHg9IjY1IiB5PSI2NSIgd2lkdGg9IjIwIiBoZWlnaHQ9IjIwIiBmaWxsPSIjMGY3NTg5IiBjbGFzcz0ic3EiPjxhbmltYXRlIGF0dHJpYnV0ZU5hbWU9ImZpbGwiIGZyb209IiMwZjc1ODkiIHRvPSIjNDdjZmVhIiByZXBlYXRDb3VudD0iaW5kZWZpbml0ZSIgZHVyPSIxcyIgYmVnaW49IjAuNXMiIHZhbHVlcz0iIzQ3Y2ZlYTsjNDdjZmVhOyMwZjc1ODk7IzBmNzU4OSIga2V5VGltZXM9IjA7MC4xOzAuMjsxIj48L2FuaW1hdGU+PC9yZWN0Pjwvc3ZnPg==')}
    """
