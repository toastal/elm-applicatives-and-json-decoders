# Elm Applicatives & Json Decoders
#### Special thanks to [@fresheyeball](https://github.com/fresheyeball) for explaining this shit to me


- - -


## Quick Fly-By at Applicatives

So we know how `Maybe` works--it's a `Just a` or `Nothing`.

`a` in `Just a` can be a function.

So what happens if we had a `Just (+)` with the addition infix
operator... how do we use this to add in an applicative manner?


- - -


Applicatives have 2 properties:

- `pure`, `singleton`

- `apply`, `ap`, `<*>`

Pure lets us know how to create a singleton list of for the
default case of some applicative. Examples:

- `Maybe` - `Just`

- `List` - `flip (::) []`

And the ability to apply values in.


- - -


So what is `Just (+)`?


```elm
foo : Maybe (number -> number -> number)
foo =
  Just (+)
```


So let's use apply


```elm
import Maybe.Extra as Maybe


bar : Maybe (number -> number)
bar =
  foo `Maybe.andMap` Just 1
```


And let's apply the value to completely


```elm
baz : Maybe Int
baz =
  bar `Maybe.andMap` Just 2

isJust3 : Bool
isJust3 =
  baz == Just 3
--=> True
```

```elm
{-| Would be cool if we had Maybe.Extra.singleton -}
singleton : a -> Maybe a
singleton =
  Just

infixl 2 =>
(<*>) : Maybe (a -> b) -> Maybe a -> Maybe b
(<*>) =
  Maybe.andMap

isNothing : Bool
isNothing =
  singleton (+) <*> Just 1 <*> Nothing == Nothing
--=> True
```


Look at the the demo `MaybeApplicative.elm`.


- - -


## So how does this relate to Json Decoders?


In `Json.Decode.Extra`:


```elm
apply : Decoder (a -> b) -> Decoder a -> Decoder b
(|:) : Decoder (a -> b) -> Decoder a -> Decoder b
```


Well that's obviously apply...

And in `Json.Decode`:


```elm
succeed : a -> Decoder a
```


Looks pretty pure to me...


- - -


## So let's apply (heh heh) our knowledge



