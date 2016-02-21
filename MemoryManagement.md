Logo storage includes a stack and a heap.  On the 83+, the
interpreter stack will be stored in the OPS.  This has the advantage
that we will be able to use the system error handling system, as well
as cleaner interaction between Logo, BASIC, and assembly programs.

The heap will be stored in an appvar (`_logows`.)  This appvar will
have two sections:

  * object area (used for strings, arrays, and other variable-sized structures)

  * node area (used for lists, floating-point numbers, and object handles.)

Allocating and deallocating in the object area requires updating
handles, so it will be slow.  We want to avoid this as much as
possible.  Since numbers and lists are stored as nodes, the only case
where a Logo program would be doing a lot of (de)allocation of object
memory is string manipulation.  We might want to create a special
"character" type so that Logo programs can manipulate individual
characters without constantly allocating 1-character strings.

Nodes are never moved during their lifetimes.  Thus the node area
will grow and shrink, but that's all.  Since the node area is stored
after the objects, this growing and shrinking doesn't require any
updating of Logo handles.

We might even want to avoid updating OS pointers unnecessarily,
moving memory around ourselves, keeping track of how much the appvar
has grown or shrunk, and only call `DelVar3*` when it's necessary.