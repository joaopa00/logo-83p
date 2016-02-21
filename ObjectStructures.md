These are the object structures currently defined:

## SYMBOL structure ##
```
  pppppppp PPPPPPPP vvvvvvvv VVVVVVVV llllllll LLLLLLLL nnnnnnnn NNNNNNNN cccccccc CCCCCCCC [ xxxxxxxx ... ]
  \_______________/ \_______________/ \_______________/ \_______________/ \_______________/ \______________/
   procedure text    variable value    property list     next symbol in    length            name
                                                           this obarray bin
```

The SYMBOL structure is used to associate a word with its definition
as a procedure, variable, and property list.  A symbol is unique --
there is only one FOO in the workspace; every time the user types FOO
we get the same object.  This is done by linking all symbols into a
global hash table (the "obarray".)


## STRING structure ##
```
  cccccccc CCCCCCCC [ xxxxxxxx ... ]
  \_______________/ \______________/
   length            name
```

The STRING structure is for words that have been created dynamically
(using WORD, FPUT or LPUT) and haven't [yet](yet.md) been used as a procedure
or variable, thus there's most likely no need to look them up in the
obarray.  A string may, however, be converted into a symbol
("interned") when necessary.

As far as the user is concerned, there is no difference between symbol
and string objects.  Both are words.  So are numbers, for that matter.

The parser might want to store input words as strings if they contain
vertical-bar or backslash quoting, since such words are unlikely to be
needed as symbols.


## ARRAY structure ##
```
  cccccccc CCCCCCCC [ xxxxxxxx XXXXXXXX ... ]
  \_______________/   \_______________/
   length              elements
```

The ARRAY structure represents a standard array indexed from 1.


## OFFSET-ARRAY structure ##
```
  cccccccc CCCCCCCC oooooooo OOOOOOOO [ xxxxxxxx XXXXXXXX ... ]
  \_______________/ \_______________/   \_______________/
   length            origin              elements
```

The OFFSET-ARRAY structure represents an array with a user-specified
origin.  The origin is a [signed?] integer.


## SUBR structure ##
```
  ffffffff dddddddd aaaaaaaa bbbbbbbb cccccccc CCCCCCCC [ xxxxxxxx ... ]
  \______/ \______/ \______/ \______/ \_______________/   \______/
   flags    default  minimum  maximum  length of code      code
            arity    arity    arity
```

The SUBR structure represents a primitive (assembly-language
procedure.)  Most of these objects will be built-in, but there will
eventually be a way for users to create their own primitives.

Flags for a primitive may include:

  * Is it position-independent?  If it is, and there aren't any memory protection issues, we can run it without moving/copying it in memory. If it's not PI, or if it's stored too high in memory, it will be copied to appBackUpScreen or some similar location... which means all primitives have to be very short.

> Built-in primitives will probably also have this flag set, even
> though they aren't PI, since they won't ever move around.

  * Could it create or destroy TIOS variable data?  (If not, we don't have to worry about the Logo appvar being moved.)

  * Will it preserve the static storage used by Logo, including the imathptrs?