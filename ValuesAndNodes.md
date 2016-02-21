# Values #
All values used in the Logo interpreter can be stored in 16 bits.
Such a value may be either an unsigned 15-bit integer, or a reference
to a "node."

Integer (15-bit unsigned):
```
  0IIIIIII IIIIIIII
```

Node pointer:
```
  1NNNNNNN nnnnnnZ0
   \____________/|\
    node number  | reserved
                 |
                 zone = 0 for builtin nodes (located in Flash)
                        1 for user created nodes (located in RAM)
```

# Nodes #

Low bits of the first byte can be used to identify type:
  * 000 = object (requires pointer management)
  * 100 = reference (object without a pointer)  (free nodes count as references)
  * 10 = list node
  * 1 = FP data

Bit 7 of the second byte is reserved for the garbage collector.

Most nodes will be user-created and stored in RAM.  We would also like
to have some builtin nodes, which don't ever need to change. These
include the void node and the builtin primitives.

It would also be nice to have builtin symbols (TRUE, FALSE, the names
of primitives) but this would require a bit of trickery in order to
allow those words to be used as variable names.  Maybe we could have a
special "split-symbol" type which includes a reference to a string
holding the symbol's name, rather than including the name in the
structure as with a normal symbol.  At the very least, we could use
builtin symbols so long as (a) there's only one builtin symbol in each
obarray bin, and (b) the user doesn't alter the symbol's
procedure/variable definition or properties.

## FREE node ##
```
  00000100 *0000000 nnnnnnnn NNNNNNNN
                    \_______________/
                     reference to next
                     node in free list;
                     0 if none.
```

Free nodes are created by the garbage collector when a previously-used
node is no longer referenced.  (Memory which has been allocated for
node storage but not yet needed is left uninitialized.)  If a subr
creates nodes for temporary use and we are certain that they have not
been referenced elsewhere, the subr might be allowed to explicitly
free them.

These free nodes are kept in linked lists.  There is one linked list
for single free nodes, one for pairs of free nodes, and one for
quadruples.  (We need to be able to allocate blocks of two or four
nodes at a time for floating-point numbers; see below.)  The end of
one of these lists is indicated by a zero, not by a reference to the
empty or void node as with an ordinary list!

To allocate a single free node, we look first to the list of single
free nodes, then to uninitialized node memory, then to the list of
pairs, then to the list of quads.  If we allocate only one of a free
pair, the remaining node is returned to the list of single free nodes.
If we allocate only one of a quad, one node is returned to the list of
single free nodes and two to the list of pairs.  And so forth.

To allocate a pair (for storing a real number), we look first to the
list of free pairs, then to UNM, then to the list of quads.

To allocate a quad (for storing a complex number), we look first to
the list of free quads, then to UNM.

We would like to be able to reclaim unused memory, and shrink the
appvar, when we no longer need so much space.  This should be done by
the garbage collector, as it requires traversing the free-node lists.

We might also like to be able to defragment the node area.  This could
be very difficult.  One approach would be to replace all the nodes to
be moved with transparent reference nodes, and then scan through all
the existing nodes and objects to find references to those nodes.  Any
defragmenting scheme would cause problems unless we disallow non-Logo
data in the stack (or, alternatively, only allow defragmenting at the
top level.)

When exiting the program editor, we should undefine procedures and
call the GC before re-reading and redefining them.  This will help
avoid allocating excessive numbers of extra nodes.


## OBJECT node ##
```
  TTTTT000 *PPPPPPP aaaaaaaa AAAAAAAA
  \___/     \_______________________/
   type     absolute address of data
```

Objects contain a data section; the format is dependent on the type.
With the exception of arrays, objects are essentially immutable, and
the size of the data section shouldn't change during the lifetime of
the object.

When we need to rearrange memory, we will need to update all the
addresses stored in object nodes.  Object nodes have the low 3 bits of
the first byte clear, to make them easy to detect.

Object types include word, string, array, and subr, and possibly
others to be determined.


## REFERENCE node ##
```
  TTTTT100 *xxxxxxx nnnnnnnn NNNNNNNN
  \___/     \_____/ \_______________/
   type      data    value
```

Reference nodes are similar to object nodes but contain a 16-bit value
parameter (which might be an integer, or might be a reference to
another node) rather than an external data block.

Reference types include void, empty, quote and colon, and possibly
others to be determined.


## LIST node ##
```
  aaaaaa10 *AAAAAAA bbbbbbbb BBBBBBBB
  \_______________/ \_______________/
   BUTFIRST (CDR)    FIRST element (CAR)
```

A list consists of a FIRST (also known as CAR) and a BUTFIRST (also
known as CDR or REST.)

It is worth noting that this format severely restricts the possible
values for the BUTFIRST.  Because bits 0, 1, and 15 are fixed and
cannot be used for storage, we have two limitations:

  * The BUTFIRST must be another node, not an integer.  This is
> consistent with the standard interpretation that the BUTFIRST is a
> list.  (In Lisp, cons cells are often used for things other than
> ordinary linked lists.  This is not done in Logo; the standard
> primitives, such as FPUT, do not allow it.  In UCBLogo it is only
> possible by using .SETBF.)

  * The BUTFIRST must be a user node, not a builtin node.  In the
> future, it might be possible for a builtin node to have another
> builtin node as its BUTFIRST; but I don't currently plan on having
> any builtin list nodes anyway.

This means that the empty list must be a user node.  Perhaps this
could be defined to be user node 0.


## FLOAT node ##
```
  xxxxxxx1 *xxxxxxx Lxxxxxxx xxxxxxxx
```

Floating-point numbers are normally stored on the 83+ as 9 bytes:
sign, exponent, and 7 BCD bytes of mantissa.  We can cram an FP-number
plus a few bits of metadata into 64 bits by converting the BCD bytes
to binary.  Converting BCD->binary is easy; simply subtract out 6
times the high nibble.  Converting binary->BCD is more computationally
difficult, but we can use a LUT.

A complete real number:
```
    mmmmmmm1 *mmmmmmm 0mmmmmmm Smmmmmmm  mmmmmmm1 *mmmmmmm 0mmmmmmm EEEEEEEE
    \________________________/ /\_________________________________/ \______/
     low 3 bytes of mantissa  /    next 4 bytes of mantissa          exponent 
                             sign
```

A complete complex number:
```
    mmmmmmm1 *mmmmmmm 1mmmmmmm Smmmmmmm  mmmmmmm1 *mmmmmmm 0mmmmmmm EEEEEEEE
    mmmmmmm1 *mmmmmmm 0mmmmmmm Smmmmmmm  mmmmmmm1 *mmmmmmm 0mmmmmmm EEEEEEEE
```