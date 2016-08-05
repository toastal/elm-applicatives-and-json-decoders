module MaybeApplicative exposing (..)

import Html exposing (Html, code, div, h1, h2, text)
import Maybe.Extra as Maybe


{-| Infix for Maybe.andMap which is the same as apply

In Haskell:
(<*>) :: Applicative f => f (a -> b) -> f a -> f b

Which takes in Applicative (because of polymorphism)--not just Maybe
-}
infixl 2 =>


(<*>) : Maybe (a -> b) -> Maybe a -> Maybe b
(<*>) =
    Maybe.andMap


view : a -> Html String
view x =
    div []
        [ h1 []
            [ code [] [ text "Just (+) <$> Just 1 <$> Just 2" ]
            , text " :"
            ]
        , h2 [] [ text <| toString x ]
        ]


{-| Same as Just (+) `Maybe.andMap` Just 1 `Maybe.andMap` Just 2
-}
main : Html String
main =
    view <| Just (+) <$> Just 1 <$> Just 2



--=> Just 3
