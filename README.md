# Elm Applicatives & Json Decoders
#### Special thanks to [@fresheyeball](https://github.com/fresheyeball) for explaining this shit to me


- - -

## Setup

```bash
npm install
npm start
```

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


Create some dummy JSON string


```elm
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
```


Create some type alias to represent these cool data items


```elm
type alias CoolItem =
    { foo : Int
    , bar : Bool
    }
```


Let's create a decoder using applicative.

Reminder: the constructor for `CoolItem` is `(Int -> Bool -> CoolItem)`

So, `Decode.succed CoolItem` is `Decoder (Int -> Bool -> CoolItem)`

Also, lets forget `Json.Decode.objectN`s don't exist because they don't
scale infinity whereas the applicatives do.


```elm
import Json.Decode as Decode exposing ((:=))


coolItemDecoder : Decoder CoolItem
coolItemDecoder =
    Decode.succeed CoolItem
        |: ("foo" := Decode.int)
        |: ("bar" := Decode.bool)
```


`(:=) : String -> Decoder a -> Decoder a`

So this `:=` infix operator is used to apply the given decoder given
a string for key JSON object (e.g. "foo" will be decoded as an integer).

So what happens when when apply in our foo decoder?

Well let's look at some types:

```elm
import Json.Decode as Decode exposing (Decoder, (:=))
import Json.Docode.Extra as Decode ((|:))


baz : Decoder (Int -> Bool -> CoolItem)
baz =
  Decode.succeed CoolItem


qux : Decoder (Bool -> CoolItem)
qux =
  Decode.succeed CoolItem
    |: ("foo" := Decode.int)


-- And the full decoder
coolItemDecoder : Decoder CoolItem
coolItemDecoder =
    Decode.succeed CoolItem
        |: ("foo" := Decode.int)
        |: ("bar" := Decode.bool)
```


So all we have to do now is set up our app to decode the JSON


```elm
import Html exposing (Html, text)


view : a -> Html String
view =
    text << toString


main : Html String
main =
    coolJson
        |> Decode.decodeString (Decode.list coolListDecoder)
        |> view
```


`Decode.decodeString : Decoder a -> String -> Result String a`

`Decode.list : Decoder a -> Decoder (List a)`

But, go look at the demo.
