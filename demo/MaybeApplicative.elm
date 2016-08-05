module MaybeApplicative exposing (..)

import Html exposing (Html, h1, text)
import Maybe.Extra as Maybe


{-| Infix for Maybe.andMap which is the same as apply

In Haskell:
(<$>) :: Functor f => (a -> b) -> f a -> f b

Which takes in Functor (because of polymorphism)--not just Maybe
-}
infixl 2 =>


(<$>) : Maybe (a -> b) -> Maybe a -> Maybe b
(<$>) =
    Maybe.andMap


view : a -> Html String
view x =
    h1 [] [ text <| toString x ]


{-| Same as Just (+) `Maybe.andMap` Just 1 `Maybe.andMap` Just 2
-}
main : Html String
main =
    view <| Just (+) <$> Just 1 <$> Just 2



--=> Just 3
