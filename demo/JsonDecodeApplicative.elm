module JsonDecodeApplicative exposing (..)

import Html exposing (Html, text)
import Json.Decode as Decode
import Json.Decode.Extra as Decode exposing ((|:))


view : a -> Html
view =
    text << toString


main : Html String
main =
    view <| 20
