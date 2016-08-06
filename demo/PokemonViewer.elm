module PokemonViewer exposing (..)

import Array exposing (Array)
import Html exposing (..)
import Html.App exposing (program)
import Html.Attributes as Attr exposing (..)
import Html.Keyed
import Http
import Json.Decode as Decode exposing (Decoder, (:=))
import Json.Decode.Extra as Decode exposing ((|:))
import String
import String.Extra as String
import Task exposing (Task)


-- TYPES


type alias Pokemon =
    { id : Int
    , name : String
    , sprite : String
    , types : Array String
    }


pokemonDecoder : Decoder Pokemon
pokemonDecoder =
    Decode.succeed Pokemon
        |: ("id" := Decode.int)
        |: ("name" := Decode.string)
        |: (Decode.at [ "sprites", "front_default" ] Decode.string)
        |: ("types" := (Decode.array <| Decode.at [ "type", "name" ] Decode.string))



-- MODEL


type alias Model =
    { pokemon : List Pokemon
    }



-- UPDATE


type Msg
    = FetchPokemonSucceed Pokemon
    | FetchPokemonFail Http.Error


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchPokemonSucceed pkmn ->
            let
                -- TODO: sort
                pkmns : List Pokemon
                pkmns =
                    model.pokemon ++ [ pkmn ]
            in
                ( { model | pokemon = pkmns }, Cmd.none )

        -- Swallowing error
        FetchPokemonFail _ ->
            ( model, Cmd.none )



-- REQUESTS


getPokemon : Int -> Task Http.Error Pokemon
getPokemon id =
    Http.get pokemonDecoder
        <| String.join "" [ "http://pokeapi.co/api/v2/pokemon/", toString id, "/" ]


getPokemonsTo : Int -> Cmd Msg
getPokemonsTo limit =
    [1..limit]
        |> List.map (getPokemon >> Task.perform FetchPokemonFail FetchPokemonSucceed)
        |> Cmd.batch



-- VIEW


viewPokemon : Pokemon -> ( String, Html Msg )
viewPokemon { id, name, sprite, types } =
    let
        id' =
            toString id

        name' =
            String.capitalize True name
    in
        ( id'
        , li []
            [ dl []
                [ dt [] [ text "ID" ]
                , dd [] [ text id' ]
                , dt [] [ text "Name" ]
                , dd [] [ text name' ]
                , dt [] [ text "Sprite" ]
                , dd []
                    [ img [ src sprite, alt ("Sprite of " ++ name'), title name' ] []
                    ]
                , dt [] [ text "Type(s)" ]
                , dd []
                    [ text << String.capitalize True << Maybe.withDefault "" <| Array.get 0 types ]
                , dd []
                    [ text << String.capitalize True << Maybe.withDefault "" <| Array.get 1 types ]
                ]
            ]
        )


view : Model -> Html Msg
view { pokemon } =
    div []
        [ node "style"
            [ type' "text/css" ]
            [ text stylez ]
        , Html.Keyed.ol []
            <| List.map viewPokemon pokemon
        ]



-- STYLES


stylez : String
stylez =
    """html { box-sizing: border-box; background-color: #111; color: #fff; font-family: sans-serif }
    *, *::before, *::after { box-sizing: inherit }
    ol { display: flex; flex-flow: row wrap; list-style: none }
    ol > li { min-width: 12em; padding: 2.25em; margin-left: -1px; margin-top: -1px; border: 1px solid hsl(190, 80%, 30%) }
    dl dt, dl dd { display: inline }
    dl dt { vertical-align: top; font-weight: 700; color: hsl(190, 80%, 60%) }
    dl dt::after { content: ": " }
    dl dd { margin: 0; white-space: pre-wrap }
    dl dd::after { content: "\\A" }
    """



-- MAIN


main : Program Never
main =
    program
        { init = ( Model [], getPokemonsTo 20 )
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }
