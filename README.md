# Elm Applicatives & Json Decoders
## FP Concepts They Don’t Want You to Know About (Which Is Why All the *Fun* Stuff is Hidden in *.Extra)
#### Special thanks to [@fresheyeball](https://github.com/fresheyeball) for explaining this shit to me


- - -

## Setup


Installs deps and then runs Elm Reactor


```bash
npm install
npm start
```

- - -


#### Disclaimer:

I’m not a Haskeller – I have an art degree.


#### What we’re building towards:

[Pokémon Viewer working demo](https://codepen.io/toastal/pen/kXAKPk)


- - -


## Quick Fly-By at Applicatives

So we know how `Maybe` works—it’s a `Just a` or `Nothing`.

To go from a `Just 1` to a `Just 3` we'd use `map` because
`Maybe` is a Functor.


```elm
Maybe.map ((+) 2) (Just 1) == Just 3
--=> True
```


The `a` in `Just a` can also be a function.

So what happens if we had a `Just (+)` with the addition infix
operator… how do we use this to add in an applicative manner
to add Just 1 and Just 2?


- - -


Applicatives have 2 properties:

- `pure`, `singleton`

- `apply`, `ap`, `<*>`


- - -


Pure lets us know how to create a singleton list for the
default case of some applicative. The type signature of pure
in Haskell should make sense.


```haskell
pure :: Applicative f => a -> f a
```


Examples of Elm singletons:

- `Maybe` - `Just`

- `Result` - `Ok`

- `List` - `flip (::) []`


- - -


And the ability to lift in values in with apply (Haskell):


```haskell
liftA :: Applicative f => (a -> b) -> f a -> f b
(<*>) :: f (a -> b) -> f a -> f b
```


- - -


So what is `Just (+)`?


```elm
foo : Maybe (number -> number -> number)
foo =
    Just (+)
```


What is [`Maybe.Extra.andMap`](http://package.elm-lang.org/packages/elm-community/maybe-extra/1.1.0/Maybe-Extra#andMap)?


```elm
andMap : Maybe (a -> b) -> Maybe a -> Maybe b
```


Looks a lot like apply/lift… So let’s use it:


```elm
import Maybe.Extra as Maybe

-- foo = Just (+)

bar : Maybe (number -> number)
bar =
    foo `Maybe.andMap` Just 1
```


And let’s apply values to completion


```elm
baz : Maybe number
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

infixl 2 <*>
(<*>) : Maybe (a -> b) -> Maybe a -> Maybe b
(<*>) =
    Maybe.andMap

isJust3 : Bool
isJust3 =
    (singleton (+) <*> Just 1 <*> Just 2) == Just 3
--=> True

isNothing : Bool
isNothing =
    (singleton (+) <*> Just 1 <*> Nothing) == Nothing
--=> True
```


Look at the the demo
[`MaybeApplicative.elm`](https://github.com/toastal/elm-applicatives-and-json-decoders/blob/master/demo/MaybeApplicative.elm).


- - -


So where have we seen a something like this?


```elm
-- given the function foo'...
foo' : number -> number -> number
foo' x y =
    x * y


-- partially in a 1
foo'' : number -> number
foo'' =
    foo' 1


-- Easter Egg: we've created a monoid
foo'' 37 == 37
--=> True
```


` ` (space) is function application ;)


- - -


## So how does this relate to Json Decoders?


In [`Json.Decode.Extra`](http://package.elm-lang.org/packages/elm-community/json-extra/1.0.0/Json-Decode-Extra)
we have [`apply`](http://package.elm-lang.org/packages/elm-community/json-extra/1.0.0/Json-Decode-Extra#apply)
and the infix [`|:`](http://package.elm-lang.org/packages/elm-community/json-extra/1.0.0/Json-Decode-Extra#|:):


```elm
apply : Decoder (a -> b) -> Decoder a -> Decoder b
(|:) : Decoder (a -> b) -> Decoder a -> Decoder b
```


Well that’s obviously apply…

And in [`Json.Decode`](http://package.elm-lang.org/packages/elm-lang/core/4.0.4/Json-Decode)
we have [`succeed`](http://package.elm-lang.org/packages/elm-lang/core/4.0.4/Json-Decode#succeed):


```elm
succeed : a -> Decoder a
```


Looks pretty pure and singleton-y to me…


- - -


## So let’s apply (heh heh) our knowledge


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

Also, let’s forget that the `Json.Decode.object*`s even exist because
they don’t scale infinitely whereas the applicative use does.


```elm
import Json.Decode as Decode exposing ((:=))


fooDecoder : Decoder Int
fooDecoder =
    "foo" := Decode.int
```


`(:=) : String -> Decoder a -> Decoder a`

So this `:=` infix operator is used to apply the given decoder given
a string for a key in a JSON object (e.g. "foo" will be decoded as an integer).


- - -


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
import Json.Decode as Decode


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


But, go look at the demo 
[`JsonDecodeApplicative.elm`](https://github.com/toastal/elm-applicatives-and-json-decoders/blob/master/demo/JsonDecodeApplicative.elm).


- - -


So how do we find Applicatives in a language like Elm without
higher-kinded types? Look for type signatures and certain names
or think about what the `singleton` would be.

In Elm you’ll see the term `singleton` or `succeed` (like `Decoder`
and `Task`) for `pure`.
…And most of the time you'll see `andMap`, `ap`, or `apply`.


- - -


## The Real Takeaway / TL;DR:

If we always keep in mind that `Json.Decode.Decoder` is an 
applicative functor, we can `map` and `apply` our way to a JSON 
deserialization victory—something I found incredibly confusing
when I first started (literally to the point where I abandoned
some projects early on because I didn't know how to decode some
scarier JSON).

**So let's see some in action** with some real JSON HTTP
requests because people want to know how to work with Tasks and
Cmds as well—see 
[Pokémon Viewer demo](https://codepen.io/toastal/pen/kXAKPk)
[`PokemonViewer.elm`](https://github.com/toastal/elm-applicatives-and-json-decoders/blob/master/demo/PokemonViewer.elm).
