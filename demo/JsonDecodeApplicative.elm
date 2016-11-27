module JsonDecodeApplicative exposing (..)

import Html exposing (Html, text)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode exposing ((|:))


coolJson : String
coolJson =
    """[
  {
    "foo": 0,
    "bar": true
  },
  {
    "foo": 1,
    "bar": true
  },
  {
    "foo": 2,
    "bar": false
  }
]
"""


type alias CoolItem =
    { foo : Int
    , bar : Bool
    }


{-| Reminder: CoolItem == (Int -> Bool -> CoolItem)
-}
coolItemDecoder : Decoder CoolItem
coolItemDecoder =
    Decode.succeed CoolItem
        |: Decode.field "foo" Decode.int
        |: Decode.field "bar" Decode.bool


view : a -> Html String
view =
    text << toString


main : Html String
main =
    coolJson
        |> Decode.decodeString (Decode.list coolItemDecoder)
        |> view
