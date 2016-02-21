We would like to be able to parse user input, which could contain arbitrarily long lists nested arbitrarily deeply, without using more than O(1) additional storage.  The trick is that while we're parsing, there is unused space in the list nodes we create (because we don't yet know where the end of the input will be.)

This algorithm, in fact, may be thought of as a modified top-down parser, except that the stack is kept within this unused space.  Specifically, we use the BUTFIRST pointer to store the parent of each "incomplete" node.

## Overview ##

While we're parsing, we are continually adding elements onto the end of a particular list; let's call that list _L_.  _currentNode_ is the last node in _L_, or empty if _L_ is empty.  _parentNode_ is a node whose first element is _L_.  (_parentNode_ is initially set to a dummy node, which is just used to keep track of where parsing ultimately began, and to act as a sentinel so we know where the bottom of our "stack" is.)

When we see a word, we just add it onto the end of _L_, by setting either first(_parentNode_) (creating a new list) or butfirst(_currentNode_) (adding onto the existing list.)

When we see a left bracket, we want to add a new, empty list onto the end of _L_, then start adding elements to it.  So we do the same thing as before (except that our new element is an empty list rather than a word.)  Then we save _parentNode_, set _parentNode_ to our new node and set _currentNode_ to empty.

When we see a right bracket, we "pop" back to the previous list and continue from where we left off.

## Pseudocode ##

  * _currentNode_ := empty
  * _parentNode_ := cons(empty, empty)

  * **while** there are more characters to read **do**
    * read the next token, _t_, from the input
    * **if** _t_ = `'['` **then**
      * _x_ := cons(empty, _parentNode_)
      * **if** _currentNode_ = empty **then**
        * first(_parentNode_) := _x_
      * **else**
        * butfirst(_currentNode_) := _x_
      * _parentNode_ := _x_
      * _currentNode_ := empty
    * **else if** _t_ = `']'` **then**
      * _currentNode_ := _parentNode_
      * _parentNode_ := butfirst(_currentNode_)
      * butfirst(_currentNode_) := empty
      * **if** _parentNode_ = empty **then** throw error
    * **else**
      * _x_ := cons(_t_, empty)
      * **if** _currentNode_ = empty **then**
        * first(_parentNode_) := _x_
      * **else**
        * butfirst(_currentNode_) := _x_
      * _currentNode_ := _x_

  * **if** butfirst(_parentNode_) != empty **then** throw error

  * **output** first(_parentNode_)

## Examples ##

Parsing the string `a b c`:
```
Input   Output
-----   ------
        P C
a b c   ( () . () )

        P C
b c     ( (a . ()) . () )

        P      C
c       ( (a . (b . ())) . () )

        P           C
$       ( (a . (b . (c . ()))) . () )

Result: (a . (b . (c . ()))) = (a b c)
```

Parsing the string `a [b c] d`:
```
Input         Output
-----         ------
              P C
a [ b c ] d   ( () . () )

              P C
[ b c ] d     ( (a . ()) . () )

              #1     P C
b c ] d       ( (a . ( () . #1) ) . () )

              #1     P C
c ] d         ( (a . ( (b . ()) . #1) ) . () )

              #1     P      C
] d           ( (a . ( (b . (c . ())) . #1) ) . () )

              P      C
d             ( (a . ( (b . (c . ())) . ()) ) . () )

              P                         C
$             ( (a . ( (b . (c . ())) . (d . ())) ) . () )

Result: (a . ( (b . (c . ())) . (d . ())) ) = (a (b c) d)
```

Parsing the string `[[][]]`:
```
Input          Output
-----          ------
               P  C
[ [ ] [ ] ]    (  () . ()  )

               #1 P  C
[ ] [ ] ]      (  (  () . #1  ) . ()  )

               #1 #2 P C
] [ ] ]        (  (  ( () . #2) . #1  ) . ()  )

               #1 P  C
[ ] ]          (  (  ( () . () ) . #1  ) . ()  )

               #1 #2        P C
] ]            (  (  ( () . ( () . #2 ) ) . #1  ) . ()  )

               #1 P         C
]              (  (  ( () . ( () . () ) ) . #1  ) . ()  )

               P  C
$              (  (  ( () . ( () . () ) ) . ()  ) . ()  )

Result: ((() . (() . ())) . ()) = ( (()  ()) )
```










