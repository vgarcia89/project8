(* <mlscheme.sml>=                              *)


(*****************************************************************)
(*                                                               *)
(*   \FOOTNOTESIZE SHARED: NAMES, ENVIRONMENTS, STRINGS, ERRORS, PRINTING, INTERACTION, STREAMS, \&\ INITIALIZATION *)
(*                                                               *)
(*****************************************************************)

(* <\footnotesize shared: names, environments, strings, errors, printing, interaction, streams, \&\ initialization>= *)
(* <for working with curried functions: [[id]], [[fst]], [[snd]], [[pair]], [[curry]], and [[curry3]]>= *)
fun id x = x
fun fst (x, y) = x
fun snd (x, y) = y
fun pair x y = (x, y)
fun curry  f x y   = f (x, y)
fun curry3 f x y z = f (x, y, z)
(* <boxed values 75>=                           *)
val _ = op fst    : ('a * 'b) -> 'a
val _ = op snd    : ('a * 'b) -> 'b
val _ = op pair   : 'a -> 'b -> 'a * 'b
val _ = op curry  : ('a * 'b -> 'c) -> ('a -> 'b -> 'c)
val _ = op curry3 : ('a * 'b * 'c -> 'd) -> ('a -> 'b -> 'c -> 'd)
(* [[bindList]] tried to                        *)
(*              extend an environment, but it passed *)
(*              two lists (names and values) of *)
(*              different lengths.              *)
(* RuntimeError    Something else went wrong during *)
(*              evaluation, i.e., during the    *)
(*              execution of [[eval]].          *)
(* \bottomrule                                  *)
(*                                              *)
(* Exceptions defined especially for this interpreter  *)
(* [*]                                          *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* Abstract syntax and values                   *)
(*                                              *)
(* An abstract-syntax tree can contain a literal value. *)
(* A value, if it is a closure, can contain an  *)
(* abstract-syntax tree. These two types are therefore *)
(* mutually recursive, so I define them together, using *)
(* [[and]].                                     *)
(*                                              *)
(* These particular types use as complicated a nest of *)
(* definitions as you'll ever see. The keyword  *)
(* [[datatype]] defines a new algebraic datatype; the *)
(* keyword [[withtype]] introduces a new type   *)
(* abbreviation that is mutually recursive with the *)
(* [[datatype]]. The first group of [[and]] keywords *)
(* define additional algebraic datatypes, and the second *)
(* group of [[and]] keywords define additional type *)
(* abbreviations. Everything in the whole nest is *)
(* mutually recursive. [*] [*]                  *)

(* Interlude: micro-Scheme in ML                *)
(*                                              *)
(* [*] \invisiblelocaltableofcontents[*]        *)
(*                                              *)
(* {epigraph}Conversation with David R. Hanson, coauthor *)
(* of A Retargetable C Compiler: Design and     *)
(* Implementation\break\citep                   *)
(* hanson-fraser:retargetable:book.             *)
(*                                              *)
(*  \myblock=\wd0 =0.8=0pt                      *)
(*                                              *)
(*  to \myblock\upshapeHanson: C is a lousy language *)
(*  to write a compiler in.                     *)
(*                                              *)
(* {epigraph} The interpreters in \crefrange    *)
(* impcore.chapgc.chap are written in C, which has much *)
(* to recommend it: C is relatively small and simple; *)
(* it is widely known and widely supported; its *)
(* perspicuous cost model makes it is easy to discover *)
(* what is happening at the machine level; and  *)
(* it provides pointer arithmetic, which makes it a fine *)
(* language in which to write a garbage collector. *)
(* But for implementing more complicated or ambitious *)
(* languages, C is less than ideal. In this and *)
(* succeeding chapters, I therefore present interpreters *)
(* written in the functional language Standard ML. *)
(*                                              *)
(* Standard ML is particularly well suited to symbolic *)
(* computing, especially functions that operate on *)
(* abstract-syntax trees; some advantages are detailed *)
(* in the sidebar \vpagerefmlscheme.good-ml. And an *)
(* ML program can illustrate connections between *)
(* language design, formal semantics, and       *)
(* implementations more clearly than a C program can. *)
(* Infrastructure suitable for writing interpreters *)
(* in ML is presented in this chapter and in \cref *)
(* mlinterps.chap,lazyparse.chap. That infrastructure is *)
(* introduced by using it to implement a language that *)
(* is now familiar: micro-Scheme.               *)
(*                                              *)
(* {sidebar}[t]Helpful properties of the ML family of *)
(* languages [*]                                *)
(*                                              *)
(*  \advance\parsepby -5.5pt \advance\itemsepby *)
(*  -5.5pt \advanceby -0.5pt                    *)
(*   • ML is safe: there are no unchecked run-time *)
(*  errors, which means there are no faults that are *)
(*  entirely up to the programmer to avoid.     *)
(*   • Like Scheme, ML is naturally polymorphic. *)
(*  Polymorphism simplifies everything. For example, *)
(*  unlike the C code in \crefrange             *)
(*  impcore.chapgcs.chap, the ML code in \crefrange *)
(*  mlscheme.chapsmall.chap uses just one       *)
(*  representation of lists and one length function. *)
(*  As another example, where the C code in \cref *)
(*  cinterps.chap defines three different types of *)
(*  streams, each with its own [[get]] function, the *)
(*  ML code in \crefmlinterps.chap defines one type *)
(*  of stream and one [[streamGet]] function. And *)
(*  when a job is done by just one polymorphic  *)
(*  function, not a group of similar functions, you *)
(*  know that the one function always does the same *)
(*  thing.                                      *)
(*   • Unlike Scheme, ML uses a static type system, and *)
(*  this system guarantees that data structures are *)
(*  internally consistent. For example, if one  *)
(*  element of a list is a function, every element of *)
(*  that list is a function. This happens without *)
(*  requiring variable declarations or type     *)
(*  annotations to be written in the code.      *)
(*                                              *)
(*  If talk of polymorphism mystifies you, don't *)
(*  worry; polymorphism in programming languages is *)
(*  an important topic in its own right. Polymorphism *)
(*  is formally introduced and defined in \cref *)
(*  typesys.chap, and the algorithms that ML uses to *)
(*  provide polymorphism without type annotations are *)
(*  described in \crefml.chap.                  *)
(*   • Like Scheme, ML provides first-class, nested *)
(*  functions, and its initial basis contains useful *)
(*  higher-order functions. These functions help *)
(*  simplify and clarify code. For example, they can *)
(*  eliminate the special-purpose functions that the *)
(*  C code uses to run a list of unit tests from back *)
(*  to front; the ML code just uses [[foldr]].  *)
(*   • To detect and signal errors, ML provides *)
(*  exception handlers and exceptions, which are more *)
(*  flexible and easier to use then C's [[setjmp]] *)
(*  and [[longjmp]].                            *)
(*   • Finally, least familiar but most important, *)
(*  ML provides native support for algebraic data *)
(*  types, which I use to represent both abstract *)
(*  syntax and values. These types provide value *)
(*  constructors like the [[IFX]] or [[APPLY]] used *)
(*  in previous chapters, but instead of [[switch]] *)
(*  statements, ML provides pattern matching. Pattern *)
(*  matching enables ML programmers to write function *)
(*  definitions that look like algebraic laws; such *)
(*  definitions are easier to follow than C code. *)
(*  The technique is demonstrated in the definition *)
(*  of function [[valueString]] on \cpageref    *)
(*  mlscheme.code.valueString. For a deeper dive into *)
(*  algebraic data types, jump ahead to \crefadt.chap *)
(*  and read through \crefadt.howto.            *)
(*                                              *)
(* {sidebar}                                    *)
(*                                              *)
(* The micro-Scheme interpreter in this chapter is *)
(* structured in the same way as the interpreter in *)
(* Chapter [->]. Like that interpreter, it has  *)
(* environments, abstract syntax, primitives, an *)
(* evaluator for expressions, and an evaluator for *)
(* definitions. Many details are as similar as I can *)
(* make them, but many are not: I want the interpreters *)
(* to look similar, but even more, I want my ML code to *)
(* look like ML and my C code to look like C.   *)
(*                                              *)
(* The ML code will be easier to read if you know my *)
(* programming conventions.                     *)
(*                                              *)
(*   • My naming conventions are the ones recommended by *)
(*  the SML'97 Standard Basis Library [cite     *)
(*  gansner:basis]. Names of types are written in *)
(*  lowercase letters with words separated by   *)
(*  underscores, like [[exp]], [[def]], or      *)
(*  [[unit_test]]. Names of functions and variables *)
(*  begin with lowercase letters, like [[eval]] or *)
(*  [[evaldef]], but long names may be written in *)
(*  ``camel case'' with a mix of uppercase and  *)
(*  lowercase letters, like [[processTests]] instead *)
(*  of the C-style [[process_tests]]. (Rarely, I may *)
(*  use an underscore in the name of a local    *)
(*  variable.)                                  *)
(*                                              *)
(*  Names of exceptions are capitalized, like   *)
(*  [[NotFound]] or [[RuntimeError]], and they use *)
(*  camel case. Names of value constructors, which *)
(*  identify alternatives in algebraic data types, *)
(*  are written in all capitals, possibly with  *)
(*  underscores, like [[IFX]], [[APPLY]], or    *)
(*  [[CHECK_EXPECT]]—just like enumeration literals *)
(*  in C.                                       *)
(*   • \qtrim0.5 If you happen to be a seasoned *)
(*  ML programmer, you'll notice something missing: *)
(*  the interpreter is not decomposed into modules. *)
(*  Modules get a book chapter of their own (\cref *)
(*  mcl.chap), but compared to what's in \cref  *)
(*  mcl.chap, Standard ML's module system is    *)
(*  complicated and hard to understand. To avoid *)
(*  explaining it, I define no modules—although I do *)
(*  use ``dot notation'' to select functions that are *)
(*  defined in Standard ML's predefined modules. *)
(*  By avoiding module definitions, I enable you to *)
(*  digest this chapter even if your only previous *)
(*  functional-programming experience is with   *)
(*  micro-Scheme.                               *)
(*                                              *)
(*  Because I don't use ML modules, I cannot easily *)
(*  write interfaces or distinguish them from   *)
(*  implementations. Instead, I use a           *)
(*  literate-programming trick: I put the types of *)
(*  functions and values, which is mostly what  *)
(*  ML interfaces describe, in boxes preceding the *)
(*  implementations. These types are checked by the *)
(*  ML compiler, and the trick makes it possible to *)
(*  present a function's interface just before its *)
(*  implementation.                             *)
(*                                              *)
(* My code is also affected by two limitations of ML: *)
(* ML is persnickety about the order in which   *)
(* definitions appear, and it has miserable support for *)
(* mutually recursive data definitions. These   *)
(* limitations arise because unlike C, which has *)
(* syntactic forms for both declarations and    *)
(* definitions, ML has only definition forms.   *)
(*                                              *)
(* In C, as long as declarations precede definitions, *)
(* you can be careless about the order in which both *)
(* appear. Declare all your structures (probably in *)
(* [[typedef]]s) in any order you like, and you can *)
(* define them in just about any order you like. Then *)
(* declare all your functions in any order you like, and *)
(* you can define them in any order you like—even if *)
(* your data structures and functions are mutually *)
(* recursive. Of course there are drawbacks: not all *)
(* variables are guaranteed to be initialized, and *)
(* global variables can be initialized only in limited *)
(* ways. And you can easily define mutually recursive *)
(* data structures that allow you to chase pointers *)
(* forever.                                     *)
(*                                              *)
(* In ML, there are no declarations, and you may write a *)
(* definition only after the definitions of the things *)
(* it refers to. Of course there are benefits: every *)
(* definition initializes its name, and initialization *)
(* may use any valid expression, including [[let]] *)
(* expressions, which in ML can contain nested  *)
(* definitions. And unless your code assigns to mutable *)
(* reference cells, you cannot define circular data *)
(* structures that allow you to chase pointers forever. *)
(* As a consequence, unless a structurally recursive *)
(* function fetches the contents of mutable reference *)
(* cells, it is guaranteed to terminate. ML's designers *)
(* thought this guarantee was more important than the *)
(* convenience of writing data definitions in many *)
(* orders. (And to be fair, using ML modules makes it *)
(* relatively convenient to get things in the right *)
(* order.)                                      *)
(*                                              *)
(* What about mutually recursive data? Suppose for *)
(* example, that type [[exp]] refers to [[value]] and *)
(* type [[value]] refers to [[exp]]? Mutually recursive *)
(* definitions like [[exp]] and [[value]] must be *)
(* written together, adjacent in the source code, *)
(* connected with the keyword [[and]]. (You won't see *)
(* [[and]] often, but when you do, please remember this: *)
(* it means mutual recursion, never a Boolean   *)
(* operation.)                                  *)
(*                                              *)
(* Mutually recursive function definitions provide more *)
(* options: they can be joined with [[and]], but it is *)
(* usually more convenient and more idiomatic to nest *)
(* one inside the other using a [[let]] binding. You *)
(* would use [[and]] only when both mutually recursive *)
(* functions need to be called by some third, client *)
(* function. When I use mutual recursion, I identify the *)
(* technique I use. Now, on to the code!        *)
(*                                              *)
(* Names and \chaptocsplitenvironments\cull, with \ *)
(* chaptocsplitintroduction to ML               *)
(*                                              *)
(* [*] In my C code, [[Name]] is an abstract type, and *)
(* by design, two values of type [[Name]] can be *)
(* compared using C's built-in [[==]] operator. In my ML *)
(* code, because ML strings are immutable and can be *)
(* meaningfully compared using ML's built-in [[=]] *)
(* operator, names are represented as strings. \mlslabel *)
(* name                                         *)
(* <support for names and environments>=        *)
type name = string
(* ML's [[type]] syntax is like C's [[typedef]]; *)
(* it defines a type by type abbreviation.      *)

(* Each micro-Scheme name is bound to a location that *)
(* contains a value. In C, such a location is   *)
(* represented by a pointer of C type \monoboxValue *. *)
(* In ML, such a pointer has type \monoboxvalue ref. *)
(* Like a C pointer, an ML [[ref]] can be read from and *)
(* written to, but unlike a C pointer, it can't be added *)
(* to or subtracted from.                       *)
(*                                              *)
(* In C, the code that looks up or binds a name has to *)
(* know what kind of thing a name stands for; that's why *)
(* the Impcore interpreter uses one set of environment *)
(* functions for value environments xi and rho and *)
(* another set for a function environment phi. In ML, *)
(* the code that looks up or binds a name is independent *)
(* of what a name stands for; it is naturally   *)
(* polymorphic. One set of polymorphic functions *)
(* suffices to implement environments that hold *)
(* locations, values, or types.                 *)
(*                                              *)
(* ML has a static type system, and polymorphism is *)
(* reflected in the types. An environment has type \ *)
(* monobox'a env; such an environment binds each name in *)
(* its domain to a value of type [['a]]. The [['a]] is *)
(* called a type parameter or type variable; it stands *)
(* for an unknown type. (Type parameters are explained *)
(* in detail in \creftypesys.tuscheme, where they have *)
(* an entire language devoted to them.) Type \monobox'a *)
(* env, like any type that takes a type parameter, can *)
(* be instantiated at any type; instantiation   *)
(* substitutes a known type for every occurrence of  *)
(* [['a]]. micro-Scheme's environment binds each name to *)
(* a mutable location, and it is obtained by    *)
(* instantiating type \monobox'a env using \nomathbreak\ *)
(* monobox'a = \monoboxvalue ref; the resulting type is *)
(* \monoboxvalue ref env.                       *)
(*                                              *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(* \advanceby 0.8pt \newskip\myskip \myskip=6pt *)
(*                                              *)
(*    Semantics   Concept        Interpreter    *)
(*        d       Definition     def (\cpageref *)
(*                               mlscheme.type.def) *)
(*        e       Expression     \mlstypeexp    *)
(*        x       Name           \mlstypename   *)
(*   [\myskip] v  Value          \mlstypevalue  *)
(*        l       Location       \monovalue ref (ref is *)
(*                               built into ML) *)
(*       rho      Environment    \monovalue ref env (\ *)
(*                               cpagerefmlscheme.type.env) *)
(*      sigma     Store          Machine memory (the *)
(*                               ML heap)       *)
(*                    Expression     \monoboxeval(e, rho) = *)
(*   [\myskip] \      evaluation     v, \break with sigma *)
(*   evale ==>\                      updated to sigma' \ *)
(*   evalr['] v                      mlsfunpageeval *)
(*                                              *)
(*                    Definition     \monoboxevaldef(d, rho *)
(*  <d,rho,sigma>     evaluation     ) = (rho', s), \break *)
(*   --><rho',                       with sigma updated to  *)
(*     sigma'>                       sigma' \mlsfunpage *)
(*                                   evaldef    *)
(*                                              *)
(*                Definedness    \monofind (x, rho) *)
(*   [\myskip] x                 terminates without raising *)
(*   in dom rho                  an exception (\cpageref *)
(*                               mlscheme.fun.find) *)
(*     rho(x)     Location       \monofind (x, rho) (\ *)
(*                lookup         cpagerefmlscheme.fun.find) *)
(*  sigma(rho(x)) Value lookup   \mono!(find (x, rho)) (\ *)
(*                               cpagerefmlscheme.fun.find) *)
(*   rho{x |->l}  Binding        \monobind (x, l, rho) (\ *)
(*                               cpagerefmlscheme.fun.bind) *)
(*          \     Allocation     call \monoboxref v; the *)
(*      centering                result is l    *)
(*      sigma{l|                                *)
(*       ->v}, \                                *)
(*        break                                 *)
(*      where l\                                *)
(*      notindom                                *)
(*        sigma                                 *)
(*                                              *)
(*          \     Store update   \monol := v    *)
(*      centering                               *)
(*      sigma{l|                                *)
(*       ->v}, \                                *)
(*        break                                 *)
(*      where lin                               *)
(*      dom sigma                               *)
(*                                              *)
(*                                              *)
(* Correspondence between micro-Scheme semantics and ML *)
(* code [*]                                     *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* My environments are implemented using ML's native *)
(* support for lists and pairs. Although my C code *)
(* represents an environment as a pair of lists, in ML, *)
(* it's easier and simpler to use a list of pairs. The *)
(* type of the list is \monobox(name * 'a) list; *)
(* the type of a single pair is \monoboxname * 'a. *)
(* A pair is created by an ML expression of the form \ *)
(* monobox(e_1, e_2); this pair contains the value of  *)
(* e_1 and the value of e_2. The pair \monobox(e_1, e_2) *)
(* has type \monoboxname * 'a if e_1 has type [[name]] *)
(* and e_2 has type [['a]]. \mlslabelenv        *)
(* <support for names and environments>=        *)
type 'a env = (name * 'a) list
(* <support for names and environments>=        *)
val emptyEnv = []
(* <support for names and environments>=        *)
exception NotFound of name
fun find (name, []) = raise NotFound name
  | find (name, (x, v)::tail) = if name = x then v else find (name, tail)
(* The [[fun]] definition form is ML's analog to *)
(* [[define]], but unlike micro-Scheme's [[define]], *)
(* it uses multiple clauses with pattern matching. Each *)
(* clause is like an algebraic law. The first clause *)
(* says that calling [[find]] with an empty environment *)
(* raises an exception; the second clause handles a *)
(* nonempty environment. The infix [[::]] is ML's way of *)
(* writing [[cons]], and it is pronounced ``cons.'' *)
(*                                              *)
(* To check x in dom rho, the ML code uses function *)
(* [[isbound]].                                 *)
(* <support for names and environments>=        *)
fun isbound (name, []) = false
  | isbound (name, (x, v)::tail) = name = x orelse isbound (name, tail)
(* <support for names and environments>=        *)
fun bind (name, v, rho) =
  (name, v) :: rho
(* <support for names and environments>=        *)
exception BindListLength
fun bindList (x::vars, v::vals, rho) = bindList (vars, vals, bind (x, v, rho))
  | bindList ([], [], rho) = rho
  | bindList _ = raise BindListLength

fun mkEnv (xs, vs) = bindList (xs, vs, emptyEnv)
(* <support for names and environments>=        *)
(* composition *)
infix 6 <+>
fun pairs <+> pairs' = pairs' @ pairs
(* The representation guarantees that there is an [['a]] *)
(* for every [[name]].                          *)
(*                                              *)
(* \setcodemargin7pt                            *)
(*                                              *)
(* The empty environment is represented by the empty *)
(* list. In ML, that's written using square brackets. *)
(* The [[val]] form is like micro-Scheme's [[val]] form. *)
(* <boxed values 1>=                            *)
val _ = op emptyEnv : 'a env
(* (The phrase in the box is like a declaration that *)
(* could appear in an interface to an ML module; through *)
(* some Noweb hackery, it is checked by the     *)
(* ML compiler.)                                *)
(*                                              *)
(* A name is looked up by function [[find]], which is *)
(* closely related to the [[find]] from \cref   *)
(* scheme.chap: it returns whatever is in the   *)
(* environment, which has type [['a]]. If the name is *)
(* unbound, [[find]] raises an exception. Raising an *)
(* exception is a lot like the [[throw]] operator in \ *)
(* crefschemes.chap; it is roughly analogous to *)
(* [[longjmp]]. The exceptions I use are listed in \vref *)
(* mlscheme.tab.exns.                           *)
(* <boxed values 1>=                            *)
val _ = op find : name * 'a env -> 'a
(* \mlsflabelfind                               *)

(* Again using [[::]], function [[bind]] adds a new *)
(* binding to an existing environment. Unlike \cref *)
(* scheme.chap's [[bind]], it does not allocate a *)
(* mutable reference cell.                      *)
(* <boxed values 1>=                            *)
val _ = op bind : name * 'a * 'a env -> 'a env
(* \mlsflabelbind                               *)

(* <boxed values 1>=                            *)
val _ = op bindList : name list * 'a list * 'a env -> 'a env
val _ = op mkEnv    : name list * 'a list -> 'a env
(* Finally, environments can be composed using the + *)
(*  operator. In my ML code, this operator is   *)
(* implemented by function [[<+>]], which I declare to *)
(* be [[infix]]. It uses the predefined infix function  *)
(* [[@]], which is ML's way of writing [[append]]. \ *)
(* mlsflabel<+>                                 *)
(* <boxed values 1>=                            *)
val _ = op <+> : 'a env * 'a env -> 'a env
(* <support for names and environments>=        *)
fun duplicatename [] = NONE
  | duplicatename (x::xs) =
      if List.exists (fn x' => x' = x) xs then
        SOME x
      else
        duplicatename xs
(* <boxed values 25>=                           *)
val _ = op duplicatename : name list -> name option
(* All interpreters incorporate these two exceptions: *)
(* <exceptions used in every interpreter>=      *)
exception RuntimeError of string (* error message *)
exception LeftAsExercise of string (* string identifying code *)
(* Some errors might be caused not by a fault in a *)
(* user's code but in my interpreter code. Such faults *)
(* are signaled by the [[InternalError]] exception. *)
(* <support for detecting and signaling errors detected at run time>= *)
exception InternalError of string (* bug in the interpreter *)
(* <list functions not provided by \sml's initial basis>= *)
fun unzip3 [] = ([], [], [])
  | unzip3 (trip::trips) =
      let val (x,  y,  z)  = trip
          val (xs, ys, zs) = unzip3 trips
      in  (x::xs, y::ys, z::zs)
      end

fun zip3 ([], [], []) = []
  | zip3 (x::xs, y::ys, z::zs) = (x, y, z) :: zip3 (xs, ys, zs)
  | zip3 _ = raise ListPair.UnequalLengths
(* \qbreak                                      *)
(*                                              *)
(* List utilities                               *)
(*                                              *)
(* Most of the list utilities anyone would need are part *)
(* of the initial basis of Standard ML. But the type *)
(* checker for pattern matching in \crefadt.chap *)
(* sometimes needs to unzip a list of triples into a *)
(* triple of lists. I define [[unzip3]] and also the *)
(* corresponding [[zip3]].                      *)
(* <boxed values 23>=                           *)
val _ = op unzip3 : ('a * 'b * 'c) list -> 'a list * 'b list * 'c list
val _ = op zip3   : 'a list * 'b list * 'c list -> ('a * 'b * 'c) list
(* Standard ML's list-reversal function is called *)
(* [[rev]], but in this book I use [[reverse]]. *)
(* <list functions not provided by \sml's initial basis>= *)
val reverse = rev
(* <list functions not provided by \sml's initial basis>= *)
fun optionList [] = SOME []
  | optionList (NONE :: _) = NONE
  | optionList (SOME x :: rest) =
      (case optionList rest
         of SOME xs => SOME (x :: xs)
          | NONE    => NONE)
(* Function [[optionList]] inspects a list of optional *)
(* values, and if every value is actually present (made *)
(* with [[SOME]]), then it returns the values. Otherwise *)
(* it returns [[NONE]].                         *)
(* <boxed values 24>=                           *)
val _ = op optionList : 'a option list -> 'a list option
(* The [[xdeftable]] is shared with the Impcore parser. *)
(* Function [[reduce_to_xdef]] is almost shareable as *)
(* well, but not quite---the abstract syntax of *)
(* [[DEFINE]] is different.                     *)

(* <utility functions for string manipulation and printing>= *)
fun intString n =
  String.map (fn #"~" => #"-" | c => c) (Int.toString n)
(* <boxed values 15>=                           *)
val _ = op intString : int -> string
(* The [[xdeftable]] is shared with the Impcore parser. *)
(* Function [[reduce_to_xdef]] is almost shareable as *)
(* well, but not quite---the abstract syntax of *)
(* [[DEFINE]] is different.                     *)

(* To characterize a list by its length and contents, *)
(* interpreter messages use strings like        *)
(* ``3 arguments,'' which come from functions [[plural]] *)
(* and [[countString]].                         *)
(* <utility functions for string manipulation and printing>= *)
fun plural what [x] = what
  | plural what _   = what ^ "s"

fun countString xs what =
  intString (length xs) ^ " " ^ plural what xs
(* <utility functions for string manipulation and printing>= *)
val spaceSep = String.concatWith " "   (* list separated by spaces *)
val commaSep = String.concatWith ", "  (* list separated by commas *)
(* To separate items by spaces or commas, interpreters *)
(* use [[spaceSep]] and [[commaSep]], which are special *)
(* cases of the basis-library function          *)
(* [[String.concatWith]].                       *)
(*                                              *)
(* <boxed values 16>=                           *)
val _ = op spaceSep : string list -> string
val _ = op commaSep : string list -> string
(* [[bindList]] tried to                        *)
(*              extend an environment, but it passed *)
(*              two lists (names and values) of *)
(*              different lengths.              *)
(* RuntimeError    Something else went wrong during *)
(*              evaluation, i.e., during the    *)
(*              execution of [[eval]].          *)
(* \bottomrule                                  *)
(*                                              *)
(* Exceptions defined especially for this interpreter  *)
(* [*]                                          *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* Abstract syntax and values                   *)
(*                                              *)
(* An abstract-syntax tree can contain a literal value. *)
(* A value, if it is a closure, can contain an  *)
(* abstract-syntax tree. These two types are therefore *)
(* mutually recursive, so I define them together, using *)
(* [[and]].                                     *)
(*                                              *)
(* These particular types use as complicated a nest of *)
(* definitions as you'll ever see. The keyword  *)
(* [[datatype]] defines a new algebraic datatype; the *)
(* keyword [[withtype]] introduces a new type   *)
(* abbreviation that is mutually recursive with the *)
(* [[datatype]]. The first group of [[and]] keywords *)
(* define additional algebraic datatypes, and the second *)
(* group of [[and]] keywords define additional type *)
(* abbreviations. Everything in the whole nest is *)
(* mutually recursive. [*] [*]                  *)

(* <utility functions for string manipulation and printing>= *)
fun nullOrCommaSep empty [] = empty
  | nullOrCommaSep _     ss = commaSep ss                   
(* Sometimes, as when printing substitutions for *)
(* example, the empty list should be represented by *)
(* something besides the empty string. Like maybe the *)
(* string [["idsubst"]]. Such output can be produced by, *)
(* e.g., [[nullOrCommaSep "idsubst"]].          *)
(* <boxed values 17>=                           *)
val _ = op nullOrCommaSep : string -> string list -> string
(* <utility functions for string manipulation and printing>= *)
fun fnvHash s =
  let val offset_basis = 0wx011C9DC5 : Word.word  (* trim the high bit *)
      val fnv_prime    = 0w16777619  : Word.word
      fun update (c, hash) = Word.xorb (hash, Word.fromInt (ord c)) * fnv_prime
      fun int w =
        Word.toIntX w handle Overflow => Word.toInt (Word.andb (w, 0wxffffff))
  in  int (foldl update offset_basis (explode s))
  end
(* The [[hash]] primitive in the \usm interpreter uses *)
(* an algorithm by Glenn Fowler, Phong Vo, and Landon *)
(* Curt Noll, which I implement in function [[fnvHash]]. *)
(* [*] I have adjusted the algorithm's ``offset basis'' *)
(* by removing the high bit, so the computation works *)
(* using 31-bit integers. The algorithm is described by *)
(* an IETF draft at \urlhttp://tools.ietf.org/html/ *)
(* draft-eastlake-fnv-03, and it's also described by the *)
(* web page at \urlhttp://www.isthe.com/chongo/tech/comp *)
(* /fnv/.                                       *)
(* <boxed values 18>=                           *)
val _ = op fnvHash : string -> int
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <utility functions for string manipulation and printing>= *)
fun println  s = (print s; print "\n")
fun eprint   s = TextIO.output (TextIO.stdErr, s)
fun eprintln s = (eprint s; eprint "\n")
(* <utility functions for string manipulation and printing>= *)
fun predefinedFunctionError s =
  eprintln ("while reading predefined functions, " ^ s)
(* <utility functions for string manipulation and printing>= *)
val xprinter = ref print
fun xprint   s = !xprinter s
fun xprintln s = (xprint s; xprint "\n")
(* <utility functions for string manipulation and printing>= *)
fun tryFinally f x post =
  (f x handle e => (post (); raise e)) before post ()

fun withXprinter xp f x =
  let val oxp = !xprinter
      val ()  = xprinter := xp
  in  tryFinally f x (fn () => xprinter := oxp)
  end
(* \qbreak The printing function that is stored in *)
(* [[xprinter]] can be changed temporarily by calling *)
(* function [[withXprinter]]. This function changes *)
(* [[xprinter]] just for the duration of a call to \ *)
(* monoboxf x. To restore [[xprinter]], function *)
(* [[withXprinter]] uses [[tryFinally]], which ensures *)
(* that its [[post]] handler is always run, even if an *)
(* exception is raised.                         *)
(* <boxed values 19>=                           *)
val _ = op withXprinter : (string -> unit) -> ('a -> 'b) -> ('a -> 'b)
val _ = op tryFinally   : ('a -> 'b) -> 'a -> (unit -> unit) -> 'b
(* And the function stored in [[xprinter]] might be *)
(* [[bprint]], which ``prints'' by appending a string to *)
(* a buffer. Function [[bprinter]] returns a pair that *)
(* contains both [[bprint]] and a function used to *)
(* recover the contents of the buffer.          *)
(* <utility functions for string manipulation and printing>= *)
fun bprinter () =
  let val buffer = ref []
      fun bprint s = buffer := s :: !buffer
      fun contents () = concat (rev (!buffer))
  in  (bprint, contents)
  end
(* \qtrim2                                      *)
(*                                              *)
(* Function [[xprint]] is used by function      *)
(* [[printUTF8]], which prints a Unicode character using *)
(* the Unicode Transfer Format (UTF-8).         *)
(* <utility functions for string manipulation and printing>= *)
fun printUTF8 code =
  let val w = Word.fromInt code
      val (&, >>) = (Word.andb, Word.>>)
      infix 6 & >>
      val _ = if (w & 0wx1fffff) <> w then
                raise RuntimeError (intString code ^
                                    " does not represent a Unicode code point")
              else
                 ()
      val printbyte = xprint o str o chr o Word.toInt
      fun prefix byte byte' = Word.orb (byte, byte')
  in  if w > 0wxffff then
        app printbyte [ prefix 0wxf0  (w >> 0w18)
                      , prefix 0wx80 ((w >> 0w12) & 0wx3f)
                      , prefix 0wx80 ((w >>  0w6) & 0wx3f)
                      , prefix 0wx80 ((w      ) & 0wx3f)
                      ]
      else if w > 0wx7ff then
        app printbyte [ prefix 0wxe0  (w >> 0w12)
                      , prefix 0wx80 ((w >>  0w6) & 0wx3f)
                      , prefix 0wx80 ((w        ) & 0wx3f)
                      ]
      else if w > 0wx7f then
        app printbyte [ prefix 0wxc0  (w >>  0w6)
                      , prefix 0wx80 ((w        ) & 0wx3f)
                      ]
      else
        printbyte w
  end
(* The internal function [[kind]] computes the kind of  *)
(* [[tau]]; the environment [[Delta]] is assumed. *)
(* Function [[kind]] implements the kinding rules in the *)
(* same way that [[typeof]] implements the typing rules *)
(* and [[eval]] implements the operational semantics. *)
(*                                              *)
(* The kind of a type variable is looked up in the *)
(* environment. \usetyKindIntroVar Thanks to the parser *)
(* in \creftuschemea.parser, the name of a type variable *)
(* always begins with a quote mark, so it is distinct *)
(* from any type constructor. \tusflabelkind    *)
(* <utility functions for string manipulation and printing>= *)
fun stripNumericSuffix s =
      let fun stripPrefix []         = s   (* don't let things get empty *)
            | stripPrefix (#"-"::[]) = s
            | stripPrefix (#"-"::cs) = implode (reverse cs)
            | stripPrefix (c   ::cs) = if Char.isDigit c then stripPrefix cs
                                       else implode (reverse (c::cs))
      in  stripPrefix (reverse (explode s))
      end
(* \stdbreak                                    *)
(*                                              *)
(* Utility functions for sets, collections, and lists *)
(*                                              *)
(* Sets                                         *)
(*                                              *)
(* Quite a few analyses of programs, including a type *)
(* checker in \creftypesys.chap and the type inference *)
(* in \crefml.chap, need to manipulate sets of  *)
(* variables. In small programs, such sets are usually *)
(* small, so I provide a simple implementation that *)
(* represents a set using a list with no duplicate *)
(* elements. It's essentially the same implementation *)
(* that you see in micro-Scheme in \crefscheme.chap. [ *)
(* The~\ml~types of the set operations include type *)
(* variables with double primes, like~[[''a]]. The type *)
(* variable~[[''a]] can be instantiated only with an *)
(* ``equality type.'' Equality types include base types *)
(* like strings and integers, as well as user-defined *)
(* types that do not contain functions. Functions \emph *)
(* {cannot} be compared for equality.]          *)

(* Representing error outcomes as values        *)
(*                                              *)
(* When an error occurs, especially during evaluation, *)
(* the best and most convenient thing to do is often to *)
(* raise an ML exception, which can be caught in a *)
(* handler. But it's not always easy to put a handler *)
(* exactly where it's needed. To get the code right, it *)
(* may be better to represent an error outcome as a *)
(* value. Like any other value, such a value can be *)
(* passed and returned until it reaches a place where a *)
(* decision is made.                            *)
(*                                              *)
(*   • When representing the outcome of a unit test, an *)
(*  error means failure for [[check-expect]] but *)
(*  success for [[check-error]]. Rather than juggle *)
(*  ``exception'' versus ``non-exception,'' I treat *)
(*  both outcomes on the same footing, as values. *)
(*  Successful evaluation to produce bridge-language *)
(*  value v is represented as ML value \monoOK v. *)
(*  Evaluation that signals an error with message m *)
(*  is represented as ML value \monoERROR m.    *)
(*  Constructors [[OK]] and [[ERROR]] are the value *)
(*  constructors of the algebraic data type     *)
(*  [[error]], defined here:                    *)
(* <support for representing errors as \ml\ values>= *)
datatype 'a error = OK of 'a | ERROR of string
(* <support for representing errors as \ml\ values>= *)
infix 1 >>=
fun (OK x)      >>= k  =  k x
  | (ERROR msg) >>= k  =  ERROR msg
(* What if we have a function [[f]] that could return *)
(* an [['a]] or an error, and another function [[g]] *)
(* that expects an [['a]]? Because the expression \ *)
(* monoboxg (f x) isn't well typed, standard function *)
(* composition doesn't exactly make sense, but the idea *)
(* of composition is good. Composition just needs to *)
(* take a new form, and luckily, there's already a *)
(* standard. The standard composition relies on a *)
(* sequencing operator written [[>>=]], which uses a *)
(* special form of continuation-passing style. (The *)
(* [[>>=]] operator is traditionally called ``bind,'' *)
(* but you might wish to pronounce it ``and then.'') *)
(* The idea is to apply [[f]] to [[x]], and if the *)
(* result is [[OK y]], to continue by applying [[g]] to  *)
(* [[y]]. But if the result of applying [[(f x)]] is an *)
(* error, that error is the result of the whole *)
(* computation. The [[>>=]] operator sequences the *)
(* possibly erroneous result [[(f x)]] with the *)
(* continuation [[g]], so where we might wish to write \ *)
(* monoboxg (f x), we instead write             *)
(*                                              *)
(*  [[f x >>= g]].                              *)
(*                                              *)
(* In the definition of [[>>=]], I write the second *)
(* function as [[k]], not [[g]], because [[k]] is a *)
(* traditional metavariable for a continuation. *)
(* <boxed values 27>=                           *)
val _ = op >>= : 'a error * ('a -> 'b error) -> 'b error
(* The [[xdeftable]] is shared with the Impcore parser. *)
(* Function [[reduce_to_xdef]] is almost shareable as *)
(* well, but not quite---the abstract syntax of *)
(* [[DEFINE]] is different.                     *)

(* A very common special case occurs when the   *)
(* continuation always succeeds; that is, the   *)
(* continuation [[k']] has type \monobox'a -> 'b instead *)
(* of \monobox'a -> 'b error. In this case, the *)
(* execution plan is that when [[(f x)]] succeeds, *)
(* continue by applying [[k']] to the result; otherwise *)
(* propagate the error. I know of no standard way to *)
(* write this operator, [Haskell uses [[flip fmap]].] , *)
(* so I use [[>>=+]], which you might also choose to *)
(* pronounce ``and then.''                      *)

(* <support for representing errors as \ml\ values>= *)
infix 1 >>=+
fun e >>=+ k'  =  e >>= (OK o k')
(* <boxed values 28>=                           *)
val _ = op >>=+ : 'a error * ('a -> 'b) -> 'b error
(* <support for representing errors as \ml\ values>= *)
fun errorList es =
  let fun cons (OK x, OK xs) = OK (x :: xs)
        | cons (ERROR m1, ERROR m2) = ERROR (m1 ^ "; " ^ m2)
        | cons (ERROR m, OK _) = ERROR m
        | cons (OK _, ERROR m) = ERROR m
  in  foldr cons (OK []) es
  end
(* Sometimes I map an error-producing function over a *)
(* list of values to get a list of [['a error]] results. *)
(* Such a list is hard to work with, and the right thing *)
(* to do with it is to convert it to a single value *)
(* that's either an [['a list]] or an error. In my code, *)
(* the conversion operation is called [[errorList]]. [ *)
(* Haskell calls it [[sequence]].] It is implemented by *)
(* folding over the list of possibly erroneous results, *)
(* concatenating all error messages.            *)
(* <boxed values 29>=                           *)
val _ = op errorList : 'a error list -> 'a list error
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <support for representing errors as \ml\ values>= *)
fun errorLabel s (OK x) = OK x
  | errorLabel s (ERROR msg) = ERROR (s ^ msg)
(* A reusable read-eval-print loop              *)
(*                                              *)
(* [*] In each bridge-language interpreter, functions *)
(* [[eval]] and [[evaldef]] process expressions and true *)
(* definitions. But each interpreter also has to process *)
(* the extended definitions [[USE]] and [[TEST]], which *)
(* need more tooling:                           *)
(*                                              *)
(*   • To process a [[USE]], the interpreter must be *)
(*  able to parse definitions from a file and enter a *)
(*  read-eval-print loop recursively.           *)
(*   • To process a [[TEST]] (like [[check_expect]] or *)
(*  [[check_error]]), the interpreter must be able to *)
(*  run tests, and to run a test, it must call  *)
(*  [[eval]].                                   *)
(*                                              *)
(* Much the tooling can be shared among more than one *)
(* bridge language. To make sharing easy, I introduce *)
(* some abstraction.                            *)
(*                                              *)
(*   • Type [[basis]], which is different for each *)
(*  bridge language, stands for the collection of *)
(*  environment or environments that are used at top *)
(*  level to evaluate a definition. The name basis *)
(*  comes from The Definition of Standard ML \citep *)
(*  milner:definition-revised.                  *)
(*                                              *)
(*  For micro-Scheme, a [[basis]] is a single   *)
(*  environment that maps each name to a mutable *)
(*  location holding a value. For Impcore, a    *)
(*  [[basis]] would include both global-variable and *)
(*  function environments. And for later languages *)
(*  that have static types, a [[basis]] includes *)
(*  environments that store information about types. *)
(*   • Function [[processDef]], which is different for *)
(*  each bridge language, takes a [[def]] and a *)
(*  [[basis]] and returns an updated [[basis]]. *)
(*  For micro-Scheme, [[processDef]] just evaluates *)
(*  the definition, using [[evaldef]]. For languages *)
(*  that have static types (Typed Impcore, Typed *)
(*  uScheme, and \nml in \creftuscheme.chap,ml.chap, *)
(*  among others), [[processDef]] includes two  *)
(*  phases: type checking followed by evaluation. *)
(*                                              *)
(*  Function [[processDef]] also needs to be told *)
(*  about interaction, which has two dimensions: *)
(*  input and output. On input, an interpreter may or *)
(*  may not prompt:                             *)
(* <type [[interactivity]] plus related functions and value>= *)
datatype input_interactivity = PROMPTING | NOT_PROMPTING
(* On output, an interpreter may or may not show a *)
(* response to each definition.                 *)

(* <type [[interactivity]] plus related functions and value>= *)
datatype output_interactivity = ECHOING | NOT_ECHOING
(* <type [[interactivity]] plus related functions and value>= *)
type interactivity = 
  input_interactivity * output_interactivity
val noninteractive = 
  (NOT_PROMPTING, NOT_ECHOING)
fun prompts (PROMPTING,     _) = true
  | prompts (NOT_PROMPTING, _) = false
fun echoes (_, ECHOING)     = true
  | echoes (_, NOT_ECHOING) = false
(* The two of information together form a value of type *)
(* [[interactivity]]. Such a value can be queried by *)
(* predicates [[prompts]] and [[print]].        *)
(* <boxed values 60>=                           *)
type interactivity = interactivity
val _ = op noninteractive : interactivity
val _ = op prompts : interactivity -> bool
val _ = op echoes  : interactivity -> bool
(* <simple implementations of set operations>=  *)
type 'a set = 'a list
val emptyset = []
fun member x = 
  List.exists (fn y => y = x)
fun insert (x, ys) = 
  if member x ys then ys else x::ys
fun union (xs, ys) = foldl insert ys xs
fun inter (xs, ys) =
  List.filter (fn x => member x ys) xs
fun diff  (xs, ys) = 
  List.filter (fn x => not (member x ys)) xs
(* <boxed values 20>=                           *)
type 'a set = 'a set
val _ = op emptyset : 'a set
val _ = op member   : ''a -> ''a set -> bool
val _ = op insert   : ''a     * ''a set  -> ''a set
val _ = op union    : ''a set * ''a set  -> ''a set
val _ = op inter    : ''a set * ''a set  -> ''a set
val _ = op diff     : ''a set * ''a set  -> ''a set
(* [[bindList]] tried to                        *)
(*              extend an environment, but it passed *)
(*              two lists (names and values) of *)
(*              different lengths.              *)
(* RuntimeError    Something else went wrong during *)
(*              evaluation, i.e., during the    *)
(*              execution of [[eval]].          *)
(* \bottomrule                                  *)
(*                                              *)
(* Exceptions defined especially for this interpreter  *)
(* [*]                                          *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* Abstract syntax and values                   *)
(*                                              *)
(* An abstract-syntax tree can contain a literal value. *)
(* A value, if it is a closure, can contain an  *)
(* abstract-syntax tree. These two types are therefore *)
(* mutually recursive, so I define them together, using *)
(* [[and]].                                     *)
(*                                              *)
(* These particular types use as complicated a nest of *)
(* definitions as you'll ever see. The keyword  *)
(* [[datatype]] defines a new algebraic datatype; the *)
(* keyword [[withtype]] introduces a new type   *)
(* abbreviation that is mutually recursive with the *)
(* [[datatype]]. The first group of [[and]] keywords *)
(* define additional algebraic datatypes, and the second *)
(* group of [[and]] keywords define additional type *)
(* abbreviations. Everything in the whole nest is *)
(* mutually recursive. [*] [*]                  *)

(* <ability to interrogate environment variable [[BPCOPTIONS]]>= *)
local
  val split = String.tokens (fn c => c = #",")
  val optionTokens =
    getOpt (Option.map split (OS.Process.getEnv "BPCOPTIONS"), [])
in
  fun hasOption s = member s optionTokens
(* <boxed values 26>=                           *)
val _ = op hasOption : string -> bool
end
(* <collections with mapping and combining functions>= *)
datatype 'a collection = C of 'a set
fun elemsC (C xs) = xs
fun singleC x     = C [x]
val emptyC        = C []
(* <boxed values 21>=                           *)
type 'a collection = 'a collection
val _ = op elemsC  : 'a collection -> 'a set
val _ = op singleC : 'a -> 'a collection
val _ = op emptyC  :       'a collection
(* <collections with mapping and combining functions>= *)
fun joinC     (C xs) = C (List.concat (map elemsC xs))
fun mapC  f   (C xs) = C (map f xs)
fun filterC p (C xs) = C (List.filter p xs)
fun mapC2 f (xc, yc) = joinC (mapC (fn x => mapC (fn y => f (x, y)) yc) xc)
(* The [[collection]] type is intended to be used some *)
(* more functions that are defined below. In particular, *)
(* functions [[joinC]] and [[mapC]], together with *)
(* [[singleC]], form a monad. (If you've heard of *)
(* monads, you may know that they are a useful  *)
(* abstraction for containers and collections of all *)
(* kinds; they also have more exotic uses, such as *)
(* expressing input and output as pure functions. The  *)
(* [[collection]] type is the monad for nondeterminism, *)
(* which is to say, all possible combinations or *)
(* outcomes. If you know about monads, you may have *)
(* picked up some programming tricks you can reuse. But *)
(* you don't need to know monads to do any of the *)
(* exercises in this book.)                     *)
(*                                              *)
(* The key functions on collections are as follows: *)
(*                                              *)
(*   • Functions [[mapC]] and [[filterC]] do for *)
(*  collections what [[map]] and [[filter]] do for *)
(*  lists.                                      *)
(*   • Function [[joinC]] takes a collection of *)
(*  collections of tau's and reduces it to a single *)
(*  collection of tau's. When [[mapC]] is used with a *)
(*  function that itself returns a collection,  *)
(*  [[joinC]] usually follows, as exemplified in the *)
(*  implementation of [[mapC2]] below.          *)
(*   • Function [[mapC2]] is the most powerful of *)
(*  all—its type resembles the type of Standard ML's *)
(*  [[ListPair.map]], but it works differently: where *)
(*  [[ListPair.map]] takes elements pairwise,   *)
(*  [[mapC2]] takes all possible combinations.  *)
(*  In particular, if you give [[ListPair.map]] two *)
(*  lists containing N and M elements respectively, *)
(*  the number of elements in the result is min(N,M). *)
(*  If you give collections of size N and M to  *)
(*  [[mapC2]], the number of elements in the result *)
(*  is N\atimesM.                               *)
(*                                              *)
(* \nwnarrowboxes                               *)
(* <boxed values 22>=                           *)
val _ = op joinC   : 'a collection collection -> 'a collection
val _ = op mapC    : ('a -> 'b)      -> ('a collection -> 'b collection)
val _ = op filterC : ('a -> bool)    -> ('a collection -> 'a collection)
val _ = op mapC2   : ('a * 'b -> 'c) -> ('a collection * 'b collection -> 'c
                                                                     collection)
(* <suspensions>=                               *)
datatype 'a action
  = PENDING  of unit -> 'a
  | PRODUCED of 'a

type 'a susp = 'a action ref
(* Suspensions: repeatable access to the result of one *)
(* action                                       *)
(*                                              *)
(* Streams are built around a single abstraction: the *)
(* suspension, which is also called a thunk.    *)
(* A suspension of type [['a susp]] represents a value *)
(* of type [['a]] that is produced by an action, like *)
(* reading a line of input. The action is not performed *)
(* until the suspension's value is demanded by function *)
(* [[demand]]. [If~you're familiar with suspensions or *)
(* with lazy computation in general, you know that the *)
(* function [[demand]] is traditionally called  *)
(* [[force]]. But I~use the name [[force]] to refer to a *)
(* similar function in the \uhaskell\ interpreter, which *)
(* implements a full language around the idea of lazy *)
(* computation. It~is possible to have two functions *)
(* called [[force]]---they can coexist peacefully---but *)
(* I~think it's too confusing. So~the less important *)
(* function, which is presented here, is called *)
(* [[demand]]. Even though my \uhaskell\ chapter never *)
(* made it into the book.] The action itself is *)
(* represented by a function of type \monoboxunit -> 'a. *)
(* A suspension is created by passing an action to the *)
(* function [[delay]]; at that point, the action is *)
(* ``pending.'' If [[demand]] is never called, the *)
(* action is never performed and remains pending. The *)
(* first time [[demand]] is called, the action is *)
(* performed, and the suspension saves the result that *)
(* is produced. \stdbreak If [[demand]] is called *)
(* multiple times, the action is still performed just *)
(* once—later calls to [[demand]] don't repeat the *)
(* action; instead they return the value previously *)
(* produced.                                    *)
(*                                              *)
(* To implement suspensions, I use a standard   *)
(* combination of imperative and functional code. *)
(* A suspension is a reference to an [[action]], which *)
(* can be pending or can have produced a result. *)
(* <boxed values 36>=                           *)
type 'a susp = 'a susp
(* <suspensions>=                               *)
fun delay f = ref (PENDING f)
fun demand cell =
  case !cell
    of PENDING f =>  let val result = f ()
                     in  (cell := PRODUCED result; result)
                     end
     | PRODUCED v => v
(* \qbreak Functions [[delay]] and [[demand]] convert to *)
(* and from suspensions.                        *)
(* <boxed values 37>=                           *)
val _ = op delay  : (unit -> 'a) -> 'a susp
val _ = op demand : 'a susp -> 'a
(* Streams: results of a sequence of actions    *)
(*                                              *)
(* [*] A stream behaves much like a list, except that *)
(* the first time an element is inspected, an action *)
(* might be taken. And unlike a list, a stream can be *)
(* infinite. My code uses streams of lines, streams of *)
(* characters, streams of definitions, and even streams *)
(* of source-code locations. In this section I define *)
(* streams and many related utility functions. Most of *)
(* the utility functions are inspired by list functions *)
(* like [[map]], [[filter]], [[concat]], [[zip]], and *)
(* [[foldl]].                                   *)
(*                                              *)
(* Stream representation and basic functions    *)
(*                                              *)
(* The representation of a stream takes one of three *)
(* forms: [There are representations that use fewer *)
(* forms, but this one has the merit that I~can define a *)
(* polymorphic empty stream without running afoul of \ *)
(* ml's ``value restriction.'']                 *)
(*                                              *)
(*   • The [[EOS]] constructor represents an empty *)
(*  stream.                                     *)
(*                                              *)
(*   • The [[:::]] constructor (pronounced ``cons''), *)
(*  which should remind you of ML's [[::]]      *)
(*  constructor for lists, represents a stream in *)
(*  which an action has already been taken, and the *)
(*  first element of the stream is available (as are *)
(*  the remaining elements). Like the [[::]]    *)
(*  constructor for lists, the [[:::]] constructor is *)
(*  written as an infix operator.               *)
(*                                              *)
(*   • The [[SUSPENDED]] constructor represents a stream *)
(*  in which the action needed to produce the next *)
(*  element may not yet have been taken. Getting the *)
(*  element requires demanding a value from a   *)
(*  suspension, and if the action in the suspension *)
(*  is pending, it is performed at that time.   *)
(*                                              *)
(* [*]                                          *)
(* <streams>=                                   *)
datatype 'a stream 
  = EOS
  | :::       of 'a * 'a stream
  | SUSPENDED of 'a stream susp
infixr 3 :::
(* <streams>=                                   *)
fun streamGet EOS = NONE
  | streamGet (x ::: xs)    = SOME (x, xs)
  | streamGet (SUSPENDED s) = streamGet (demand s)
(* <streams>=                                   *)
fun streamOfList xs = 
  foldr (op :::) EOS xs
(* Even though its representation uses mutable state *)
(* (the suspension), the stream is an immutable *)
(* abstraction. [When debugging, I~sometimes violate the *)
(* abstraction and look at the state of a [[SUSPENDED]] *)
(* stream.] To observe that abstraction, call   *)
(* [[streamGet]]. This function performs whatever *)
(* actions are needed either to produce a pair holding *)
(* an element an a stream (represented as \monoSOME (x, *)
(* xs)) or to decide that the stream is empty and no *)
(* more elements can be produced (represented as *)
(* [[NONE]]).                                   *)
(* <boxed values 38>=                           *)
val _ = op streamGet : 'a stream -> ('a * 'a stream) option
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* The simplest way to create a stream is by using the *)
(* [[:::]] or [[EOS]] constructor. A stream can also be *)
(* created from a list. When such a stream is read, no *)
(* new actions are performed.                   *)
(* <boxed values 38>=                           *)
val _ = op streamOfList : 'a list -> 'a stream
(* <streams>=                                   *)
fun listOfStream xs =
  case streamGet xs
    of NONE => []
     | SOME (x, xs) => x :: listOfStream xs
(* <streams>=                                   *)
fun delayedStream action = 
  SUSPENDED (delay action)
(* Function [[listOfStream]] creates a list from a *)
(* stream. It is useful for debugging.          *)
(* <boxed values 39>=                           *)
val _ = op listOfStream : 'a stream -> 'a list
(* The more interesting streams are those that result *)
(* from actions. To help create such streams, I define *)
(* [[delayedStream]] as a convenience abbreviation for *)
(* creating a stream from one action.           *)
(* <boxed values 39>=                           *)
val _ = op delayedStream : (unit -> 'a stream) -> 'a stream
(* <streams>=                                   *)
fun streamOfEffects action =
  delayedStream (fn () => case action ()
                            of NONE   => EOS
                             | SOME a => a ::: streamOfEffects action)
(* Creating streams using actions and functions *)
(*                                              *)
(* Function [[streamOfEffects]] produces the stream of *)
(* results obtained by repeatedly performing a single *)
(* action (like reading a line of input). \stdbreak The *)
(* action must have type [[unit -> 'a option]]; the *)
(* stream performs the action repeatedly, producing a *)
(* stream of [['a]] values until performing the action *)
(* returns [[NONE]].                            *)
(* <boxed values 40>=                           *)
val _ = op streamOfEffects : (unit -> 'a option) -> 'a stream
(* Function [[streamOfEffects]] can be used to produce a *)
(* stream of lines from an input file:          *)

(* <streams>=                                   *)
type line = string
fun filelines infile = 
  streamOfEffects (fn () => TextIO.inputLine infile)
(* <boxed values 41>=                           *)
type line = line
val _ = op filelines : TextIO.instream -> line stream
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <streams>=                                   *)
fun streamRepeat x =
  delayedStream (fn () => x ::: streamRepeat x)
(* <boxed values 42>=                           *)
val _ = op streamRepeat : 'a -> 'a stream
(* The [[xdeftable]] is shared with the Impcore parser. *)
(* Function [[reduce_to_xdef]] is almost shareable as *)
(* well, but not quite---the abstract syntax of *)
(* [[DEFINE]] is different.                     *)

(* <streams>=                                   *)
fun streamOfUnfold next state =
  delayedStream
    (fn () => case next state
                of NONE => EOS
                 | SOME (a, state') => a ::: streamOfUnfold next state')
(* A more sophisticated way to produce a stream is to *)
(* use a function that depends on an evolving state of *)
(* some unknown type [['b]]. The function is applied to *)
(* a state (of type [['b]]) and may produce a pair *)
(* containing a value of type [['a]] and a new state. *)
(* Repeatedly applying the function can produce a *)
(* sequence of results of type [['a]]. This operation, *)
(* in which a function is used to expand a value into a *)
(* sequence, is the dual of the fold operation, which is *)
(* used to collapse a sequence into a value. The new *)
(* operation is therefore called unfold.        *)
(* <boxed values 43>=                           *)
val _ = op streamOfUnfold : ('b -> ('a * 'b) option) -> 'b -> 'a stream
(* Function [[streamOfUnfold]] can turn any ``get'' *)
(* function into a stream. In fact, the unfold and get *)
(* operations should obey the following algebraic law: *)
(*                                              *)
(*  streamOfUnfold streamGet xs ===xs\text.     *)
(*                                              *)
(* Another useful ``get'' function is [[(fn n => SOME *)
(* (n, n+1))]]; passing this function to        *)
(* [[streamOfUnfold]] results in an infinite stream of *)
(* increasing integers. [*]                     *)

(* <streams>=                                   *)
val naturals = 
  streamOfUnfold (fn n => SOME (n, n+1)) 0   (* 0 to infinity *)
(* <boxed values 44>=                           *)
val _ = op naturals : int stream
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* (Streams, like lists, support not only unfolding but *)
(* also folding. The fold function [[streamFold]] is *)
(* defined below in chunk [->].)                *)
(*                                              *)
(* Attaching extra actions to streams           *)
(*                                              *)
(* A stream built with [[streamOfEffects]] or   *)
(* [[filelines]] has an imperative action built in. *)
(* But in an interactive interpreter, the action of *)
(* reading a line should be preceded by another action: *)
(* printing the prompt. And deciding just what prompt to *)
(* print requires orchestrating other actions.  *)
(* One option, which I use below, is to attach an *)
(* imperative action to a ``get'' function used with *)
(* [[streamOfUnfold]]. Another option, which is *)
(* sometimes easier to understand, is to attach an *)
(* action to the stream itself. Such an action could *)
(* reasonably be performed either before or after the *)
(* action of getting an element from the stream. *)
(*                                              *)
(* Given an action [[pre]] and a stream xs, I define a *)
(* stream \monoboxpreStream (pre, xs) that adds \monobox *)
(* pre () to the action performed by the stream. Roughly *)
(* speaking,                                    *)
(*                                              *)
(*  \monostreamGet (preStream (pre, xs)) = \mono(pre *)
(*  (); streamGet xs).                          *)
(*                                              *)
(* (The equivalence is only rough because the pre action *)
(* is performed lazily, only when an action is needed to *)
(* get a value from xs.)                        *)

(* <streams>=                                   *)
fun preStream (pre, xs) = 
  streamOfUnfold (fn xs => (pre (); streamGet xs)) xs
(* It's also useful to be able to perform an action *)
(* immediately after getting an element from a stream. *)
(* In [[postStream]], I perform the action only if *)
(* [[streamGet]] succeeds. By performing the [[post]] *)
(* action only when [[streamGet]] succeeds, I make it *)
(* possible to write a [[post]] action that has access *)
(* to the element just gotten. Post-get actions are *)
(* especially useful for debugging.             *)

(* <streams>=                                   *)
fun postStream (xs, post) =
  streamOfUnfold (fn xs => case streamGet xs
                             of NONE => NONE
                              | head as SOME (x, _) => (post x; head)) xs
(* <boxed values 45>=                           *)
val _ = op preStream : (unit -> unit) * 'a stream -> 'a stream
(* <boxed values 45>=                           *)
val _ = op postStream : 'a stream * ('a -> unit) -> 'a stream
(* <streams>=                                   *)
fun streamMap f xs =
  delayedStream (fn () => case streamGet xs
                            of NONE => EOS
                             | SOME (x, xs) => f x ::: streamMap f xs)
(* <boxed values 46>=                           *)
val _ = op streamMap : ('a -> 'b) -> 'a stream -> 'b stream
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <streams>=                                   *)
fun streamFilter p xs =
  delayedStream (fn () => case streamGet xs
                            of NONE => EOS
                             | SOME (x, xs) => if p x then x ::: streamFilter p
                                                                              xs
                                               else streamFilter p xs)
(* <boxed values 47>=                           *)
val _ = op streamFilter : ('a -> bool) -> 'a stream -> 'a stream
(* <streams>=                                   *)
fun streamFold f z xs =
  case streamGet xs of NONE => z
                     | SOME (x, xs) => streamFold f (f (x, z)) xs
(* The only sensible order in which to fold the elements *)
(* of a stream is the order in which the actions are *)
(* taken and the results are produced: from left to *)
(* right. [*]                                   *)
(* <boxed values 48>=                           *)
val _ = op streamFold : ('a * 'b -> 'b) -> 'b -> 'a stream -> 'b
(* <streams>=                                   *)
fun streamZip (xs, ys) =
  delayedStream
  (fn () => case (streamGet xs, streamGet ys)
              of (SOME (x, xs), SOME (y, ys)) => (x, y) ::: streamZip (xs, ys)
               | _ => EOS)
(* <streams>=                                   *)
fun streamConcat xss =
  let fun get (xs, xss) =
        case streamGet xs
          of SOME (x, xs) => SOME (x, (xs, xss))
           | NONE => case streamGet xss
                       of SOME (xs, xss) => get (xs, xss)
                        | NONE => NONE
  in  streamOfUnfold get (EOS, xss)
  end
(* Function [[streamZip]] returns a stream that is as *)
(* long as the shorter of the two argument streams. *)
(* In particular, if [[streamZip]] is applied to a *)
(* finite stream and an infinite stream, the result is a *)
(* finite stream.                               *)
(* <boxed values 49>=                           *)
val _ = op streamZip : 'a stream * 'b stream -> ('a * 'b) stream
(* <boxed values 49>=                           *)
val _ = op streamConcat : 'a stream stream -> 'a stream
(* <streams>=                                   *)
fun streamConcatMap f xs = streamConcat (streamMap f xs)
(* In list and stream processing, [[concat]] is very *)
(* often composed with [[map f]]. The composition is *)
(* usually called [[concatMap]].                *)
(* <boxed values 50>=                           *)
val _ = op streamConcatMap : ('a -> 'b stream) -> 'a stream -> 'b stream
(* <streams>=                                   *)
infix 5 @@@
fun xs @@@ xs' = streamConcat (streamOfList [xs, xs'])
(* The code used to append two streams is much like the *)
(* code used to concatenate arbitrarily many streams. *)
(* To avoid duplicating the tricky manipulation of *)
(* states, I implement append using concatenation. *)
(* <boxed values 51>=                           *)
val _ = op @@@ : 'a stream * 'a stream -> 'a stream
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <streams>=                                   *)
fun streamTake (0, xs) = []
  | streamTake (n, xs) =
      case streamGet xs
        of SOME (x, xs) => x :: streamTake (n-1, xs)
         | NONE => []
(* Whenever I rename bound variables, for example in a *)
(* type \/\ldotsnalpha\alldottau, I have to choose new *)
(* names that don't conflict with existing names in tau *)
(* or in the environment. The easiest way to get good *)
(* names to build an infinite stream of names by using *)
(* [[streamMap]] on [[naturals]], then use      *)
(* [[streamFilter]] to choose only the good ones, and *)
(* finally to take exactly as many good names as I need *)
(* by calling [[streamTake]], which is defined here. *)
(* <boxed values 52>=                           *)
val _ = op streamTake : int * 'a stream -> 'a list
(* <streams>=                                   *)
fun streamDrop (0, xs) = xs
  | streamDrop (n, xs) =
      case streamGet xs
        of SOME (_, xs) => streamDrop (n-1, xs)
         | NONE => EOS
(* Once I've used [[streamTake]], I get the rest of the *)
(* stream with [[streamDrop]] (\chunkref        *)
(* mlinterps.chunk.use-streamDrop).             *)
(* <boxed values 53>=                           *)
val _ = op streamDrop : int * 'a stream -> 'a stream
(* <stream transformers and their combinators>= *)
type ('a, 'b) xformer = 
  'a stream -> ('b error * 'a stream) option
(* Stream transformers, which act as parsers    *)
(*                                              *)
(* The purpose of a parser is to turn streams of input *)
(* lines into streams of definitions. Intermediate *)
(* representations may include streams of characters, *)
(* tokens, types, expressions, and more. To handle all *)
(* these different kinds of streams using a single set *)
(* of operators, I define a type representing a stream *)
(* transformer. A stream transformer from A to B takes a *)
(* stream of A's as input and either succeeds, fails, or *)
(* detects an error:                            *)
(*                                              *)
(*   • If it succeeds, it consumes zero or more A's from *)
(*  the input stream and produces exactly one B. *)
(*  It returns a pair containing [[OK]] B plus  *)
(*  whatever A's were not consumed.             *)
(*   • If it fails, it returns [[NONE]].      *)
(*   • If it detects an error, it returns a pair *)
(*  containing [[ERROR]] m, where m is a message, *)
(*  plus whatever A's were not consumed.        *)
(*                                              *)
(* A stream transformer from A to B has type \monobox(A, *)
(* B) transformer.                              *)
(* <boxed values 71>=                           *)
type ('a, 'b) xformer = ('a, 'b) xformer
(* <stream transformers and their combinators>= *)
fun pure y = fn xs => SOME (OK y, xs)
(* The stream-transformer abstraction supports many, *)
(* many operations. These operations, known as parsing *)
(* combinators, have been refined by functional *)
(* programmers for over two decades, and they can be *)
(* expressed in a variety of guises. The guise I have *)
(* chosen uses notation from applicative functors and *)
(* from the ParSec parsing library.             *)
(*                                              *)
(* I begin very abstractly, by presenting combinators *)
(* that don't actually consume any inputs. The next two *)
(* sections present only ``constant'' transformers and *)
(* ``glue'' functions that build transformers from other *)
(* transformers. With those functions in place, *)
(* I proceed to real, working parsing combinators. These *)
(* combinators are split into two groups: ``universal'' *)
(* combinators that work with any stream, and   *)
(* ``parsing'' combinators that expect a stream of *)
(* tokens with source-code locations.           *)
(*                                              *)
(* My design includes a lot of combinators. Too many, *)
(* really. I would love to simplify the design, but *)
(* simplifying software can be hard, and I don't want to *)
(* delay the book by another year.              *)
(*                                              *)
(* --- #2                                       *)
(* \newskip\myskip \myskip=4pt                  *)
(*                                              *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(* \catcode`=\other \catcode`_=\other \catcode`$=\other *)
(*                                              *)
(*  Stream transformers; applying functions to  *)
(*  transformers                                *)
(*  \type('a, 'b) xformer \                     *)
(*  tableboxpure : 'b -> ('a, 'b)               *)
(*  xformer \splitbox<*>('a, 'b ->              *)
(*  'c) xformer * ('a, 'b)                      *)
(*  xformer-> ('a, 'c) xformer \                *)
(*  tablebox<> : ('b -> 'c) * ('a,              *)
(*  'b) xformer -> ('a, 'c)                     *)
(*  xformer \tablebox<>? : ('b ->               *)
(*  'c option) * ('a, 'b) xformer               *)
(*  -> ('a, 'c) xformer \splitbox               *)
(*  <*>!('a, 'b -> 'c error)                    *)
(*  xformer * ('a, 'b) xformer->                *)
(*  ('a, 'c) xformer \tablebox<>!               *)
(*  : ('b -> 'c error) * ('a, 'b)               *)
(*  xformer -> ('a, 'c) xformer                 *)
(*  [8pt] Functions useful with                 *)
(*  [[<>]] and [[<*>]]                          *)
(*  \tableboxfst : ('a * 'b) -> 'a              *)
(*  \tableboxsnd : ('a * 'b) -> 'b              *)
(*  \tableboxpair : 'a -> 'b -> 'a              *)
(*  * 'b \tableboxcurry : ('a * 'b              *)
(*  -> 'c) -> ('a -> 'b -> 'c) \                *)
(*  tableboxcurry3 : ('a * 'b * 'c              *)
(*  -> 'd) -> ('a -> 'b -> 'c ->                *)
(*  'd) [8pt] Combining                         *)
(*  transformers in sequence,                   *)
(*  alternation, or conjunction                 *)
(*  \tablebox<* : ('a, 'b) xformer >]] : ('a, 'b) *)
(*  * ('a, 'c) xformer -> ('a, 'b) xformer * ('a, 'c) *)
(*  xformer \tablebox *> : ('a,    xformer -> ('a, *)
(*  'b) xformer * ('a, 'c) xformer 'c) xformer [8pt] *)
(*  -> ('a, 'c) xformer \tablebox< Transformers *)
(*  : 'b * ('a, 'c) xformer ->     useful for both *)
(*  ('a, 'b) xformer \tablebox<|>  lexical analysis *)
(*  : ('a, 'b) xformer * ('a, 'b)  and parsing  *)
(*  xformer -> ('a, 'b) xformer \               *)
(*  tableboxpzero : ('a, 'b)                    *)
(*  xformer \tableboxanyParser :                *)
(*  ('a, 'b) xformer list -> ('a,               *)
(*  'b) xformer \tablebox[[<                    *)
(*  \tableboxone : ('a, 'a)                     *)
(*  xformer \tableboxeos : ('a,                 *)
(*  unit) xformer \tableboxsat :                *)
(*  ('b -> bool) -> ('a, 'b)                    *)
(*  xformer -> ('a, 'b) xformer \               *)
(*  tableboxeqx : ''b -> ('a, ''b)              *)
(*  xformer -> ('a, ''b) xformer                *)
(*  notFollowedBy                               *)
(*                                 ('a, 'b) xformer *)
(*                                 -> ('a, unit) *)
(*                                 xformer      *)
(*  \tableboxmany : ('a, 'b)                    *)
(*  xformer -> ('a, 'b list)                    *)
(*  xformer \tableboxmany1 : ('a,               *)
(*  'b) xformer -> ('a, 'b list)                *)
(*  xformer \tableboxoptional :                 *)
(*  ('a, 'b) xformer -> ('a, 'b                 *)
(*  option) xformer \tableboxpeek               *)
(*  : ('a, 'b) xformer -> 'a                    *)
(*  stream -> 'b option \tablebox               *)
(*  rewind : ('a, 'b) xformer ->                *)
(*  ('a, 'b) xformer                            *)
(*                                              *)
(* Stream transformers and their combinators [*] *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* Error-free transformers and their composition *)
(*                                              *)
(* The [[pure]] combinator takes a value [[y]] of type B *)
(* as argument. It returns an \atob transformer that *)
(* consumes no A's as input and produces [[y]]. *)
(* <boxed values 72>=                           *)
val _ = op pure : 'b -> ('a, 'b) xformer
(* <stream transformers and their combinators>= *)
infix 3 <*>
fun tx_f <*> tx_b =
  fn xs => case tx_f xs
             of NONE => NONE
              | SOME (ERROR msg, xs) => SOME (ERROR msg, xs)
              | SOME (OK f, xs) =>
                  case tx_b xs
                    of NONE => NONE
                     | SOME (ERROR msg, xs) => SOME (ERROR msg, xs)
                     | SOME (OK y, xs) => SOME (OK (f y), xs)
(* To build a stream transformer that reads inputs in *)
(* sequence, I compose smaller stream transformers that *)
(* read parts of the input. The sequential composition *)
(* operator may look quite strange. To compose [[tx_f]] *)
(* and [[tx_b]] in sequence, I use the infix operator *)
(* [[<*>]], which is pronounced ``applied to.'' The *)
(* composition is written \monobox[[tx_f]] <*> [[tx_b]], *)
(* and it works like this:                      *)
(*                                              *)
(*  1. First [[tx_f]] reads some A's and produces a *)
(*  function [[f]] of type B -->C.              *)
(*  2. Next [[tx_b]] reads some more A's and produces a *)
(*  value [[y]] of type B.                      *)
(*  3. The combination [[tx_f <*> tx_b]] reads no more *)
(*  input but simply applies [[f]] to [[y]] and *)
(*  returns \monoboxf y (of type C) as its result. *)
(*                                              *)
(* This idea may seem crazy. How can reading a sequence *)
(* of A's produce a function? The secret is that almost *)
(* always, the function is produced by [[pure]], without *)
(* actually reading any A's, or it's the result of using *)
(* the [[<*>]] operator to apply a Curried function to *)
(* its first argument. But the                  *)
(* read-and-produce-a-function idiom is a great way to *)
(* do business, because when the parser is written using *)
(* the [[pure]] and [[<*>]] combinators, the code *)
(* resembles a Curried function application.    *)
(*                                              *)
(* For the combination [[tx_f <*> tx_b]] to succeed, *)
(* both [[tx_f]] and [[tx_b]] must succeed. Ensuring *)
(* that two transformers succeed requires a nested case *)
(* analysis.                                    *)
(* <boxed values 73>=                           *)
val _ = op <*> : ('a, 'b -> 'c) xformer * ('a, 'b) xformer -> ('a, 'c) xformer
(* <stream transformers and their combinators>= *)
infixr 4 <$>
fun f <$> p = pure f <*> p
(* The common case of creating [[tx_f]] using [[pure]] *)
(* is normally written using the special operator [[< *)
(* >]], which is also pronounced ``applied to.'' *)
(* It combines a B-to-C function with an \atob  *)
(* transformer to produce an \atoc transformer. *)
(* <boxed values 74>=                           *)
val _ = op <$> : ('b -> 'c) * ('a, 'b) xformer -> ('a, 'c) xformer
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <stream transformers and their combinators>= *)
infix 1 <|>
fun t1 <|> t2 = (fn xs => case t1 xs of SOME y => SOME y | NONE => t2 xs) 
(* <boxed values 76>=                           *)
val _ = op <|> : ('a, 'b) xformer * ('a, 'b) xformer -> ('a, 'b) xformer
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* I sometimes want to combine a list of parsers with *)
(* the choice operator. I can do this by folding over *)
(* the list, provided I have a ``zero'' parser, which *)
(* always fails.                                *)

(* <stream transformers and their combinators>= *)
fun pzero _ = NONE
(* <stream transformers and their combinators>= *)
fun anyParser ts = 
  foldr op <|> pzero ts
(* <boxed values 77>=                           *)
val _ = op pzero : ('a, 'b) xformer
(* This parser obeys the algebraic law          *)
(*                                              *)
(*  \monoboxt <|> pzero = \monoboxpzero <|> t = \ *)
(*  monoboxt\text.                              *)
(*                                              *)
(* Because building choices from lists is common, *)
(* I implement this special case as [[anyParser]]. *)
(* <boxed values 77>=                           *)
val _ = op anyParser : ('a, 'b) xformer list -> ('a, 'b) xformer
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <stream transformers and their combinators>= *)
infix 6 <* *>
fun p1 <*  p2 = curry fst <$> p1 <*> p2
fun p1  *> p2 = curry snd <$> p1 <*> p2

infixr 4 <$
fun v <$ p = (fn _ => v) <$> p
(* Ignoring results produced by transformers    *)
(*                                              *)
(* If a parser sees the stream of tokens {indented} *)
(* [[(]]                                        *)
(* [[if]]                                       *)
(* [[(]]                                        *)
(* [[<]]                                        *)
(* [[x]]                                        *)
(* [[y]]                                        *)
(* [[)]]                                        *)
(* [[x]]                                        *)
(* [[y]]                                        *)
(* [[)]] , {indented} I want it to build an     *)
(* abstract-syntax tree using [[IFX]] and three *)
(* expressions. The parentheses and keyword [[if]] serve *)
(* to identify the [[if]]-expression and to make sure it *)
(* is well formed, so the parser does have to read them *)
(* from the input, but it doesn't need to do anything *)
(* with the results that are produced. Using a parser *)
(* and then ignoring the result is such a common *)
(* operation that special abbreviations have evolved to *)
(* support it.                                  *)
(*                                              *)
(* The abbreviations are formed by modifying the [[<*>]] *)
(* or [[<>]] operator to remove the angle bracket on the *)
(* side containing the result to be ignored. For *)
(* example,                                     *)
(*                                              *)
(*   • Parser [[p1 <* p2]] reads the input of [[p1]] and *)
(*  then the input of [[p2]], but it returns only the *)
(*  result of [[p1]].                           *)
(*   • Parser [[p1 *> p2]] reads the input of [[p1]] and *)
(*  then the input of [[p2]], but it returns only the *)
(*  result of [[p2]].                           *)
(*   • Parser [[v < p]] parses the input the way [[p]] *)
(*   does, but it then ignores [[p]]'s result and *)
(*  instead produces the value [[v]].           *)
(*                                              *)
(* <boxed values 78>=                           *)
val _ = op <*  : ('a, 'b) xformer * ('a, 'c) xformer -> ('a, 'b) xformer
val _ = op  *> : ('a, 'b) xformer * ('a, 'c) xformer -> ('a, 'c) xformer
val _ = op <$  : 'b               * ('a, 'c) xformer -> ('a, 'b) xformer
(* <stream transformers and their combinators>= *)
fun one xs = case streamGet xs
               of NONE => NONE
                | SOME (x, xs) => SOME (OK x, xs)
(* At last, transformers that look at the input stream *)
(*                                              *)
(* None of the transformers above inspects an input *)
(* stream. The fundamental operations are [[pure]], *)
(* [[<*>]], and [[<|>]]; [[pure]] never looks at the *)
(* input, and [[<*>]] and [[<|>]] simply sequence or *)
(* alternate between other parsers which do the actual *)
(* looking. Those parsers are up next.          *)
(*                                              *)
(* The simplest input-inspecting parser is [[one]]. It's *)
(* an \atoa transformer that succeeds if and only if *)
(* there is a value in the input. If there's no value in *)
(* the input, [[one]] fails; it never signals an error. *)
(* <boxed values 79>=                           *)
val _ = op one : ('a, 'a) xformer
(* <stream transformers and their combinators>= *)
fun eos xs = case streamGet xs
               of NONE => SOME (OK (), EOS)
                | SOME _ => NONE
(* <boxed values 80>=                           *)
val _ = op eos : ('a, unit) xformer
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* Perhaps surprisingly, these are the only two standard *)
(* parsers that inspect input. The only other parsing *)
(* combinator that looks directly at input is the *)
(* function [[stripAndReportErrors]], which removes *)
(* [[ERROR]] and [[OK]] from error streams.     *)

(* <stream transformers and their combinators>= *)
fun peek tx xs =
  case tx xs of SOME (OK y, _) => SOME y
              | _ => NONE
(* It is sometimes useful to look at input without *)
(* consuming it. For this purpose I define two  *)
(* functions: [[peek]] just looks at a transformed *)
(* stream and maybe produces a value, whereas [[rewind]] *)
(* changes any transformer into a transformer that *)
(* behaves identically, but that doesn't consume any *)
(* input. I use these functions either to debug, or to *)
(* find the source-code location of the next token in a *)
(* token stream.                                *)
(* <boxed values 81>=                           *)
val _ = op peek : ('a, 'b) xformer -> 'a stream -> 'b option
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <stream transformers and their combinators>= *)
fun rewind tx xs =
  case tx xs of SOME (ey, _) => SOME (ey, xs)
              | NONE => NONE
(* Given a transformer [[tx]], transformer \monobox *)
(* rewind tx computes the same value as [[tx]], but when *)
(* it's done, it rewinds the input stream back to where *)
(* it was before it ran [[tx]]. The actions performed by *)
(* [[tx]] can't be undone, but the inputs can be read *)
(* again.                                       *)
(* <boxed values 82>=                           *)
val _ = op rewind : ('a, 'b) xformer -> ('a, 'b) xformer
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <stream transformers and their combinators>= *)
fun sat p tx xs =
  case tx xs
    of answer as SOME (OK y, xs) => if p y then answer else NONE
     | answer => answer
(* <boxed values 83>=                           *)
val _ = op sat : ('b -> bool) -> ('a, 'b) xformer -> ('a, 'b) xformer
(* <stream transformers and their combinators>= *)
fun eqx y = 
  sat (fn y' => y = y') 
(* Transformer [[eqx b]] is [[sat]] specialized to an *)
(* equality predicate. It is typically used to recognize *)
(* special characters like keywords and minus signs. *)
(* <boxed values 84>=                           *)
val _ = op eqx : ''b -> ('a, ''b) xformer -> ('a, ''b) xformer
(* The [[xdeftable]] is shared with the Impcore parser. *)
(* Function [[reduce_to_xdef]] is almost shareable as *)
(* well, but not quite---the abstract syntax of *)
(* [[DEFINE]] is different.                     *)

(* <stream transformers and their combinators>= *)
infixr 4 <$>?
fun f <$>? tx =
  fn xs => case tx xs
             of NONE => NONE
              | SOME (ERROR msg, xs) => SOME (ERROR msg, xs)
              | SOME (OK y, xs) =>
                  case f y
                    of NONE => NONE
                     | SOME z => SOME (OK z, xs)
(* A predicate of type \monobox('b -> bool) asks, ``Is *)
(* this a thing?'' But sometimes code wants to ask, ``Is *)
(* this a thing, and if so, what thing is it?'' *)
(* For example, a parser for Impcore or micro-Scheme *)
(* will want to know if an atom represents a numeric *)
(* literal, but if so, it would also like to know what *)
(* number is represented. Instead of a predicate, the *)
(* parser would use a function of type \monoboxatom -> *)
(* int option. In general, an \atob transformer can be *)
(* composed with a function of type \monoboxB -> C *)
(* option, and the result is an \atoxC transformer. *)
(* Because there's a close analogy with the application *)
(* operator [[<>]], I notate the composition operator as *)
(* [[<>?]], with a question mark.               *)
(* <boxed values 85>=                           *)
val _ = op <$>? : ('b -> 'c option) * ('a, 'b) xformer -> ('a, 'c) xformer
(* <stream transformers and their combinators>= *)
infix 3 <&>
fun t1 <&> t2 = fn xs =>
  case t1 xs
    of SOME (OK _, _) => t2 xs
     | SOME (ERROR _, _) => NONE    
     | NONE => NONE
(* Transformer \monoboxf [[<>?]] tx can be defined as \ *)
(* monoboxvalOf [[<>]] sat isSome (f [[<>]] tx), but *)
(* writing out the cases helps clarify what's going on. *)
(*                                              *)
(* A transformer might be run only if a another *)
(* transformer succeeds on the same input. For example, *)
(* the parser for uSmalltalk tries to parse an array *)
(* literal only when it knows the input begins with a *)
(* left bracket. Transformer \monoboxt1 [[< --- >]] t2 *)
(* succeeds only if both [[t1]] and [[t2]] succeed at *)
(* the same point. An error in [[t1]] is treated as *)
(* failure. The combined transformer looks at enough *)
(* input to decide if [[t1]] succeeds, but it does not *)
(* consume input consumed by [[t1]]—it consumes only the *)
(* input of [[t2]].                             *)
(* <boxed values 86>=                           *)
val _ = op <&> : ('a, 'b) xformer * ('a, 'c) xformer -> ('a, 'c) xformer
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <stream transformers and their combinators>= *)
fun notFollowedBy t xs =
  case t xs
    of NONE => SOME (OK (), xs)
     | SOME _ => NONE
(* <boxed values 87>=                           *)
val _ = op notFollowedBy : ('a, 'b) xformer -> ('a, unit) xformer
(* <stream transformers and their combinators>= *)
fun many t = 
  curry (op ::) <$> t <*> (fn xs => many t xs) <|> pure []
(* Adding [[< --- >]] and [[notFollowedBy]] to our *)
(* library gives it the flavor of a little Boolean *)
(* algebra for transformers: functions [[< --- >]], *)
(* [[<|>]], and [[notFollowedBy]] play the roles of *)
(* ``and,'' ``or,'' and ``not,'' and [[pzero]] plays the *)
(* role of ``false.''                           *)
(*                                              *)
(* Transformers for sequences                   *)
(*                                              *)
(* Concrete syntax is full of sequences. A function *)
(* takes a sequence of arguments, a program is a *)
(* sequence of definitions, and a method definition *)
(* contains a sequence of expressions. To create *)
(* transformers that process sequences, I define *)
(* functions [[many]] and [[many1]]. If [[t]] is an \ *)
(* atob transformer, then \monoboxmany t is an \atox *)
(* list-of-B transformer. It runs [[t]] as many times as *)
(* possible. And even if [[t]] fails, \monoboxmany t *)
(* always succeeds: when [[t]] fails, \monoboxmany t *)
(* returns an empty list of B's.                *)
(* <boxed values 88>=                           *)
val _ = op many  : ('a, 'b) xformer -> ('a, 'b list) xformer
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* I'd really like to write that first alternative as *)
(*                                              *)
(*  [[curry (op ::) <> t <*> many t]]           *)
(*                                              *)
(* but that formulation leads to instant death by *)
(* infinite recursion. In your own parsers, it's a *)
(* problem to watch out for.                    *)
(*                                              *)
(* Sometimes an empty list isn't acceptable. In such *)
(* cases, I use \monoboxmany1 t, which succeeds only if *)
(* [[t]] succeeds at least once—in which case it returns *)
(* a nonempty list.                             *)

(* <stream transformers and their combinators>= *)
fun many1 t = 
  curry (op ::) <$> t <*> many t
(* <boxed values 89>=                           *)
val _ = op many1 : ('a, 'b) xformer -> ('a, 'b list) xformer
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* Although \monoboxmany t always succeeds, \monobox *)
(* many1 t can fail.                            *)

(* <stream transformers and their combinators>= *)
fun optional t = 
  SOME <$> t <|> pure NONE
(* Both [[many]] and [[many1]] are ``greedy''; that is, *)
(* they repeat [[t]] as many times as possible. Client *)
(* code has to be careful to ensure that calls to *)
(* [[many]] and [[many1]] terminate. In particular, if *)
(* [[t]] can succeed without consuming any input, then \ *)
(* monoboxmany t does not terminate. To pass [[many]] a *)
(* transformer that succeeds without consuming input is *)
(* therefor an unchecked run-time error. The same goes *)
(* for [[many1]].                               *)
(*                                              *)
(* Client code also has to be careful that when [[t]] *)
(* sees something it doesn't recognize, it doesn't *)
(* signal an error. In particular, [[t]] had better not *)
(* be built with the [[<?>]] operator defined in \ *)
(* chunkrefmlinterps.chunk.<?> below.           *)
(*                                              *)
(* Sometimes instead of zero, one, or many B's, concrete *)
(* syntax calls for zero or one; such a B might be *)
(* called ``optional.'' For example, a numeric literal *)
(* begins with an optional minus sign. Function *)
(* [[optional]] turns an \atob transformer into an \atox *)
(* optional-B transformer. Like \monoboxmany t, \monobox *)
(* optional t always succeeds.                  *)
(* <boxed values 90>=                           *)
val _ = op optional : ('a, 'b) xformer -> ('a, 'b option) xformer
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <stream transformers and their combinators>= *)
infix 2 <*>!
fun tx_ef <*>! tx_x =
  fn xs => case (tx_ef <*> tx_x) xs
             of NONE => NONE
              | SOME (OK (OK y),      xs) => SOME (OK y,      xs)
              | SOME (OK (ERROR msg), xs) => SOME (ERROR msg, xs)
              | SOME (ERROR msg,      xs) => SOME (ERROR msg, xs)
infixr 4 <$>!
fun ef <$>! tx_x = pure ef <*>! tx_x
(* Transformers made with [[many]] and [[optional]] *)
(* succeed even when there is no input. They also *)
(* succeed when there is input that they don't  *)
(* recognize.                                   *)
(*                                              *)
(* Error-detecting transformers and their composition *)
(*                                              *)
(* Sometimes an error is detected not by a parser but by *)
(* a function that is applied to the results of parsing. *)
(* A classic example is a function definition: if the *)
(* formal parameters are syntactically correct but *)
(* contain a duplicate name, an error should be *)
(* signaled. Formal parameters could be handled by a *)
(* parser whose result type is \monoboxname list *)
(* error—but every transformer type already includes the *)
(* possibility of error! I would prefer that the *)
(* parser's result type be just \monoboxname list, and *)
(* that if duplicate names are detected, that the error *)
(* be managed in the same way as a syntax error. *)
(* To enable such management, I define [[<*>!]] and [[< *)
(* >!]] combinators, which merge function-detected *)
(* errors with parser-detected errors. \nwnarrowboxes *)
(* <boxed values 91>=                           *)
val _ = op <*>! : ('a, 'b -> 'c error) xformer * ('a, 'b) xformer -> ('a, 'c)
                                                                         xformer
val _ = op <$>! : ('b -> 'c error)                 * ('a, 'b) xformer -> ('a, 'c
                                                                       ) xformer
(* <support for source-code locations and located streams>= *)
type srcloc = string * int
fun srclocString (source, line) =
  source ^ ", line " ^ intString line
(* Source-code locations are useful when reading code *)
(* from a file. When reading code interactively, *)
(* however, a message that says the error occurred ``in *)
(* standard input, line 12,'' is more annoying than *)
(* helpful. As in the C code in \crefpage       *)
(* (cinterps.error-format, I use an error format to *)
(* control when error messages include source-code *)
(* locations. The format is initially set to include *)
(* them. [*]                                    *)
(* <support for source-code locations and located streams>= *)
datatype error_format = WITH_LOCATIONS | WITHOUT_LOCATIONS
val toplevel_error_format = ref WITH_LOCATIONS
(* The format is consulted by function [[synerrormsg]], *)
(* which produces the message that accompanies a syntax *)
(* error. The source location may be omitted only for *)
(* standard input; error messages about files loaded *)
(* with [[use]] are always accompanied by source-code *)
(* locations.                                   *)
(* <support for source-code locations and located streams>= *)
fun synerrormsg (source, line) strings =
  if !toplevel_error_format = WITHOUT_LOCATIONS
  andalso source = "standard input"
  then
    concat ("syntax error: " :: strings)
  else    
    concat ("syntax error in " :: srclocString (source, line) :: ": " :: strings
                                                                               )

(* <support for source-code locations and located streams>= *)
fun warnAt (source, line) strings =
  ( app eprint
      (if !toplevel_error_format = WITHOUT_LOCATIONS
       andalso source = "standard input"
       then
         "warning: " :: strings
       else
         "warning in " :: srclocString (source, line) :: ": " :: strings)
  ; eprint "\n"
  )
(* Parsing bindings used in LETX forms          *)
(*                                              *)
(* A sequence of let bindings has both names and *)
(* expressions. To capture both, [[parseletbindings]] *)
(* returns a component with both [[names]] and [[exps]] *)
(* fields set.                                  *)
(* <support for source-code locations and located streams>= *)
exception Located of srcloc * exn
(* <support for source-code locations and located streams>= *)
type 'a located = srcloc * 'a
(* <boxed values 55>=                           *)
type srcloc = srcloc
val _ = op srclocString : srcloc -> string
(* To keep track of the source location of a line, *)
(* token, expression, or other datum, I put the location *)
(* and the datum together in a pair. To make it easier *)
(* to read the types, I define a type abbreviation which *)
(* says that a value paired with a location is  *)
(* ``located.''                                 *)
(* <boxed values 55>=                           *)
type 'a located = 'a located
(* <support for source-code locations and located streams>= *)
fun atLoc loc f a =
  f a handle e as RuntimeError _ => raise Located (loc, e)
           | e as NotFound _     => raise Located (loc, e)
           (* In addition to exceptions that I have defined, *)
           (* [[atLoc]] also recognizes and wraps some of Standard *)
           (* ML's predefined exceptions. Handlers for even more *)
           (* exceptions, like [[TypeError]], can be added using *)
           (* Noweb.                                       *)
           (* <more handlers for [[atLoc]]>=               *)
           | e as IO.Io _   => raise Located (loc, e)
           | e as Div       => raise Located (loc, e)
           | e as Overflow  => raise Located (loc, e)
           | e as Subscript => raise Located (loc, e)
           | e as Size      => raise Located (loc, e)
(* The [[Located]] exception is raised by function *)
(* [[atLoc]]. Calling \monoboxatLoc f x applies [[f]] *)
(* to [[x]] within the scope of handlers that convert *)
(* recognized exceptions to the [[Located]] exception: *)
(* <boxed values 56>=                           *)
val _ = op atLoc : srcloc -> ('a -> 'b) -> ('a -> 'b)
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <support for source-code locations and located streams>= *)
fun located f (loc, a) = atLoc loc f a
fun leftLocated f ((loc, a), b) = atLoc loc f (a, b)
(* Function [[atLoc]] is often called by the    *)
(* higher-order function [[located]], which converts a *)
(* function that expects [['a]] into a function that *)
(* expects \monobox'a located. Function [[leftLocated]] *)
(* does something similar for a pair in which only the *)
(* left half must include a source-code location. *)
(* <boxed values 57>=                           *)
val _ = op located : ('a -> 'b) -> ('a located -> 'b)
val _ = op leftLocated : ('a * 'b -> 'c) -> ('a located * 'b -> 'c)
(* [[bindList]] tried to                        *)
(*              extend an environment, but it passed *)
(*              two lists (names and values) of *)
(*              different lengths.              *)
(* RuntimeError    Something else went wrong during *)
(*              evaluation, i.e., during the    *)
(*              execution of [[eval]].          *)
(* \bottomrule                                  *)
(*                                              *)
(* Exceptions defined especially for this interpreter  *)
(* [*]                                          *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* Abstract syntax and values                   *)
(*                                              *)
(* An abstract-syntax tree can contain a literal value. *)
(* A value, if it is a closure, can contain an  *)
(* abstract-syntax tree. These two types are therefore *)
(* mutually recursive, so I define them together, using *)
(* [[and]].                                     *)
(*                                              *)
(* These particular types use as complicated a nest of *)
(* definitions as you'll ever see. The keyword  *)
(* [[datatype]] defines a new algebraic datatype; the *)
(* keyword [[withtype]] introduces a new type   *)
(* abbreviation that is mutually recursive with the *)
(* [[datatype]]. The first group of [[and]] keywords *)
(* define additional algebraic datatypes, and the second *)
(* group of [[and]] keywords define additional type *)
(* abbreviations. Everything in the whole nest is *)
(* mutually recursive. [*] [*]                  *)

(* <support for source-code locations and located streams>= *)
fun fillComplaintTemplate (s, maybeLoc) =
  let val string_to_fill = " <at loc>"
      val (prefix, atloc) =
        Substring.position string_to_fill (Substring.full s)
      val suffix = Substring.triml (size string_to_fill) atloc
      val splice_in =
        Substring.full
          (case maybeLoc
             of NONE => ""
              | SOME (loc as (file, line)) =>
                  if !toplevel_error_format = WITHOUT_LOCATIONS
                  andalso file = "standard input"
                  then
                    ""
                  else
                    " in " ^ srclocString loc)
  in  if Substring.size atloc = 0 then (* <at loc> is not present *)
        s
      else
        Substring.concat [prefix, splice_in, suffix]
  end
fun fillAtLoc (s, loc) = fillComplaintTemplate (s, SOME loc)
fun stripAtLoc s = fillComplaintTemplate (s, NONE)
(* \qbreak A source-code location can appear anywhere in *)
(* an error message. To make it easy to write error *)
(* messages that include source-code locations, I define *)
(* function [[fillComplaintTemplate]]. This function *)
(* replaces the string \monobox"<at loc>" with a *)
(* reference to a source-code location—or if there is no *)
(* source-code location, it strips \monobox"<at loc>" *)
(* entirely. The implementation uses Standard ML's *)
(* [[Substring]] module.                        *)
(* <boxed values 58>=                           *)
val _ = op fillComplaintTemplate : string * srcloc option -> string
(* <support for source-code locations and located streams>= *)
fun synerrorAt msg loc = 
  ERROR (synerrormsg loc [msg])
(* <support for source-code locations and located streams>= *)
fun locatedStream (streamname, inputs) =
  let val locations =
        streamZip (streamRepeat streamname, streamDrop (1, naturals))
  in  streamZip (locations, inputs)
  end
(* To signal a syntax error at a given location, code *)
(* calls [[synerrorAt]]. [*]                    *)
(* <boxed values 59>=                           *)
val _ = op synerrorAt : string -> srcloc -> 'a error
(* All locations originate in a located stream of lines. *)
(* The locations share a filename, and the line numbers *)
(* are 1, 2, 3, ... and so on. [*]              *)
(* <boxed values 59>=                           *)
val _ = op locatedStream : string * line stream -> line located stream
(* <streams that track line boundaries>=        *)
datatype 'a eol_marked
  = EOL of int (* number of the line that ends here *)
  | INLINE of 'a

fun drainLine EOS = EOS
  | drainLine (SUSPENDED s)     = drainLine (demand s)
  | drainLine (EOL _    ::: xs) = xs
  | drainLine (INLINE _ ::: xs) = drainLine xs
(* <streams that track line boundaries>=        *)
local 
  fun asEol (EOL n) = SOME n
    | asEol (INLINE _) = NONE
  fun asInline (INLINE x) = SOME x
    | asInline (EOL _)    = NONE
in
  fun eol    xs = (asEol    <$>? one) xs
  fun inline xs = (asInline <$>? many eol *> one) xs
  fun srcloc xs = rewind (fst <$> inline) xs
end
(* Parsers: reading tokens and source-code locations *)
(*                                              *)
(* [*] To read definitions, expressions, and types, *)
(* it helps to work at a higher level of abstraction *)
(* than individual characters. All the parsers in this *)
(* book use two stages: first a lexer groups characters *)
(* into tokens, then a parser transforms tokens into *)
(* syntax. Not all languages use the same tokens, so the *)
(* code in this section assumes that the type [[token]] *)
(* and function [[tokenString]] are defined. Function *)
(* [[tokenString]] returns a string representation of *)
(* any given token; it is used in debugging. As an *)
(* example, the definitions used in micro-Scheme appear *)
(* in \crefmlschemea.chap (\cpagerefmlschemea.tokens). *)
(*                                              *)
(* Transforming a stream of characters to a stream of *)
(* tokens to a stream of definitions should sound *)
(* appealing, but it simplifies the story a little too *)
(* much. \qbreak That's because if something goes wrong, *)
(* a parser can't just throw up its hands. If an error *)
(* occurs,                                      *)
(*                                              *)
(*   • The parser should say where things went wrong—at *)
(*  what source-code location.                  *)
(*   • The parser should get rid of the bad tokens that *)
(*  caused the error.                           *)
(*   • The parser should be able to keep going, without *)
(*  having to kill the interpreter and start over. *)
(*                                              *)
(* To support error reporting and recovery takes a lot *)
(* of machinery. And that means a parser's input has to *)
(* contain more than just tokens.               *)
(*                                              *)
(* Flushing bad tokens                          *)
(*                                              *)
(* A standard parser for a batch compiler needs only to *)
(* see a stream of tokens and to know from what *)
(* source-code location each token came. A batch *)
(* compiler can simply read all its input and report all *)
(* the errors it wants to report. [Batch compilers vary *)
(* widely in the ambitions of their parsers. Some simple *)
(* parsers report just one error and stop. Some *)
(* sophisticated parsers analyze the entire input and *)
(* report the smallest number of changes needed to make *)
(* the input syntactically correct. And some    *)
(* ill-mannered parsers become confused after an error *)
(* and start spraying meaningless error messages. But *)
(* all of them have access to the entire input. *)
(* The~bridge-language interpreters don't. ] But an *)
(* interactive interpreter may not use an error as an *)
(* excuse to read an indefinite amount of input. It must *)
(* instead recover from the error and ready itself to *)
(* read the next line. To do so, it needs to know where *)
(* the line boundaries are! For example, if a parser *)
(* finds an error on line 6, it should read all the *)
(* tokens on line 6, throw them away, and start over *)
(* again on line 7. And it should do this without *)
(* reading line 7—reading line 7 will take an action and *)
(* will likely have the side effect of printing a *)
(* prompt. To mark line boundaries, I define a new type *)
(* constructor [[eol_marked]]. A value of type \monobox *)
(* 'a [[eol_marked]] is either an end-of-line marker, or *)
(* it contains a value of type [['a]] that occurs in a *)
(* line. A stream of such values can be drained up to *)
(* the end of the line.                         *)
(* <boxed values 100>=                          *)
type 'a eol_marked = 'a eol_marked
val _ = op drainLine : 'a eol_marked stream -> 'a eol_marked stream
(* \qbreak To support a stream of marked lines—possibly *)
(* marked, located lines—I define transformers [[eol]], *)
(* [[inline]], and [[srcloc]]. The [[eol]] transformer *)
(* returns the number of the line just ended.   *)
(* <boxed values 100>=                          *)
val _ = op eol      : ('a eol_marked, int) xformer
val _ = op inline   : ('a eol_marked, 'a)  xformer
val _ = op srcloc   : ('a located eol_marked, srcloc) xformer
(* <support for lexical analysis>=              *)
type 'a lexer = (char, 'a) xformer
(* <boxed values 92>=                           *)
type 'a lexer = 'a lexer
(* The type [['a lexer]] should be pronounced ``lexer *)
(* returning [['a]].''                          *)

(* <support for lexical analysis>=              *)
fun isDelim c =
  Char.isSpace c orelse Char.contains "()[]{};" c
(* <boxed values 93>=                           *)
val _ = op isDelim : char -> bool
(* [[                                           *)
(* Char.isSpace]] recognizes all whitespace     *)
(* characters. [[Char.contains]] takes a string and a *)
(* character and says if the string contains the *)
(* character. These functions are in the initial basis *)
(* of Standard ML.                              *)
(*                                              *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(* \catcode`=\other \catcode`_=\other \catcode`$=\other *)
(*                                              *)
(*  Lexical analyzers; tokens                   *)
(*  \type'a lexer = (char, 'a) xformer \        *)
(*  tableboxisDelim : char -> bool \            *)
(*  tableboxwhitespace : char list lexer \      *)
(*  tableboxintChars : (char -> bool) ->        *)
(*  char list lexer \tableboxintFromChars :     *)
(*  char list -> int error \tablebox            *)
(*  intToken : (char -> bool) -> int lexer      *)
(*  \typetoken \tableboxtokenString : token     *)
(*  -> string \tableboxlexLineWith : token      *)
(*  lexer -> line -> token stream [8pt]         *)
(*  Streams with end-of-line markers            *)
(*  \type'a eol_marked \tableboxdrainLine :     *)
(*  'a eol_marked stream -> 'a eol_marked       *)
(*  stream [8pt] Parsers                        *)
(*  \type'a parser = (token located             *)
(*  eol_marked, 'a) xformer \tableboxeol :      *)
(*  ('a eol_marked, int) xformer \tablebox      *)
(*  inline : ('a eol_marked, 'a) xformer \      *)
(*  tableboxtoken : token parser \tablebox      *)
(*  srcloc : srcloc parser \tablebox            *)
(*  noTokens : unit parser \tablebox@@ : 'a     *)
(*  parser -> 'a located parser \tablebox       *)
(*  <?> : 'a parser * string -> 'a parser \     *)
(*  tablebox<!> : 'a parser * string -> 'b      *)
(*  parser \tableboxliteral : string ->         *)
(*  unit parser \tablebox>– : string * 'a     *)
(*  parser -> 'a parser \tablebox–< : 'a      *)
(*  parser * string -> 'a parser \tablebox      *)
(*  bracket : string * string * 'a parser       *)
(*  -> 'a parser \splitboxnodupsstring *        *)
(*  string -> srcloc * name list-> name         *)
(*  list error \tableboxsafeTokens : token      *)
(*  located eol_marked stream -> token list     *)
(*  \tableboxechoTagStream : line stream ->     *)
(*  line stream stripAndReportErrors            *)
(*                                          'a error *)
(*                                          stream -> *)
(*                                          'a stream *)
(*  [8pt] A complete, interactive source of     *)
(*  abstract syntax                             *)
(*  interactiveParsedStream : token lexer * 'a parser *)
(*                                          -> string *)
(*                                          * line *)
(*                                          stream * *)
(*                                          prompts *)
(*                                          -> 'a *)
(*                                          stream *)
(*                                              *)
(* Transformers specialized for lexical analysis or *)
(* parsing [*]                                  *)
(*                                              *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(* All languages in this book ignore whitespace. Lexer *)
(* [[whitespace]] is typically combined with another *)
(* lexer using the [[*>]] operator.             *)

(* <support for lexical analysis>=              *)
val whitespace = many (sat Char.isSpace one)
(* <boxed values 94>=                           *)
val _ = op whitespace : char list lexer
(* <support for lexical analysis>=              *)
fun intChars isDelim = 
  (curry (op ::) <$> eqx #"-" one <|> pure id) <*>
  many1 (sat Char.isDigit one) <* 
  notFollowedBy (sat (not o isDelim) one)
(* Most languages in this book are, like Scheme, liberal *)
(* about names. Just about any sequence of characters, *)
(* as long as it is free of delimiters, can form a name. *)
(* But there's one big exception: a sequence of digits *)
(* forms an integer literal, not a name. Because integer *)
(* literals introduce several complications, and because *)
(* they are used in all the languages in this book, *)
(* it makes sense to deal with the complications in one *)
(* place: here.                                 *)
(*                                              *)
(* Integer literals are subject to these rules: *)
(*                                              *)
(*   • An integer literal may begin with a minus sign. *)
(*   • It continues with one or more digits.  *)
(*   • If it is followed by character, that character *)
(*  must be a delimiter. (In other words, it must not *)
(*  be followed by a non-delimiter.)            *)
(*   • When the sequence of digits is converted to an *)
(*  [[int]], the arithmetic used in the conversion *)
(*  must not overflow.                          *)
(*                                              *)
(* Function [[intChars]] does the lexical analysis to *)
(* grab the characters; [[intFromChars]] handles the *)
(* conversion and its potential overflow, and   *)
(* [[intToken]] puts everything together. Because not *)
(* every language uses the same delimiters, both *)
(* [[intChars]] and [[intToken]] receive a predicate *)
(* that identifies delimiters.                  *)
(* <boxed values 95>=                           *)
val _ = op intChars : (char -> bool) -> char list lexer
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* Function [[Char.isDigit]], like [[Char.isSpace]], is *)
(* part of Standard ML.                         *)

(* <support for lexical analysis>=              *)
fun intFromChars (#"-" :: cs) = 
      intFromChars cs >>=+ Int.~
  | intFromChars cs =
      (OK o valOf o Int.fromString o implode) cs
      handle Overflow =>
        ERROR "this interpreter can't read arbitrarily large integers"
(* <boxed values 96>=                           *)
val _ = op intFromChars : char list -> int error
(* <support for lexical analysis>=              *)
fun intToken isDelim =
  intFromChars <$>! intChars isDelim
(* In this book, every language except uProlog can use *)
(* [[intToken]].                                *)
(* <boxed values 97>=                           *)
val _ = op intToken : (char -> bool) -> int lexer
(* The [[xdeftable]] is shared with the Impcore parser. *)
(* Function [[reduce_to_xdef]] is almost shareable as *)
(* well, but not quite---the abstract syntax of *)
(* [[DEFINE]] is different.                     *)

(* All the bridge languages use balanced brackets, which *)
(* may come in three shapes. So that lexers for *)
(* different languages can share code related to *)
(* brackets, bracket shapes and tokens are defined here. *)
(* <support for lexical analysis>=              *)
datatype bracket_shape = ROUND | SQUARE | CURLY
(* <support for lexical analysis>=              *)
datatype 'a plus_brackets
  = LEFT  of bracket_shape
  | RIGHT of bracket_shape
  | PRETOKEN of 'a

fun bracketLexer pretoken
  =  LEFT  ROUND  <$ eqx #"(" one
 <|> LEFT  SQUARE <$ eqx #"[" one
 <|> LEFT  CURLY  <$ eqx #"{" one
 <|> RIGHT ROUND  <$ eqx #")" one
 <|> RIGHT SQUARE <$ eqx #"]" one
 <|> RIGHT CURLY  <$ eqx #"}" one
 <|> PRETOKEN <$> pretoken
(* Bracket tokens are added to a language-specific *)
(* ``pre-token'' type by using the type constructor *)
(* [[plus_brackets]].[*] Function [[bracketLexer]] takes *)
(* as an argument a lexer for pre-tokens, and it returns *)
(* a lexer for tokens:                          *)
(* <boxed values 98>=                           *)
type 'a plus_brackets = 'a plus_brackets
val _ = op bracketLexer : 'a lexer -> 'a plus_brackets lexer
(* [[bindList]] tried to                        *)
(*              extend an environment, but it passed *)
(*              two lists (names and values) of *)
(*              different lengths.              *)
(* RuntimeError    Something else went wrong during *)
(*              evaluation, i.e., during the    *)
(*              execution of [[eval]].          *)
(* \bottomrule                                  *)
(*                                              *)
(* Exceptions defined especially for this interpreter  *)
(* [*]                                          *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* Abstract syntax and values                   *)
(*                                              *)
(* An abstract-syntax tree can contain a literal value. *)
(* A value, if it is a closure, can contain an  *)
(* abstract-syntax tree. These two types are therefore *)
(* mutually recursive, so I define them together, using *)
(* [[and]].                                     *)
(*                                              *)
(* These particular types use as complicated a nest of *)
(* definitions as you'll ever see. The keyword  *)
(* [[datatype]] defines a new algebraic datatype; the *)
(* keyword [[withtype]] introduces a new type   *)
(* abbreviation that is mutually recursive with the *)
(* [[datatype]]. The first group of [[and]] keywords *)
(* define additional algebraic datatypes, and the second *)
(* group of [[and]] keywords define additional type *)
(* abbreviations. Everything in the whole nest is *)
(* mutually recursive. [*] [*]                  *)

(* <support for lexical analysis>=              *)
fun leftString ROUND  = "("
  | leftString SQUARE = "["
  | leftString CURLY  = "{"
fun rightString ROUND  = ")"
  | rightString SQUARE = "]"
  | rightString CURLY = "}"

fun plusBracketsString _   (LEFT shape)  = leftString shape
  | plusBracketsString _   (RIGHT shape) = rightString shape
  | plusBracketsString pts (PRETOKEN pt)  = pts pt
(* For debugging and error messages, brackets and tokens *)
(* can be converted to strings.                 *)
(* <boxed values 99>=                           *)
val _ = op plusBracketsString : ('a -> string) -> ('a plus_brackets -> string)
(* <common parsing code>=                       *)
(* Parsing located, in-line tokens              *)
(*                                              *)
(* In each interpreter, a value of type \monobox'a *)
(* parser is a transformer that takes a stream of *)
(* located tokens set between end-of-line markers, and *)
(* it returns a value of type [['a]], plus any leftover *)
(* tokens. But each interpreter has its own token type, *)
(* and the infrastructure needs to work with all of *)
(* them. That is, it needs to be polymorphic. So a value *)
(* of type \monobox('t, 'a) polyparser is a parser that *)
(* takes tokens of some unknown type [['t]].    *)
(* <combinators and utilities for parsing located streams>= *)
type ('t, 'a) polyparser = ('t located eol_marked, 'a) xformer
(* <combinators and utilities for parsing located streams>= *)
fun token    stream = (snd <$> inline)      stream
fun noTokens stream = (notFollowedBy token) stream
(* When defining a parser, I want not to worry about the *)
(* [[EOL]] and [[INLINE]] constructors. These   *)
(* constructors are essential for error recovery, but *)
(* for parsing, they just get in the way. My first order *)
(* of business is therefore to define analogs of [[one]] *)
(* and [[eos]] that ignore [[EOL]]. Parser [[token]] *)
(* takes one token; parser [[srcloc]] looks at the *)
(* source-code location of a token, but leaves the token *)
(* in the input; and parser [[noTokens]] succeeds only *)
(* if there are no tokens left in the input. They are *)
(* built on top of ``utility'' parsers [[eol]] and *)
(* [[inline]]. The two utility parsers have different *)
(* contracts; [[eol]] succeeds only when at [[EOL]], but *)
(* [[inline]] scans past [[EOL]] to look for [[INLINE]]. *)
(* <boxed values 101>=                          *)
val _ = op token    : ('t, 't)   polyparser
val _ = op noTokens : ('t, unit) polyparser
(* <combinators and utilities for parsing located streams>= *)
fun @@ p = pair <$> srcloc <*> p
(* Parser [[noTokens]] is not that same as [[eos]]: *)
(* parser [[eos]] succeeds only when the input stream is *)
(* empty, but [[noTokens]] can succeed when the input *)
(* stream is not empty but contains only [[EOL]] *)
(* markers—as is likely on the last line of an input *)
(* file.                                        *)
(*                                              *)
(* Source-code locations are useful by themselves, but *)
(* they are also useful when paired with a result from a *)
(* parser. For example, when parsing a message send for *)
(* uSmalltalk, the source-code location of the send is *)
(* used when writing a stack trace. To make it easy to *)
(* add a source-code location to any result from any *)
(* parser, I define the [[@@]] function. (Associate the *)
(* word ``at'' with the idea of ``location.'') The code *)
(* uses a dirty trick: it works because [[srcloc]] looks *)
(* at the input but does not consume any tokens. *)
(* <boxed values 102>=                          *)
val _ = op @@ : ('t, 'a) polyparser -> ('t, 'a located) polyparser
(* <combinators and utilities for parsing located streams>= *)
fun asAscii p =
  let fun good c = Char.isPrint c andalso Char.isAscii c
      fun warn (loc, s) =
        case List.find (not o good) (explode s)
          of NONE => OK s
           | SOME c => 
               let val msg =
                     String.concat ["name \"", s, "\" contains the ",
                                    "non-ASCII or non-printing byte \"",
                                    Char.toCString c, "\""]
               in  synerrorAt msg loc
               end
  in  warn <$>! @@ p
  end
(* <combinators and utilities for parsing located streams>= *)
infix 0 <?>
fun p <?> what = p <|> synerrorAt ("expected " ^ what) <$>! srcloc
(* <boxed values 103>=                          *)
val _ = op asAscii : ('t, string) polyparser -> ('t, string) polyparser
(* Parsers that report errors                   *)
(*                                              *)
(* A typical syntactic form (expression, unit test, or *)
(* definition, for example) is parsed by a sequence of *)
(* alternatives separated with [[<|>]]. When no *)
(* alternative succeeds, the collective should usually *)
(* be reported as a syntax error. An error-reporting *)
(* parser can be created using the [[<?>]] function: *)
(* parser \monoboxp <?> what succeeds when [[p]] *)
(*  succeeds, but when [[p]] fails, parser \monoboxp <?> *)
(* what reports an error: it expected [[what]]. *)
(* The error says what the parser was expecting, and it *)
(* gives the source-code location of the unrecognized *)
(* token. If there is no token, there is no error—at end *)
(* of file, rather than signal an error, a parser made *)
(* using [[<?>]] fails. An example appears in the parser *)
(* for extended definitions in micro-Scheme (\chunkref *)
(* mlschemea.chunk.xdef). [*]                   *)
(* <boxed values 103>=                          *)
val _ = op <?> : ('t, 'a) polyparser * string -> ('t, 'a) polyparser
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* The [[<?>]] operator must not be used to define a *)
(* parser that is passed to [[many]], [[many1]], or *)
(* [[optional]] In that context, if parser [[p]] fails, *)
(* it must not signal an error; it must instead *)
(* propagate the failure to [[many]], [[many1]], or *)
(* [[optional]], so those combinators know there is not *)
(* a [[p]] there.                               *)

(* <combinators and utilities for parsing located streams>= *)
infix 4 <!>
fun p <!> msg =
  fn tokens => (case p tokens
                  of SOME (OK _, unread) =>
                       let val outcome =
                             case peek srcloc tokens
                              of SOME loc => synerrorAt msg loc
                               | NONE => ERROR msg
                                             
                       in  SOME (outcome, unread)
                       end
                   | _ => NONE)
(* Another common error-detecting technique is to use a *)
(* parser [[p]] to detect some input that shouldn't be *)
(* there. For example, a parser is just starting to read *)
(* a definition, the input shouldn't begin with a right *)
(* parenthesis. I can write a parser [[p]] that *)
(* recognizes a right parenthesis, but I can't simply *)
(* combine [[p]] with [[synerrorAt]] and [[srcloc]] in *)
(* the same way that [[<?>]] does, because I want my *)
(* combined parser to do two things: consume the tokens *)
(* recognized by [[p]], and also report the error at the *)
(* location of the first of those tokens. I can't use *)
(* [[synerrorAt]] until after [[p]] succeeds, but I have *)
(* to use [[srcloc]] on the input stream as it is before *)
(* [[p]] is run. I solve this problem by defining a *)
(* special combinator that keeps a copy of the tokens *)
(* inspected by [[p]]. If parser [[p]] succeeds, then *)
(* parser \monoboxp <!> msg consumes the tokens consumed *)
(* by [[p]] and reports error [[msg]] at the location of *)
(* [[p]]'s first token.                         *)
(* <boxed values 104>=                          *)
val _ = op <!> : ('t, 'a) polyparser * string -> ('t, 'b) polyparser
(* <combinators and utilities for parsing located streams>= *)
fun nodups (what, context) (loc, names) =
  let fun dup [] = OK names
        | dup (x::xs) =
            if List.exists (fn y => y = x) xs then
              synerrorAt (what ^ " " ^ x ^ " appears twice in " ^ context) loc
            else
              dup xs
  in  dup names
  end
(* \qbreak                                      *)
(*                                              *)
(* Detection of duplicate names                 *)
(*                                              *)
(* Most of the languages in this book allow you to *)
(* define functions or methods that take formal *)
(* parameters. It is never permissible to use the same *)
(* name for formal parameters in two different  *)
(* positions. There are surprisingly many other places *)
(* where it's not acceptable to have duplicates in a *)
(* list of strings. Function [[nodups]] takes two *)
(* Curried arguments: a pair saying what kind of thing *)
(* might be duplicated and where it appeared, followed *)
(* by a pair containing a list of names and the *)
(* source-code location of the list. If there are no *)
(* duplicates, it returns [[OK]] applied to the list of *)
(* names; otherwise it returns an [[ERROR]]. Function *)
(* [[nodups]] is typically applied to a pair of strings, *)
(* after which the result is applied to a parser using *)
(* the [[<>!]] function.                        *)
(*                                              *)
(* \qbreak                                      *)
(* <boxed values 113>=                          *)
val _ = op nodups : string * string -> srcloc * name list -> name list error
(* Function [[List.exists]] is like the micro-Scheme *)
(* [[exists?]]. It is in the initial basis for  *)
(* Standard ML.                                 *)

(* <combinators and utilities for parsing located streams>= *)
fun rejectReserved reserved x =
  if member x reserved then
    ERROR ("syntax error: " ^ x ^ " is a reserved word and " ^
           "may not be used to name a variable or function")
  else
    OK x
(* Detection of reserved words                  *)
(*                                              *)
(* To rule out such nonsense as ``\monobox(val if 3),'' *)
(* parsers use function [[rejectReserved]], which issues *)
(* a syntax-error message if a name is on a list of *)
(* reserved words.                              *)
(* <boxed values 114>=                          *)
val _ = op rejectReserved : name list -> name -> name error
(* <transformers for interchangeable brackets>= *)
fun left  tokens = ((fn (loc, LEFT  s) => SOME (loc, s) | _ => NONE) <$>? inline
                                                                        ) tokens
fun right tokens = ((fn (loc, RIGHT s) => SOME (loc, s) | _ => NONE) <$>? inline
                                                                        ) tokens
fun pretoken stream = ((fn PRETOKEN t => SOME t | _ => NONE) <$>? token) stream
(* Parsers that involve brackets                *)
(*                                              *)
(* Almost every language in this book uses a    *)
(* parenthesis-prefix syntax (Scheme syntax) in which *)
(* round and square brackets must match, but are *)
(* otherwise interchangeable. [I~have spent entirely too *)
(* much time working with Englishmen who call   *)
(* parentheses ``brackets.'' I~now find it hard even to *)
(* \emph{say} the word ``parenthesis,'' let alone *)
(* type~it. ] Brackets are treated specially by the *)
(* [[plus_brackets]] type (\cpageref            *)
(* lazyparse.plus-brackets), which identifies every *)
(* token as a left bracket, a right bracket, or a *)
(* ``pre-token.'' Each of these alternatives is *)
(* supported by its own parser. A parser that finds a *)
(* bracket returns the bracket's shape and location; *)
(* a parser the finds a pre-token returns the pre-token. *)
(* <boxed values 106>=                          *)
val _ = op left  : ('t plus_brackets, bracket_shape located) polyparser
val _ = op right : ('t plus_brackets, bracket_shape located) polyparser
val _ = op pretoken : ('t plus_brackets, 't) polyparser
(* <transformers for interchangeable brackets>= *)
fun badRight msg =
  (fn (loc, shape) => synerrorAt (msg ^ " " ^ rightString shape) loc) <$>! right
(* Every interpreter needs to be able to complain when *)
(* it encounters an unexpected right bracket.   *)
(* An interpreter can build a suitable parser by passing *)
(* a message to [[badRight]]. Since the parser never *)
(* succeeds, it can have any result type.       *)
(* <boxed values 107>=                          *)
val _ = op badRight : string -> ('t plus_brackets, 'a) polyparser
(* The [[xdeftable]] is shared with the Impcore parser. *)
(* Function [[reduce_to_xdef]] is almost shareable as *)
(* well, but not quite---the abstract syntax of *)
(* [[DEFINE]] is different.                     *)

(* <transformers for interchangeable brackets>= *)
fun notCurly (_, CURLY) = false
  | notCurly _          = true
fun leftCurly tokens = sat (not o notCurly) left tokens
(* <transformers for interchangeable brackets>= *)
(* <definition of function [[errorAtEnd]]>=     *)
infix 4 errorAtEnd
fun p errorAtEnd mkMsg =
  fn tokens => 
    (case (p <* rewind right) tokens
       of SOME (OK s, unread) =>
            let val outcome =
                  case peek srcloc tokens
                    of SOME loc => synerrorAt ((concat o mkMsg) s) loc
                     | NONE => ERROR ((concat o mkMsg) s)
            in  SOME (outcome, unread)
            end
        | _ => NONE)
(* Function [[<!>]] is adequate for simple cases, but to *)
(* produce a really good error message, I might wish to *)
(* use the result from [[p]] to build a message. *)
(* My interpreters produce such messages only for text *)
(* appearing in brackets, so [[errorAtEnd]] triggers *)
(* only when [[p]] parses tokens that are followed by a *)
(* right bracket. \nwcrazynarrowboxes           *)
(* <boxed values 105>=                          *)
val _ = op errorAtEnd : ('t plus_brackets, 'a) polyparser * ('a -> string list)
                                            -> ('t plus_brackets, 'b) polyparser
(* <transformers for interchangeable brackets>= *)
datatype right_result
  = FOUND_RIGHT      of bracket_shape located
  | SCANNED_TO_RIGHT of srcloc  (* location where scanning started *)
  | NO_RIGHT
(* In this book, round and square brackets are  *)
(* interchangeable, but curly brackets are special. *)
(* Predicate [[notCurly]] identifies those non-curly, *)
(* interchangeable bracket shapes. Parser [[leftCurly]] *)
(* is just like [[left]], except it recognizes only *)
(* curly left brackets.                         *)
(* <boxed values 108>=                          *)
val _ = op notCurly  : bracket_shape located -> bool
val _ = op leftCurly : ('t plus_brackets, bracket_shape located) polyparser
(* Brackets by themselves are all very well, but what I *)
(* really want is to parse syntax that is wrapped in *)
(* matching brackets. But what if something goes wrong *)
(* inside the brackets? In that case, I want each of my *)
(* parsers to skip tokens until it gets to the matching *)
(* right bracket, and I'll likely want it to report the *)
(* source-code location of the left bracket. To look *)
(* ahead for a right bracket is the job of parser *)
(* [[matchingRight]]. This parser is called when a left *)
(* bracket has already been consumed, and it searches *)
(* the input stream for a right bracket, skipping every *)
(* left/right pair that it finds in the interim. Because *)
(* it's meant for error handling, it always succeeds. *)
(* And to communicate its findings, it produces one of *)
(* three outcomes:                              *)
(*                                              *)
(*   • Result \monobox[[FOUND_RIGHT]] (loc, s) says, *)
(*  ``I found a right bracket exactly where     *)
(*  I expected to, and its shape and location are s *)
(*  and loc.''                                  *)
(*   • Result \monobox[[SCANNED_TO_RIGHT]] loc says, *)
(*  ``I didn't find a right bracket at loc, but *)
(*  I scanned to a matching right bracket       *)
(*  eventually.''                               *)
(*   • Result \monobox[[NO_RIGHT]] says, ``I scanned the *)
(*  entire input without finding a matching right *)
(*  bracket.''                                  *)
(*                                              *)
(* This result is defined as follows:           *)
(* <boxed values 108>=                          *)
type right_result = right_result
(* <transformers for interchangeable brackets>= *)
type ('t, 'a) pb_parser = ('t plus_brackets, 'a) polyparser
fun matchingRight tokens =
  let fun scanToClose tokens = 
        let val loc = getOpt (peek srcloc tokens, ("end of stream", 9999))
            fun scan nlp tokens =
              (* nlp is the number of unmatched left parentheses *)
              case tokens
                of EOL _                  ::: tokens => scan nlp tokens
                 | INLINE (_, PRETOKEN _) ::: tokens => scan nlp tokens
                 | INLINE (_, LEFT  _)    ::: tokens => scan (nlp+1) tokens
                 | INLINE (_, RIGHT _)    ::: tokens =>
                     if nlp = 0 then
                       pure (SCANNED_TO_RIGHT loc) tokens
                     else
                       scan (nlp-1) tokens
                 | EOS         => pure NO_RIGHT tokens
                 | SUSPENDED s => scan nlp (demand s)
        in  scan 0 tokens
        end
  in  (FOUND_RIGHT <$> right <|> scanToClose) tokens
  end
(* A value of type [[right_result]] is produced by *)
(* parser [[matchingRight]]. A right bracket in the *)
(* expected position is successfully found by the \ *)
(* qbreak [[right]] parser; when tokens have to be *)
(* skipped, they are skipped by parser [[scanToClose]]. *)
(* The ``matching'' is done purely by counting left and *)
(* right brackets; [[scanToClose]] does not look at *)
(* shapes.                                      *)
(* <boxed values 109>=                          *)
val _ = op matchingRight : ('t, right_result) pb_parser
(* <transformers for interchangeable brackets>= *)
fun matchBrackets _ (loc, left) a (FOUND_RIGHT (loc', right)) =
      if left = right then
        OK a
      else
        synerrorAt (rightString right ^ " does not match " ^ leftString left ^
                 (if loc <> loc' then " at " ^ srclocString loc else "")) loc'
  | matchBrackets _ (loc, left) _ NO_RIGHT =
      synerrorAt ("unmatched " ^ leftString left) loc
  | matchBrackets e (loc, left) _ (SCANNED_TO_RIGHT loc') =
      synerrorAt ("expected " ^ e) loc
(* <boxed values 110>=                          *)
val _ = op matchBrackets : string -> bracket_shape located -> 'a -> right_result
                                                                     -> 'a error
(* <transformers for interchangeable brackets>= *)

fun liberalBracket (expected, p) =
  matchBrackets expected <$> sat notCurly left <*> p <*>! matchingRight
fun bracket (expected, p) =
  liberalBracket (expected, p <?> expected)
fun curlyBracket (expected, p) =
  matchBrackets expected <$> leftCurly <*> (p <?> expected) <*>! matchingRight
fun bracketKeyword (keyword, expected, p) =
  liberalBracket (expected, keyword *> (p <?> expected))
(* \qbreak The bracket matcher is then used to help wrap *)
(* other parsers in brackets. A parser may be wrapped in *)
(* a variety of ways, depending on what may be allowed *)
(* to fail without causing an error.            *)
(*                                              *)
(*   • To wrap parser [[p]] in matching round or square *)
(*  brackets when [[p]] may fail: use           *)
(*  [[liberalBracket]]. If [[p]] succeeds but the *)
(*  brackets don't match, that's an error.      *)
(*   • To wrap parser [[p]] in matching round or square *)
(*  brackets when [[p]] must succeed: use       *)
(*  [[bracket]].                                *)
(*   • To wrap parser [[p]] in matching curly brackets *)
(*  when [[p]] must succeed: use [[curlyBracket]]. *)
(*   • To put parser [[p]] after a keyword, all wrapped *)
(*  in brackets: use [[bracketKeyword]]. Once the *)
(*  keyword is seen, [[p]] must not fail—if it does, *)
(*  that's an error.                            *)
(*                                              *)
(* Each of these functions takes a parameter    *)
(* [[expected]] of type [[string]]; when anything goes *)
(* wrong, this parameter says what the parser was *)
(* expecting. [*] \nwnarrowboxes                *)
(* <boxed values 111>=                          *)
val _ = op liberalBracket : string * ('t, 'a) pb_parser -> ('t, 'a) pb_parser
val _ = op bracket           : string * ('t, 'a) pb_parser -> ('t, 'a) pb_parser
val _ = op curlyBracket    : string * ('t, 'a) pb_parser -> ('t, 'a) pb_parser
(* <boxed values 111>=                          *)
val _ = op bracketKeyword : ('t, 'keyword) pb_parser * string * ('t, 'a)
                                                 pb_parser -> ('t, 'a) pb_parser
(* <transformers for interchangeable brackets>= *)
fun usageParser keyword =
  let val left = eqx #"(" one <|> eqx #"[" one
      val getkeyword = left *> (implode <$> many1 (sat (not o isDelim) one))
  in  fn (usage, p) =>
        case getkeyword (streamOfList (explode usage))
          of SOME (OK k, _) => bracketKeyword (keyword k, usage, p)
           | _ => raise InternalError ("malformed usage string: " ^ usage)
  end
(* The [[bracketKeyword]] function is what's used to *)
(* build parsers for [[if]], [[lambda]], and many other *)
(* syntactic forms. And if one of these parsers fails, *)
(* I want it to show the programmer what's expected, *)
(* like for example \monobox"(if e1 e2 e3)". The *)
(* expectation is represented by a usage string. A usage *)
(* string begins with a left bracket, which is followed *)
(* by its keyword. I want not to write the keyword *)
(* twice, so [[usageParser]] pulls the keyword out of *)
(* the usage string—using a parser. [*]       *)
(* <boxed values 112>=                          *)
val _ = op usageParser : (string -> ('t, string) pb_parser) ->
                               string * ('t, 'a) pb_parser -> ('t, 'a) pb_parser
(* [[bindList]] tried to                        *)
(*              extend an environment, but it passed *)
(*              two lists (names and values) of *)
(*              different lengths.              *)
(* RuntimeError    Something else went wrong during *)
(*              evaluation, i.e., during the    *)
(*              execution of [[eval]].          *)
(* \bottomrule                                  *)
(*                                              *)
(* Exceptions defined especially for this interpreter  *)
(* [*]                                          *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* Abstract syntax and values                   *)
(*                                              *)
(* An abstract-syntax tree can contain a literal value. *)
(* A value, if it is a closure, can contain an  *)
(* abstract-syntax tree. These two types are therefore *)
(* mutually recursive, so I define them together, using *)
(* [[and]].                                     *)
(*                                              *)
(* These particular types use as complicated a nest of *)
(* definitions as you'll ever see. The keyword  *)
(* [[datatype]] defines a new algebraic datatype; the *)
(* keyword [[withtype]] introduces a new type   *)
(* abbreviation that is mutually recursive with the *)
(* [[datatype]]. The first group of [[and]] keywords *)
(* define additional algebraic datatypes, and the second *)
(* group of [[and]] keywords define additional type *)
(* abbreviations. Everything in the whole nest is *)
(* mutually recursive. [*] [*]                  *)

(* <code used to debug parsers>=                *)
fun safeTokens stream =
  let fun tokens (seenEol, seenSuspended) =
            let fun get (EOL _         ::: ts) = if seenSuspended then []
                                                 else tokens (true, false) ts
                  | get (INLINE (_, t) ::: ts) = t :: get ts
                  | get  EOS                   = []
                  | get (SUSPENDED (ref (PRODUCED ts))) = get ts
                  | get (SUSPENDED s) = if seenEol then []
                                        else tokens (false, true) (demand s)
            in   get
            end
  in  tokens (false, false) stream
  end
(* Code used to debug parsers                   *)
(*                                              *)
(* When debugging parsers, I often find it helpful to *)
(* dump out the tokens that a parser is looking at. *)
(* I want to dump only the tokens that are available *)
(* without triggering the action of reading another line *)
(* of input. To get those tokens, function      *)
(* [[safeTokens]] reads until it has got to both an *)
(* end-of-line marker and a suspension whose value has *)
(* not yet been demanded.                       *)
(* <boxed values 115>=                          *)
val _ = op safeTokens : 'a located eol_marked stream -> 'a list
(* <code used to debug parsers>=                *)
fun showErrorInput asString p tokens =
  case p tokens
    of result as SOME (ERROR msg, rest) =>
         if String.isSubstring " [input: " msg then
           result
         else
           SOME (ERROR (msg ^ " [input: " ^
                        spaceSep (map asString (safeTokens tokens)) ^ "]"),
               rest)
     | result => result
(* \qbreak Another way to debug is to show whatever *)
(* input tokens might cause an error. They can be shown *)
(* using function [[showErrorInput]], which transforms *)
(* an ordinary parser into a parser that, when it *)
(* errors, shows the input that caused the error. *)
(* It should be applied routinely to every parser you *)
(* build. \nwverynarrowboxes                    *)
(* <boxed values 116>=                          *)
val _ = op showErrorInput : ('t -> string) -> ('t, 'a) polyparser -> ('t, 'a)
                                                                      polyparser
(* <code used to debug parsers>=                *)
fun wrapAround tokenString what p tokens =
  let fun t tok = " " ^ tokenString tok
      val _ = app eprint ["Looking for ", what, " at"]
      val _ = app (eprint o t) (safeTokens tokens)
      val _ = eprint "\n"
      val answer = p tokens
      val _ = app eprint [ case answer of NONE => "Didn't find "
                                        | SOME _ => "Found "
                         , what, "\n"
                         ]
  in  answer
  end handle e =>
        ( app eprint ["Search for ", what, " raised ", exnName e, "\n"]
        ; raise e
        )
(* <boxed values 117>=                          *)
val _ = op wrapAround : ('t -> string) -> string -> ('t, 'a) polyparser -> ('t,
                                                                  'a) polyparser
(* <streams that issue two forms of prompts>=   *)
fun echoTagStream lines = 
  let fun echoIfTagged line =
        if (String.substring (line, 0, 2) = ";#" handle _ => false) then
          print line
        else
          ()
  in  postStream (lines, echoIfTagged)
  end
(* Support for testing                          *)
(*                                              *)
(* I begin with testing support. As in the C code, *)
(* I want each interpreter to print out any line read *)
(* that begins with the special string [[;#]]. This *)
(* string is a formal comment that helps test chunks *)
(* marked \LAtranscript\RA. The strings are printed in a *)
(* modular way: a post-stream action prints any line *)
(* meeting the criterion. Function [[echoTagStream]] *)
(* transforms a stream of lines to a stream of lines, *)
(* adding the behavior I want.                  *)
(* <boxed values 118>=                          *)
val _ = op echoTagStream : line stream -> line stream 
(* <streams that issue two forms of prompts>=   *)
fun stripAndReportErrors xs =
  let fun next xs =
        case streamGet xs
          of SOME (ERROR msg, xs) => (eprintln msg; next xs)
           | SOME (OK x, xs) => SOME (x, xs)
           | NONE => NONE
  in  streamOfUnfold next xs
  end
(* \qbreak                                      *)
(*                                              *)
(* Issuing messages for error values            *)
(*                                              *)
(* Next is error handling. A process that can detect *)
(* errors produces a stream of type \monobox'a error *)
(* stream, for some unspecified type [['a]]. The  *)
(* [[ERROR]] and [[OK]] tags can be removed by reporting *)
(* errors and passing on values tagged [[OK]], resulting *)
(* in a new stream of type \monobox'a stream. Values *)
(* tagged with [[OK]] are passed on to the output stream *)
(* unchanged; messages tagged with [[ERROR]] are printed *)
(* to standard error, using [[eprintln]].       *)
(* <boxed values 119>=                          *)
val _ = op stripAndReportErrors : 'a error stream -> 'a stream
(* <streams that issue two forms of prompts>=   *)
fun lexLineWith lexer =
  stripAndReportErrors o streamOfUnfold lexer o streamOfList o explode
(* Using [[stripAndReportErrors]], I can turn a lexical *)
(* analyzer into a function that takes an input line and *)
(* returns a stream of tokens. Any errors detected *)
(* during lexical analysis are printed without any *)
(* information about source-code locations. That's *)
(* because, to keep things somewhat simple, I've chosen *)
(* to do lexical analysis on one line at a time, and my *)
(* code doesn't keep track of the line's source-code *)
(* location.                                    *)
(* <boxed values 120>=                          *)
val _ = op lexLineWith : 't lexer -> line -> 't stream
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <streams that issue two forms of prompts>=   *)
fun parseWithErrors parser =
  let fun adjust (SOME (ERROR msg, tokens)) =
            SOME (ERROR msg, drainLine tokens)
        | adjust other = other
  in  streamOfUnfold (adjust o parser)
  end
(* <boxed values 121>=                          *)
val _ = op parseWithErrors : ('t, 'a) polyparser ->                     't
                                    located eol_marked stream -> 'a error stream
(* <streams that issue two forms of prompts>=   *)
type prompts   = { ps1 : string, ps2 : string }
val stdPrompts = { ps1 = "-> ", ps2 = "   " }
val noPrompts  = { ps1 = "", ps2 = "" }
(* Prompts                                      *)
(*                                              *)
(* Each interpreter in this book issues prompts using *)
(* the model established by the Unix shell. This model *)
(* uses two prompt strings. The first prompt string, *)
(* called [[ps1]], is issued when starting to read a *)
(* definition. The second prompt string, called [[ps2]], *)
(* is issued when in the middle of reading a definition. *)
(* Prompting can be disabled by making both [[ps1]] and *)
(* [[ps2]] empty.                               *)
(* <boxed values 122>=                          *)
type prompts = prompts
val _ = op stdPrompts : prompts
val _ = op noPrompts  : prompts
(* <streams that issue two forms of prompts>=   *)
fun ('t, 'a) interactiveParsedStream (lexer, parser) (name, lines, prompts) =
  let val { ps1, ps2 } = prompts
      val thePrompt = ref ps1
      fun setPrompt ps = fn _ => thePrompt := ps

      val lines = preStream (fn () => print (!thePrompt), echoTagStream lines)

      fun lexAndDecorate (loc, line) =
        let val tokens = postStream (lexLineWith lexer line, setPrompt ps2)
        in  streamMap INLINE (streamZip (streamRepeat loc, tokens)) @@@
            streamOfList [EOL (snd loc)]
        end

      val xdefs_with_errors : 'a error stream = 
        (parseWithErrors parser o streamConcatMap lexAndDecorate o locatedStream
                                                                               )
        (name, lines)
(* Building a reader                            *)
(*                                              *)
(* All that is left is to combine lexer and parser. The *)
(* combination manages the flow of information from the *)
(* input through the lexer and parser, and by monitoring *)
(* the flow of tokens in and syntax out, it arranges *)
(* that the right prompts ([[ps1]] and [[ps2]]) are *)
(* printed at the right times. The flow of information *)
(* involves multiple steps:                     *)
(*                                              *)
(*  1. [*] The input is a stream of lines. The stream is *)
(*  transformed with [[preStream]] and          *)
(*  [[echoTagStream]], so that a prompt is printed *)
(*  before every line, and when a line contains the *)
(*  special tag, that line is echoed to the output. *)
(*  2. Each line is converted to a stream of tokens by *)
(*  function \monoboxlexLineWith lexer. Each token is *)
(*  then paired with a source-code location and, *)
(*  tagged with [[INLINE]], and the stream of tokens *)
(*  is followed by an [[EOL]] value. This extra *)
(*  decoration transforms the \monoboxtoken stream *)
(*  provided by the lexer to the \monoboxtoken  *)
(*  located [[eol_marked]] stream needed by the *)
(*  parser. The work is done by function        *)
(*  [[lexAndDecorate]], which needs a located line. *)
(*                                              *)
(*  The moment a token is successfully taken from the *)
(*  stream, a [[postStream]] action sets the prompt *)
(*  to [[ps2]].                                 *)
(*  3. A final stream of definitions is computed by *)
(*  composing [[locatedStream]] to add source-code *)
(*  locations, \monoboxstreamConcatMap lexAndDecorate *)
(*  to add decorations, and \monoboxparseWithErrors *)
(*  parser to parse. The entire composition is  *)
(*  applied to the stream of lines created in step  *)
(*  [<-].                                       *)
(*                                              *)
(* The composition is orchestrated by function  *)
(* [[interactiveParsedStream]].                 *)
(*                                              *)
(* To deliver the right prompt in the right situation, *)
(* [[interactiveParsedStream]] stores the current prompt *)
(* in a mutable cell called [[thePrompt]]. The prompt is *)
(* initially [[ps1]], and it stays [[ps1]] until a token *)
(* is delivered, at which point the [[postStream]] *)
(* action sets it to [[ps2]]. But every time a new *)
(* definition is demanded, a [[preStream]] action on the *)
(* syntax stream [[xdefs_with_errors]] resets the prompt *)
(* to [[ps1]]. \qbreak This combination of pre- and *)
(* post-stream actions, on different streams, ensures *)
(* that the prompt is always appropriate to the state of *)
(* the parser. [*] \nwnarrowboxes               *)
(* <boxed values 123>=                          *)
val _ = op interactiveParsedStream : 't lexer * ('t, 'a) polyparser ->
                                     string * line stream * prompts -> 'a stream
val _ = op lexAndDecorate : srcloc * line -> 't located eol_marked stream
  in  
      stripAndReportErrors (preStream (setPrompt ps1, xdefs_with_errors))
  end 
(* The functions defined in this appendix are useful for *)
(* reading all kinds of input, not just computer *)
(* programs, and I encourage you to use them in your own *)
(* projects. But here are two words of caution: with so *)
(* many abstractions in the mix, the parsers are tricky *)
(* to debug. And while some parsers built from  *)
(* combinators are very efficient, mine aren't. *)

(* <common parsing code ((elided))>=            *)
fun ('t, 'a) finiteStreamOfLine fail (lexer, parser) line =
  let val lines = streamOfList [line] @@@ streamOfEffects fail
      fun lexAndDecorate (loc, line) =
        let val tokens = lexLineWith lexer line
        in  streamMap INLINE (streamZip (streamRepeat loc, tokens)) @@@
            streamOfList [EOL (snd loc)]
        end

      val things_with_errors : 'a error stream = 
        (parseWithErrors parser o streamConcatMap lexAndDecorate o locatedStream
                                                                               )
        ("command line", lines)
  in  
      stripAndReportErrors things_with_errors
  end 
val _ = finiteStreamOfLine :
          (unit -> string option) -> 't lexer * ('t, 'a) polyparser -> line ->
                                                                       'a stream
(* \qbreak                                      *)
(*                                              *)
(* Interpreter setup and command-line \         *)
(* chaptocsplitprocessing                       *)
(*                                              *)
(* In each interpreter, something has to act like the *)
(* C function [[main]]. This code has to initialize the *)
(* interpreter and start evaluating extended    *)
(* definitions.                                 *)
(*                                              *)
(* Part of initialization is setting the global error *)
(* format. The reusable function [[setup_error_format]] *)
(* uses interactivity to set the error format, which, as *)
(* in the C versions, determines whether syntax-error *)
(* messages include source-code locations (see functions *)
(* [[synerrorAt]] and [[synerrormsg]] on \      *)
(* cpagerefmlinterps.synerrormsg,mlinterps.synerrorAt). *)
(* <shared utility functions for initializing interpreters>= *)
fun override_if_testing () =                           (*OMIT*)
  if isSome (OS.Process.getEnv "NOERRORLOC") then      (*OMIT*)
    toplevel_error_format := WITHOUT_LOCATIONS         (*OMIT*)
  else                                                 (*OMIT*)
    ()                                                 (*OMIT*)
fun setup_error_format interactivity =
  if prompts interactivity then
    toplevel_error_format := WITHOUT_LOCATIONS
    before override_if_testing () (*OMIT*)
  else
    toplevel_error_format := WITH_LOCATIONS
    before override_if_testing () (*OMIT*)
(* \qbreak                                      *)
(*                                              *)
(* Utility functions for limiting computation   *)
(*                                              *)
(* Each interpreter is supplied with two ways of *)
(* stopping a runaway computation:              *)
(*                                              *)
(*   • A recursion limit halts the computation if its *)
(*  call stack gets deeper than 6,000 calls.    *)
(*   • A supply of evaluation fuel halts the computation *)
(*  after a million calls to [[eval]]. That's enough *)
(*  to compute the 25th Catalan number in uSmalltalk, *)
(*  for example.                                *)
(*                                              *)
(* If environment variable [[BPCOPTIONS]] includes the *)
(* string [[nothrottle]], evaluation fuel is ignored. *)
(* <function application with overflow checking>= *)
local
  val defaultRecursionLimit = 6000
  val recursionLimit = ref defaultRecursionLimit
  datatype checkpoint = RECURSION_LIMIT of int

  val evalFuel = ref 1000000
  val throttleCPU = not (hasOption "nothrottle")
in
  (* manipulate recursion limit *)
  fun checkpointLimit () = RECURSION_LIMIT (!recursionLimit)
  fun restoreLimit (RECURSION_LIMIT n) = recursionLimit := n

  (* work with fuel *)
  val defaultEvalFuel = ref (!evalFuel)
  fun fuelRemaining () = !evalFuel
  fun withFuel n f x = 
    let val old = !evalFuel
        val _ = evalFuel := n
    in  (f x before evalFuel := old) handle e => (evalFuel := old; raise e)
    end
(* \qbreak                                      *)
(* <function application with overflow checking>= *)
  (* convert function `f` to respect computation limits *)
  fun applyWithLimits f =
    if !recursionLimit <= 0 then
      ( recursionLimit := defaultRecursionLimit
      ; raise RuntimeError "recursion too deep"
      )
    else if throttleCPU andalso !evalFuel <= 0 then
      ( evalFuel := !defaultEvalFuel
      ; raise RuntimeError "CPU time exhausted"
      )
    else
      let val _ = recursionLimit := !recursionLimit - 1
          val _ = evalFuel       := !evalFuel - 1
      in  fn arg => f arg before (recursionLimit := !recursionLimit + 1)
      end
  fun resetComputationLimits () = ( recursionLimit := defaultRecursionLimit
                                  ; evalFuel := !defaultEvalFuel
                                  )
end



(*****************************************************************)
(*                                                               *)
(*   ABSTRACT SYNTAX AND VALUES FOR \USCHEME                     *)
(*                                                               *)
(*****************************************************************)

(* <abstract syntax and values for \uscheme>=   *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(* \advanceby 3.5pt                             *)
(*                                              *)
(*                                              *)
(*                                              *)
(* Exceptions                                   *)
(* raised at run                                *)
(* time                                         *)
(* NotFound       A name was looked up in an environment *)
(*             but not found there.             *)
(* BindListLength A call to [[bindList]] tried to extend *)
(*             an environment, but it passed two *)
(*             lists (names and values) of different *)
(*             lengths (also raised by [[mkEnv]]). *)
(* RuntimeError   Something else went wrong during *)
(*             evaluation, i.e., during the execution *)
(*             of [[eval]].                     *)
(*                                              *)
(* Exceptions defined for my interpreters [*]   *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* Abstract syntax and values                   *)
(*                                              *)
(* [*]                                          *)
(*                                              *)
(* An abstract-syntax tree can contain a literal value. *)
(* A value, if it is a closure, can contain an  *)
(* abstract-syntax tree. These two types are therefore *)
(* mutually recursive, so they must be defined together, *)
(* using [[and]].                               *)
(*                                              *)
(* These particular types use as complicated a nest of *)
(* definitions as you'll ever see. The keyword  *)
(* [[datatype]] defines a new algebraic datatype; the *)
(* keyword [[withtype]] introduces a new type   *)
(* abbreviation that is mutually recursive with the *)
(* [[datatype]]. The first two [[and]] keywords define *)
(* additional algebraic datatypes, and the third [[and]] *)
(* keyword defines an additional type abbreviation. *)
(* Everything in the whole nest is mutually recursive.  *)
(* [*] [*]                                      *)
(* <definitions of [[exp]] and [[value]] for \uscheme>= *)
datatype exp   = LITERAL of value
               | VAR     of name
               | SET     of name * exp
               | IFX     of exp * exp * exp
               | WHILEX  of exp * exp
               | BEGIN   of exp list
               | APPLY   of exp * exp list
               | LETX    of let_flavor * (name * exp) list * exp
               | LAMBDA  of lambda
and let_flavor = LET | LETREC | LETSTAR
and      value = SYM       of name
               | NUM       of int
               | BOOLV     of bool   
               | NIL
               | PAIR      of value * value
               | CLOSURE   of lambda * value ref env
               | PRIMITIVE of primitive
withtype primitive = exp * value list -> value (* raises RuntimeError *)
     and lambda    = name list * exp
(* The representations are the same as in C, with these *)
(* exceptions:                                  *)
(*                                              *)
(*   • In a [[LETX]] expression, the bindings are *)
(*  represented by a list of pairs, not a pair of *)
(*  lists—just like environments.             *)
(*   • In the representation of a primitive function, *)
(*  there's no need for an integer tag. As shown in \ *)
(*  crefmlscheme.primitives below, ML's higher-order *)
(*  functions makes it easy to create groups of *)
(*  primitives that share code. Tags would be useful *)
(*  only if we wanted to distinguish one primitive *)
(*  from another when printing.                 *)
(*   • None of the fields of [[exp]], [[value]], or *)
(*  [[lambda]] is named. Instead of being referred to *)
(*  by name, these fields are referred to by pattern *)
(*  matching.                                   *)
(*                                              *)
(* A primitive function that goes wrong raises the *)
(* [[RuntimeError]] exception, which is the ML  *)
(* equivalent of calling [[runerror]].          *)
(*                                              *)
(* True definitions are as in the C code, except again, *)
(* fields are not named. [*]                    *)

(* <definition of [[def]] for \uscheme>=        *)
datatype def  = VAL    of name * exp
              | EXP    of exp
              | DEFINE of name * lambda
(* Unit tests and other extended definitions are *)
(* relegated to \crefmlschemea.chap.            *)

(* Common syntactic \chaptocsplitforms          *)
(*                                              *)
(* [*] Syntactic forms for unit tests and for extended *)
(* definitions are often shared.                *)
(*                                              *)
(* The following forms of unit test are used by both of *)
(* the major untyped languages in this book:    *)
(* micro-Scheme (\crefmlscheme.chap) and uSmalltalk (\ *)
(* crefsmall.chap). [*]                         *)
(* <definition of [[unit_test]] for untyped languages (shared)>= *)
datatype unit_test = CHECK_EXPECT of exp * exp
                   | CHECK_ASSERT of exp
                   | CHECK_ERROR  of exp
(* <definition of [[xdef]] (shared)>=           *)
datatype xdef = DEF    of def
              | USE    of name
              | TEST   of unit_test
              | DEFS   of def list  (*OMIT*)
(* <definition of [[valueString]] for \uscheme, \tuscheme, and \nml>= *)
fun valueString (SYM v)   = v
  | valueString (NUM n)   = intString n
  | valueString (BOOLV b) = if b then "#t" else "#f"
  | valueString (NIL)     = "()"
  | valueString (PAIR (car, cdr))  = 
      let fun tail (PAIR (car, cdr)) = " " ^ valueString car ^ tail cdr
            | tail NIL = ")"
            | tail v = " . " ^ valueString v ^ ")"
(* The rest of this section defines utility functions on *)
(* values.                                      *)
(*                                              *)
(* String conversion                            *)
(*                                              *)
(* Instead of [[printf]], ML provides functions that can *)
(* create, manipulate, and combine strings. So instead *)
(* using something like \crefimpcore.chap's extensible *)
(* [[print]] function, this chapter builds strings using *)
(* string-conversion functions. One example,    *)
(* [[valueString]], which converts an ML [[value]] to a *)
(* string, is shown here. The other string-conversion *)
(* functions are relegated to the Supplement.   *)
(*                                              *)
(* Function [[valueString]] is primarily concerned with *)
(* S-expressions. An atom is easily converted, but a *)
(* list made up of cons cells ([[PAIR]]s) requires care; *)
(* the [[cdr]] is converted by a recursive function, *)
(* [[tail]], which implements the same list-printing *)
(* algorithm as the C code. (The algorithm, which goes *)
(* back to McCarthy, is implemented by C function *)
(* [[printtail]] on \cpagerefschemea.printtail.imp.) *)
(* Function [[tail]] is defined inside [[valueString]], *)
(* with which it is mutually recursive. [*]     *)
(* <boxed values 2>=                            *)
val _ = op valueString : value -> string
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

      in  "(" ^ valueString car ^ tail cdr
      end
  | valueString (CLOSURE   _) = "<function>"
  | valueString (PRIMITIVE _) = "<function>"
(* Function [[valueString]] demonstrates pattern *)
(* matching. It takes one argument and does a case *)
(* analysis on its form. Each case corresponds to a *)
(* clause in the definition of [[valueString]]; there is *)
(* one clause for each datatype constructor of the *)
(* [[value]] type. On the left of the [[=]], each clause *)
(* contains a pattern that applies a datatype   *)
(* constructor to a variable, to a pair of variables, or *)
(* to the special ``wildcard'' pattern [[_]]    *)
(* (the underscore). Each variable, but not the *)
(* wildcard, is introduced into the environment and is *)
(* available for use on the right-hand side of  *)
(* the clause, just as if it had been bound by a *)
(* micro-Scheme [[let]] or ML [[val]].          *)
(*                                              *)
(* From the point of view of a C programmer, a pattern *)
(* match combines a [[switch]] statement with assignment *)
(* to local variables. The notation is sweet; for *)
(* example, in the matches for [[BOOLV]] and [[PAIR]], *)
(* I like [[b]] and [[car]] much better than the *)
(* [[v.u.boolv]] and [[v.u.pair.car]] that I have to *)
(* write in C. And I really like that the variables *)
(* [[b]] and [[car]] can be used only where they are *)
(* meaningful—in C, [[v.u.pair.car]] is accepted *)
(* whenever [[v]] has type [[Value]], but if [[v]] isn't *)
(* a pair, the reference to its [[car]] is meaningless *)
(* (and to evaluate it is an unchecked run-time error). *)
(* In ML, only meaningful references are accepted. *)
(*                                              *)
(* Embedding and projection                     *)
(*                                              *)
(* [*] Inside the interpreter, micro-Scheme values *)
(* sometimes need to be converted to or from ML values *)
(* of other types.                              *)
(*                                              *)
(*   • When it sees a quote mark and brackets, the *)
(*  parser defined in the Supplement produces a *)
(*  native ML list of S-expressions represented by a *)
(*  combination of [[[]]] and [[::]]. But the   *)
(*  evaluator needs a micro-Scheme list represented *)
(*  by a combination of [[NIL]] and [[PAIR]].   *)
(*   • When it evaluates a condition in a micro-Scheme *)
(*  [[if]] expression, the evaluator produces a *)
(*  micro-Scheme value. But to test that value with *)
(*  a native ML [[if]] expression, the evaluator *)
(*  needs a native ML Boolean.                  *)
(*                                              *)
(* Such needs are met by using functions that convert *)
(* values from one language to another. Similar needs *)
(* arise whenever one language is used to implement or *)
(* describe another, and to keep two such languages *)
(* straight, we typically resort to jargon:     *)
(*                                              *)
(*   • The language being implemented or described—in *)
(*  our case, micro-Scheme—is called the object *)
(*  language.                                   *)
(*   • The language doing the describing or   *)
(*  implementation—in our case, ML—is called the *)
(*  metalanguage. (The name ML actually stands for *)
(*  ``metalanguage.'')                          *)
(*                                              *)
(* To convert, say, an integer between object language *)
(* and metalanguage, we use a pair of functions called *)
(* embedding and projection. The embedding puts a *)
(* metalanguage integer into the object language, *)
(* converting an [[int]] into a [[value]].      *)
(* The projection extracts a metalanguage integer from *)
(* the object language, converting a [[value]] into an  *)
(* [[int]]. If the [[value]] can't be interpreted as an *)
(* integer, the projection fails. [In general, we embed *)
(* a smaller set into a larger set. Embeddings don't *)
(* fail, but projections might. A mathematician would *)
(* say that an embedding e of S into S' is an injection *)
(* from S-->S'. The corresponding projection pi_e is a *)
(* left inverse of the embedding; that is pi_e oe is the *)
(* identity function on S. There is no corresponding *)
(* guarantee for e opi_e; for example, pi_e may be *)
(* undefined (_|_) on some elements of S', or e(pi_e(x)) *)
(*  may not equal x. ] The embedding/projection pair for *)
(* integers is defined as follows:              *)

(* <definition of [[expString]] for \uscheme>=  *)
fun expString e =
  let fun bracket s = "(" ^ s ^ ")"
      val bracketSpace = bracket o spaceSep
      fun exps es = map expString es
      fun withBindings (keyword, bs, e) =
        bracket (spaceSep [keyword, bindings bs, expString e])
      and bindings bs = bracket (spaceSep (map binding bs))
      and binding (x, e) = bracket (x ^ " " ^ expString e)
      val letkind = fn LET => "let" | LETSTAR => "let*" | LETREC => "letrec"
  in  case e
        of LITERAL (v as NUM   _) => valueString v
         | LITERAL (v as BOOLV _) => valueString v
         | LITERAL v => "'" ^ valueString v
         | VAR name => name
         | SET (x, e) => bracketSpace ["set", x, expString e]
         | IFX (e1, e2, e3) => bracketSpace ("if" :: exps [e1, e2, e3])
         | WHILEX (cond, body) =>
                         bracketSpace ["while", expString cond, expString body]
         | BEGIN es => bracketSpace ("begin" :: exps es)
         | APPLY (e, es) => bracketSpace (exps (e::es))
         | LETX (lk, bs, e) => bracketSpace [letkind lk, bindings bs, expString
                                                                              e]
         | LAMBDA (xs, body) => bracketSpace ["lambda", bracketSpace xs,
                                                                 expString body]
  end
(* \qbreak The [[                               *)
(*                                              *)
(* ( ***************************************************************** ) *)
(* ( * * ) ( * ABSTRACT SYNTAX AND VALUES FOR \USCHEME* ) ( * *)
(* * )                                          *)
(* ( ***************************************************************** ) *)
(*                                              *)
(* ]] is                                        *)
(* itself defined as a sequence of smaller chunks. *)
(* <boxed values 124>=                          *)
val _ = op valueString      : value -> string
val _ = op expString        : exp   -> string
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)



(*****************************************************************)
(*                                                               *)
(*   UTILITY FUNCTIONS ON VALUES ({\FOOTNOTESIZE \USCHEME, \TUSCHEME, \NML}) *)
(*                                                               *)
(*****************************************************************)

(* <utility functions on values ({\footnotesize \uscheme, \tuscheme, \nml})>= *)
fun embedInt n = NUM n
fun projectInt (NUM n) = n
  | projectInt v =
      raise RuntimeError ("value " ^ valueString v ^ " is not an integer")
(* <boxed values 3>=                            *)
val _ = op embedInt   : int   -> value
val _ = op projectInt : value -> int
(* <utility functions on values ({\footnotesize \uscheme, \tuscheme, \nml})>= *)
fun embedBool b = BOOLV b
fun projectBool (BOOLV false) = false
  | projectBool _             = true
(* <boxed values 4>=                            *)
val _ = op embedBool   : bool  -> value
val _ = op projectBool : value -> bool
(* <utility functions on values ({\footnotesize \uscheme, \tuscheme, \nml})>= *)
fun embedList []     = NIL
  | embedList (h::t) = PAIR (h, embedList t)
(* <utility functions on values ({\footnotesize \uscheme, \tuscheme, \nml})>= *)
fun equalatoms (NIL,      NIL    )  = true
  | equalatoms (NUM  n1,  NUM  n2)  = (n1 = n2)
  | equalatoms (SYM  v1,  SYM  v2)  = (v1 = v2)
  | equalatoms (BOOLV b1, BOOLV b2) = (b1 = b2)
  | equalatoms  _                   = false
(* Different interpreters need different utility *)
(* functions, but they all need an implementation of *)
(* equality that can be used in [[check-expect]]. And *)
(* the micro-Scheme interpreter also needs an   *)
(* implementation of primitive equality. Primitive *)
(* equality permits only atoms to be considered equal. *)
(* <boxed values 125>=                          *)
val _ = op equalatoms : value * value -> bool
(* In a unit test written with [[check-expect]], lists *)
(* are compared for equality structurally, the way the *)
(* micro-Scheme function [[equal?]] does.       *)

(* <utility functions on values ({\footnotesize \uscheme, \tuscheme, \nml})>= *)
fun equalpairs (PAIR (car1, cdr1), PAIR (car2, cdr2)) =
      equalpairs (car1, car2) andalso equalpairs (cdr1, cdr2)
  | equalpairs (v1, v2) = equalatoms (v1, v2)
(* <boxed values 126>=                          *)
val _ = op equalpairs : value * value -> bool
(* The testing infrastructure expects this function to *)
(* be called [[testEquals]].                    *)

(* <utility functions on values ({\footnotesize \uscheme, \tuscheme, \nml})>= *)
val testEquals = equalpairs
(* <boxed values 127>=                          *)
val _ = op testEquals : value * value -> bool
(* <utility functions on values ({\footnotesize \uscheme, \tuscheme, \nml})>= *)
fun cycleThrough xs =
  let val remaining = ref xs
      fun next () = case !remaining
                      of [] => (remaining := xs; next ())
                       | x :: xs => (remaining := xs; x)
  in  if null xs then
        raise InternalError "empty list given to cycleThrough"
      else
        next
  end
val unspecified =
  cycleThrough [ BOOLV true, NUM 39, SYM "this value is unspecified", NIL
               , PRIMITIVE (fn _ => raise RuntimeError "unspecified primitive")
               ]
(* <boxed values 149>=                          *)
val _ = op cycleThrough : 'a list -> (unit -> 'a)
val _ = op unspecified  : unit -> value
(* Scheme, S-expressions, and first-class functions *)
(*                                              *)
(* [*] \invisiblelocaltableofcontents[*]        *)
(*                                              *)
(* \minibasison                                 *)
(*                                              *)
(* \notationgroupmicro-Scheme \makenowebnotdef(generated *)
(* automatically)                               *)
(*                                              *)




(*****************************************************************)
(*                                                               *)
(*   LEXICAL ANALYSIS AND PARSING FOR \USCHEME, PROVIDING [[FILEXDEFS]] AND [[STRINGSXDEFS]] *)
(*                                                               *)
(*****************************************************************)

(* To redefine [[print]], send                  *)
(* [[addSelector:withMethod:]] to class [[Float]] with *)
(* two arguments: the literal symbol [['print]] and a *)
(* [[compiled-method]] expression with the new method *)
(* definition.                                  *)
(*                                              *)
(* Establish a new invariant for class [[CoordPair]]: *)
(* that the values of instance variables [[x]] and [[y]] *)
(* are always numbers of class [[Float]]. Modify only *)
(* methods of class [[CoordPair]], not methods of any *)
(* other class.                                 *)
(*                                              *)
(* Make sure the public methods of class [[CoordPair]] *)
(* work with arguments of any numeric class, not just *)
(* integers or [[Float]]s.                      *)
(*                                              *)
(* [*] More informative [[print]] method for pictures. *)
(* The [[print]] method of class [[Picture]] would be *)
(* more interesting if it showed the shapes inside the *)
(* picture, like so:                            *)
(*                                              *)
(*   -> pic                                     *)
(*   Picture ( <Circle> <Square> <Triangle> )   *)
(*                                              *)
(* Make it so. (You might wish to study the [[print]] *)
(* method for class [[Collection]].)            *)
(* <lexical analysis and parsing for \uscheme, providing [[filexdefs]] and [[stringsxdefs]]>= *)
(* <lexical analysis for \uscheme\ and related languages>= *)
datatype pretoken = QUOTE
                  | INT     of int
                  | SHARP   of bool
                  | NAME    of string
type token = pretoken plus_brackets
(* <boxed values 132>=                          *)
type pretoken = pretoken
type token = token
(* <lexical analysis for \uscheme\ and related languages>= *)
fun pretokenString (QUOTE)     = "'"
  | pretokenString (INT  n)    = intString n
  | pretokenString (SHARP b)   = if b then "#t" else "#f"
  | pretokenString (NAME x)    = x
val tokenString = plusBracketsString pretokenString
(* For debugging, code in \creflazyparse.chap needs to *)
(* be able to render a [[token]] as a string.   *)
(* <boxed values 133>=                          *)
val _ = op pretokenString : pretoken -> string
val _ = op tokenString    : token    -> string
(* <lexical analysis for \uscheme\ and related languages>= *)
local
  (* <functions used in all lexers>=              *)
  fun noneIfLineEnds chars =
    case streamGet chars
      of NONE => NONE (* end of line *)
       | SOME (#";", cs) => NONE (* comment *)
       | SOME (c, cs) => 
           let val msg = "invalid initial character in `" ^
                         implode (c::listOfStream cs) ^ "'"
           in  SOME (ERROR msg, EOS)
           end
  (* <boxed values 135>=                          *)
  val _ = op noneIfLineEnds : 'a lexer
  (* The [[atom]] function identifies the special literals *)
  (* [[#t]] and [[#f]]; all other atoms are names. *)
  (* <functions used in the lexer for \uscheme>=  *)
  fun atom "#t" = SHARP true
    | atom "#f" = SHARP false
    | atom x    = NAME x
in
  val schemeToken =
    whitespace *>
    bracketLexer   (  QUOTE   <$  eqx #"'" one
                  <|> INT     <$> intToken isDelim
                  <|> (atom o implode) <$> many1 (sat (not o isDelim) one)
                  <|> noneIfLineEnds
                   )
(* <boxed values 134>=                          *)
val _ = op schemeToken : token lexer
val _ = op atom : string -> pretoken
(* [[checkExpectPasses]] runs a                 *)
(* [[check-expect]] test and tells if the test passes. *)
(* If the test does not pass, [[checkExpectPasses]] also *)
(* writes an error message. Error messages are written *)
(* using [[failtest]], which, after writing the error *)
(* message, indicates failure by returning [[false]]. *)

end
(* <parsers for single tokens for \uscheme-like languages>= *)
type 'a parser = (token, 'a) polyparser
val pretoken  = (fn (PRETOKEN t)=> SOME t  | _ => NONE) <$>? token : pretoken
                                                                          parser
val quote     = (fn (QUOTE)     => SOME () | _ => NONE) <$>? pretoken
val int       = (fn (INT   n)   => SOME n  | _ => NONE) <$>? pretoken
val booltok   = (fn (SHARP b)   => SOME b  | _ => NONE) <$>? pretoken
val namelike  = (fn (NAME  n)   => SOME n  | _ => NONE) <$>? pretoken
val namelike  = asAscii namelike
(* Parsers for micro-Scheme                     *)
(*                                              *)
(* A parser consumes a stream of tokens and produces an *)
(* abstract-syntax tree. My parsers begin with code for *)
(* parsing the smallest things and finish with the code *)
(* for parsing the biggest things. I define parsers for *)
(* tokens, literal S-expressions, micro-Scheme  *)
(* expressions, and finally micro-Scheme definitions. *)
(*                                              *)
(* Parsers for single tokens and common idioms  *)
(*                                              *)
(* Usually a parser knows what kind of token it is *)
(* looking for. To make such a parser easier to write, *)
(* I define a special parsing combinator for each kind *)
(* of token. Each one succeeds when given a token of the *)
(* kind it expects; when given any other token, it *)
(* fails.                                       *)
(* <boxed values 136>=                          *)
val _ = op booltok  : bool parser
val _ = op int      : int  parser
val _ = op namelike : name parser
(* [[bindList]] tried to                        *)
(*              extend an environment, but it passed *)
(*              two lists (names and values) of *)
(*              different lengths.              *)
(* RuntimeError    Something else went wrong during *)
(*              evaluation, i.e., during the    *)
(*              execution of [[eval]].          *)
(* \bottomrule                                  *)
(*                                              *)
(* Exceptions defined especially for this interpreter  *)
(* [*]                                          *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* Abstract syntax and values                   *)
(*                                              *)
(* An abstract-syntax tree can contain a literal value. *)
(* A value, if it is a closure, can contain an  *)
(* abstract-syntax tree. These two types are therefore *)
(* mutually recursive, so I define them together, using *)
(* [[and]].                                     *)
(*                                              *)
(* These particular types use as complicated a nest of *)
(* definitions as you'll ever see. The keyword  *)
(* [[datatype]] defines a new algebraic datatype; the *)
(* keyword [[withtype]] introduces a new type   *)
(* abbreviation that is mutually recursive with the *)
(* [[datatype]]. The first group of [[and]] keywords *)
(* define additional algebraic datatypes, and the second *)
(* group of [[and]] keywords define additional type *)
(* abbreviations. Everything in the whole nest is *)
(* mutually recursive. [*] [*]                  *)

(* A [[namelike]] parser accepts any name, as long as *)
(* the name is made up only of printing ASCII   *)
(* characters. But it also accepts reserved words, and *)
(* reserved words must not be accepted as names. *)
(* <parsers for \uscheme\ tokens>=              *)
val reserved = [ "if", "while", "set", "begin", "lambda", "let"
               , "letrec", "let*", "quote", "val", "define", "use"
               , "check-expect", "check-assert", "check-error"
               ]
val name = rejectReserved reserved <$>! namelike
(* <parsers and parser builders for formal parameters and bindings>= *)
fun formalsOf what name context = 
  nodups ("formal parameter", context) <$>! @@ (bracket (what, many name))

fun bindingsOf what name exp =
  let val binding = bracket (what, pair <$> name <*> exp)
  in  bracket ("(... " ^ what ^ " ...) in bindings", many binding)
  end
(* <parsers and parser builders for formal parameters and bindings>= *)
fun distinctBsIn bindings context =
  let fun check (loc, bs) =
        nodups ("bound name", context) (loc, map fst bs) >>=+ (fn _ => bs)
  in  check <$>! @@ bindings
  end
(* <boxed values 137>=                          *)
val _ = op formalsOf  : string -> name parser -> string -> name list parser
val _ = op bindingsOf : string -> 'x parser -> 'e parser -> ('x * 'e) list
                                                                          parser
(* <boxed values 137>=                          *)
val _ = op distinctBsIn : (name * 'e) list parser -> string -> (name * 'e) list
                                                                          parser
(* <parsers and parser builders for formal parameters and bindings ((higher-order))>= *)
fun asLambda inWhat (loc, e as LAMBDA _) = OK e
  | asLambda inWhat (loc, e) = 
      synerrorAt ("in " ^ inWhat ^ ", expression " ^ expString e ^ 
                  " is not a lambda")
                 loc

val asLambda = fn what => fn eparser => asLambda what <$>! @@ eparser
(* A [[letrec]] may bind only lambda expressions. *)
(* <boxed values 138>=                          *)
val _ = op asLambda : string -> exp parser -> exp parser
(* <parsers and parser builders for formal parameters and bindings>= *)
fun recordFieldsOf name =
  nodups ("record fields", "record definition") <$>!
                                    @@ (bracket ("(field ...)", many name))
(* <boxed values 139>=                          *)
val _ = op recordFieldsOf : name parser -> name list parser
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <parsers and parser builders for formal parameters and bindings>= *)
fun kw keyword = 
  eqx keyword namelike
fun usageParsers ps = anyParser (map (usageParser kw) ps)
(* To define a parser for the bracketed expressions, *)
(* I deploy the ``usage parser'' described in \cref *)
(* lazyparse.chap. It enables me to define most of the *)
(* parser as a table containing usage strings and *)
(* functions. Function [[kw]] parses only the keyword *)
(* passed as an argument. Using it, function    *)
(* [[usageParsers]] strings together usage parsers. *)
(* <boxed values 141>=                          *)
val _ = op kw : string -> string parser
val _ = op usageParsers : (string * 'a parser) list -> 'a parser
(* <parsers and parser builders for \scheme-like syntax>= *)
fun sexp tokens = (
     SYM       <$> (notDot <$>! @@ namelike)
 <|> NUM       <$> int
 <|> embedBool <$> booltok
 <|> leftCurly <!> "curly brackets may not be used in S-expressions"
 <|> embedList <$> bracket ("list of S-expressions", many sexp)
 <|> (fn v => embedList [SYM "quote", v]) 
               <$> (quote *> sexp)
) tokens
and notDot (loc, ".") =
      synerrorAt "this interpreter cannot handle . in quoted S-expressions" loc
  | notDot (_,   s)   = OK s
(* With this machinery I can define a parser for quoted *)
(* S-expressions. A quoted S-expression is a symbol, *)
(* a number, a Boolean, a list of S-expressions, or a *)
(* quoted S-expression.                         *)
(* <boxed values 140>=                          *)
val _ = op sexp : value parser
(* Full Scheme allows programmers to notate arbitrary *)
(* cons cells using a dot in a quoted S-expression. *)
(* micro-Scheme doesn't.                        *)

(* Parsers for micro-Scheme expressions         *)
(*                                              *)
(* I define distinct parses for atomic expressions *)
(* (which aren't recursively defined) and bracketed *)
(* expressions (which are recursively defined). *)
(* An atomic expression is a variable or a literal. *)
(* <parsers and parser builders for \scheme-like syntax>= *)
fun atomicSchemeExpOf name =  VAR                   <$> name
                          <|> LITERAL <$> NUM       <$> int
                          <|> LITERAL <$> embedBool <$> booltok
(* <parsers and parser builders for \scheme-like syntax>= *)
fun fullSchemeExpOf atomic bracketedOf =
  let val exp = fn tokens => fullSchemeExpOf atomic bracketedOf tokens
  in      atomic
      <|> bracketedOf exp
      <|> quote *> (LITERAL <$> sexp)
      <|> quote *> badRight "quote ' followed by right bracket"
      <|> leftCurly <!> "curly brackets are not supported"
      <|> left *> right <!> "(): unquoted empty parentheses"
      <|> bracket("function application", curry APPLY <$> exp <*> many exp)
  end
(* <boxed values 143>=                          *)
val _ = op fullSchemeExpOf : exp parser -> (exp parser -> exp parser) -> exp
                                                                          parser
(* <parsers and [[xdef]] streams for \uscheme>= *)
fun exptable exp =
  let val bindings = bindingsOf "(x e)" name exp
      val formals  = formalsOf "(x1 x2 ...)" name "lambda"
      val dbs      = distinctBsIn bindings
      val letrecbs =
        distinctBsIn
            (bindingsOf "[f (lambda (...) ...)]" name (asLambda "letrec" exp))
            "letrec"
(* The [[exptable]] itself uses the format described in *)
(* \crefpage(lazyparse.code.usageParser: each   *)
(* alternative is specified by a pair containing a usage *)
(* string and a parser.                         *)
(* <boxed values 142>=                          *)
val _ = op exptable  : exp parser -> exp parser
val _ = op exp       : exp parser
val _ = op bindings  : (name * exp) list parser
  in usageParsers
     [ ("(if e1 e2 e3)",            curry3 IFX    <$> exp <*> exp <*> exp)
     , ("(while e1 e2)",            curry  WHILEX <$> exp  <*> exp)
     , ("(set x e)",                curry  SET    <$> name <*> exp)
     , ("(begin e1 ...)",                  BEGIN  <$> many exp)
     , ("(lambda (names) body)",    curry  LAMBDA <$> formals <*> exp)
     , ("(let (bindings) body)",    curry3 LETX LET     <$> dbs  "let" <*> exp)
     , ("(letrec (bindings) body)", curry3 LETX LETREC  <$> letrecbs   <*> exp)
     , ("(let* (bindings) body)",   curry3 LETX LETSTAR <$> bindings   <*> exp)
     , ("(quote sexp)",             LITERAL             <$> sexp)

    (* <rows added to ML \uscheme's [[exptable]] in exercises ((prototype))>= *)
     , ("(cond ([q a] ...))",
        let fun desugarCond qas = raise LeftAsExercise "desugar cond"
            val qa = bracket ("[question answer]", pair <$> exp <*> exp)
     (* The remaining type predicates, the list primitives, *)
     (* and the printing primitives are defined in \cref *)
     (* mlschemea.chap.                              *)
     (*                                              *)
     (* Notable differences \maintocsplit\chaptocsplitbetween *)
     (* ML and C                                     *)
     (*                                              *)
     (* [*] The ML interpreter presented in \cref    *)
     (* mlscheme.eval,mlscheme.primitives uses the same *)
     (* overall design as the C interpreters of \cref *)
     (* impcore.chap,scheme.chap. But the many small *)
     (* differences in the two languages add up to a *)
     (* different programming experience; the ML version is *)
     (* more compact and more reliable. The two experiences *)
     (* compare as follows:                          *)
     (*                                              *)
     (*   • Both interpreters allocate mutable locations on *)
     (*  the heap, which they operate on with C pointer *)
     (*  syntax ([[*]]) or ML primitive functions ([[!]] *)
     (*   and [[:=]]). The C code leaks memory like crazy; *)
     (*  plugging all the leaks would require a garbage *)
     (*  collector considerably more elaborate than the *)
     (*  one in \crefgc.chap. ML ships with a        *)
     (*  comprehensive garbage collector built in.   *)
     (*                                              *)
     (*   • Both interpreters use the same abstraction to *)
     (*  represent abstract syntax trees: a tagged sum of *)
     (*  products. Thanks to the little data-description *)
     (*  language of \crefimpcore.chap, the          *)
     (*  representations are even specified similarly. But *)
     (*  C's unions are unsafe: making the [[alt]] tag *)
     (*  consistent with the payload is up to the    *)
     (*  programmer. ML's algebraic data types guarantee *)
     (*  consistency. The C code does offer one advantage, *)
     (*  however: in the source code, the definitions of \ *)
     (*  monostruct Value and \monostruct Exp can appear *)
     (*  separately. In the ML code, the definitions *)
     (*  [[value]] and [[exp]], because they are mutually *)
     (*  recursive, must appear adjacent in the source *)
     (*  code so they can be connected with [[and]]. *)
     (*                                              *)
     (*   • Both interpreters manage run-time errors in the *)
     (*  same way. An error may be detected and signaled *)
     (*  anywhere; C code uses [[runerror]], which calls *)
     (*  [[longjmp]] (in C), and ML code uses [[raise]]. *)
     (*  And in both interpreters, an error once detected *)
     (*  is handled in a central place, using [[setjmp]] *)
     (*  or [[handle]], as described in the Supplement. *)
     (*                                              *)
     (*   • Both interpreters use functions, like ``length of *)
     (*  a list'' and ``find a name in an environment,'' *)
     (*  that could in principle be polymorphic. But only *)
     (*  ML code can define a function that is actually *)
     (*  polymorphic. The C code in \cref            *)
     (*  impcore.chap,scheme.chap must define a new length *)
     (*  function for every type of list and a new find *)
     (*  function for every type of environment.     *)
     (*   • C code can use [[printf]], and it can even define *)
     (*  new functions that resemble [[printf]], like *)
     (*  [[print]]. ML code has nothing comparable:  *)
     (*  because the ML type checker won't check the types *)
     (*  of the arguments based on a format string,  *)
     (*  ML code can only print strings—so it must use *)
     (*  string-conversion functions.                *)
     (*   • To define primitives, both interpreters use *)
     (*  first-order embedding and projection functions to *)
     (*  embed and project numbers ([[projectint32]] and *)
     (*  [[mkNum]] or [[projectInt]] and [[embedInt]]) and *)
     (*  Booleans. But only the ML code can embed    *)
     (*  functions, using [[binaryOp]], [[intcompare]], *)
     (*  and so on. And in ML, operations like [[/]] and *)
     (*  [[div]] are functions, not syntax, so they can be *)
     (*  embedded into micro-Scheme directly. Their  *)
     (*  counterparts in C require significant ``glue *)
     (*  code.''                                     *)
     (*                                              *)
     (* Free and bound variables\cull: \             *)
     (* chaptocbacksplitDeeper into micro-Scheme     *)
     (*                                              *)
     (* [*] The ML implementation of micro-Scheme is easier *)
     (* to modify than the C version. And no matter what *)
     (* mistakes you make, the ML code cannot dump core or *)
     (* fail with inexplicable pointer errors. These *)
     (* properties make ML a good vehicle for exploring *)
     (* techniques that are actually used to implement *)
     (* functional languages (\                      *)
     (* crefpage,mlscheme.ex.closure-proof,mlscheme.ex.closure-code). *)
     (* These techniques rely on a crucial concept in *)
     (* programming languages: the distinction between free *)
     (* and bound variables.                         *)
     (*                                              *)
     (* When an expression e refers to a name y that is *)
     (* introduced outside of e, we say that y is free in e. *)
     (* Such names are called ``free variables,'' even though *)
     (* ``free names'' would be more accurate. A variable in  *)
     (* e that is introduced within e is a bound variable. *)
     (* For example, in the expression               *)
     (*                                              *)
     (*   (lambda (n) (+ 1 n))                       *)
     (*                                              *)
     (* the name [[+]] is a free variable, but [[n]] is a *)
     (* bound variable. Every variable that appears in an *)
     (* expression is either free or bound.          *)
     (*                                              *)
     (* Each variable that appears in a definition is also *)
     (* free or bound. For example, in               *)
     (*                                              *)
     (*   (define map (f xs)                         *)
     (*  (if (null? xs)                              *)
     (*    '()                                       *)
     (*    (cons (f (car xs)) (map f (cdr xs)))))    *)
     (*                                              *)
     (* the names [[null?]], [[cons]], [[car]], and [[cdr]] *)
     (* are free, and the names [[map]], [[f]], and [[xs]] *)
     (* are bound. (And [[if]] is not a name; it is a  *)
     (* reserved word that, like [[if]] in ML or C, marks a *)
     (* syntactic form.)                             *)
     (*                                              *)
     (* Free variables enable compilers to represent closures *)
     (* efficiently. According to the operational semantics, *)
     (* evaluating a [[lambda]] expression captures the  *)
     (* entire environment rho_c: \ops. MkClosure \ldotsnx *)
     (* all distinct <\xlambda(<x_1, ..., x_n>, e), rho_c, *)
     (* sigma> ==> \schemeevalr\vclo\xlambda(<x_1, ..., x_n>, *)
     (* e)rho_c Does the closure really need all the *)
     (* information in rho_c? How is rho_c used?[*] \ops *)
     (* ApplyClosure \sixline l_1, ..., l_n \notindom sigma_n *)
     (* (and all distinct) \schemeevale ==>\schemeevalr[_0]\ *)
     (* vclo\xlambda(<x_1, ..., x_n>, e_c)rho_c \schemeeval *)
     (* [_0]e_1 ==>\schemeevalr[_1]v_1 ... \schemeeval[_n-1] *)
     (* e_n ==>\schemeevalr[_n]v_n \se_crho_c{x_1|->l_1, ..., *)
     (* x_n|->l_n} sigma_n{l_1|->v_1, ..., l_n |->v_n} ==>\ *)
     (* schemeevalr[']v \schemeeval\xapply(e, e_1, ..., e_n) *)
     (* ==>\schemeevalr[']v Environment rho_c is used only to *)
     (* evaluate the body of the lambda. So the \    *)
     (* rulenameMkClosure rule need not store all of rho_c—it *)
     (* needs only those bindings that refer to variables *)
     (* that are free in the lambda expression (\    *)
     (* exrefmlscheme.ex.closure-proof). You can use this *)
     (* fact to make the interpreter faster (\       *)
     (* exrefmlscheme.ex.closure-code).              *)
     (*                                              *)
     (* To do \                                      *)
     (* crefmlscheme.ex.closure-proof,mlscheme.ex.closure-code, *)
     (* you need a precise definition of what a free *)
     (* variable is. And precision calls for formal judgments *)
     (* and proofs. The judgment form for identifying free *)
     (* variables in an expression is \freeiny e. [*]\ *)
     (* jlabeluscheme.free.expy in \fv(e) The notation \fv(e) *)
     (* refers to the set of all variables that appear free *)
     (* in e, but constructing the set is not necessary, and *)
     (* the judgment \freeiny e should be pronounced as ``y *)
     (*  appears free in e.'' The judgment may be provable in *)
     (* different ways for each syntactic form.      *)
     (*                                              *)
     (* A literal expression has no free variables. Formally *)
     (* speaking, no judgment of the form \freeiny \xliteral *)
     (* (v) can ever be proved, so there is no rule for *)
     (* literals.                                    *)
     (*                                              *)
     (* A lone variable x is always free. {mathpar} \ *)
     (* inferrule \freeinx \xvar(x) {mathpar}        *)
     (*                                              *)
     (* A variable is free in a \xset expression if it is *)
     (* assigned to or if it is free in the right-hand side. *)
     (* So a \xset expression has two proof rules: {mathpar} *)
     (* \inferrule \freeinx \xset(x, e)              *)
     (*                                              *)
     (* \inferrule\freeiny e \freeiny \xset(x, e)\fracsuffix. *)
     (* {mathpar}                                    *)
     (*                                              *)
     (* A variable is free in an \xif expression if and only *)
     (* if it is free in one of the subexpressions: {mathpar} *)
     (* \inferrule\freeiny e_1 \freeiny \xif(e_1, e_2, e_3) *)
     (*                                              *)
     (* \inferrule\freeiny e_2 \freeiny \xif(e_1, e_2, e_3) *)
     (*                                              *)
     (* \inferrule\freeiny e_3 \freeiny \xif(e_1, e_2, e_3)\ *)
     (* fracsuffix. {mathpar}                        *)
     (*                                              *)
     (* A variable is also free in a \xwhile expression if *)
     (* and only if it is free in one of the subexpressions: *)
     (* {mathpar} \inferrule\freeiny e_1 \freeiny \xwhile *)
     (* (e_1, e_2)                                   *)
     (*                                              *)
     (* \inferrule\freeiny e_2 \freeiny \xwhile(e_1, e_2)\ *)
     (* fracsuffix. {mathpar} And the same for \xbegin: *)
     (* {mathpar} \inferrule\freeiny e_i \freeiny \xbegin(\ *)
     (* ldotsne)\fracsuffix. {mathpar}               *)
     (*                                              *)
     (* A variable is free in an application if and only if *)
     (* it is free in the function or in one of the  *)
     (* arguments: {mathpar} \inferrule\freeiny e \freeiny \ *)
     (* xapply(e, \ldotsne)                          *)
     (*                                              *)
     (* \inferrule\freeiny e_i \freeiny \xapply(e, \ldotsne)\ *)
     (* fracsuffix. {mathpar}                        *)
     (*                                              *)
     (* Finally, an interesting case! A variable is free in a *)
     (* \xlambda expression if it is free in the body and it *)
     (* is not one of the arguments: {mathpar} \inferrule\ *)
     (* freeiny e                                    *)
     (* y \notin{\ldotsnx} \freeiny \xlambda(<\ldotsnx>, e)\ *)
     (* fracsuffix. {mathpar}                        *)
     (*                                              *)
     (* The various \xlet forms require care. A variable is *)
     (* free in an ordinary \xlet if it is free in the *)
     (* right-hand side of any binding, or if it is both free *)
     (* in the body and not bound by the \xlet. {mathpar} \ *)
     (* inferrule\freeiny e_i \freeiny \xlet         *)
     (* (<x_1,e_1,...,x_n,e_n>, e)                   *)
     (*                                              *)
     (* \inferrule\freeiny e                         *)
     (* y \notin{\ldotsnx} \freeiny \xlet            *)
     (* (<x_1,e_1,...,x_n,e_n>, e) {mathpar} The similarity *)
     (* between the second \xlet rule and the \xlambda rule *)
     (* shows a kinship between \xlet and \xlambda.  *)
     (*                                              *)
     (* The rules for \xletrec are almost identical to the *)
     (* rules for \xlet, except that in a \xletrec, the bound *)
     (* names x_i are never free: {mathpar} \inferrule\ *)
     (* freeiny e_i                                  *)
     (* y \notin{\ldotsnx} \freeiny \xletrec         *)
     (* (<x_1,e_1,...,x_n,e_n>, e)\fracsuffix,       *)
     (*                                              *)
     (* \inferrule\freeiny e                         *)
     (* y \notin{\ldotsnx} \freeiny \xletrec         *)
     (* (<x_1,e_1,...,x_n,e_n>, e)\fracsuffix. {mathpar} *)
     (*                                              *)
     (* As usual, a \xletstar rule would be a nuisance to *)
     (* write directly. Instead, I treat a \xletstar *)
     (* expression as a set of nested \xlet expressions, each *)
     (* containing just one binding. And an empty \xletstar *)
     (* behaves just like its body. {mathpar} \inferrule\ *)
     (* freeiny \xlet(<x_1, e_1>, \xletstar          *)
     (* (<x_2,e_2,...,x_n,e_n>, e)) \freeiny \xletstar *)
     (* (<x_1,e_1,...,x_n,e_n>, e)                   *)
     (*                                              *)
     (* \inferrule\freeiny e \freeiny \xletstar(<>, e) *)
     (* {mathpar}                                    *)
     (*                                              *)
     (* Summary                                      *)
     (*                                              *)
     (* By exploiting algebraic data types, pattern matching, *)
     (* higher-order functions, and exceptions, we can make *)
     (* interpreters that are simpler, smaller, easier to *)
     (* read, more reliable, and more flexible than  *)
     (* interpreters we can write in C.              *)
     (*                                              *)
     (* Key words and phrases                        *)
     (*                                              *)
     (* {nrglossary}micro-Scheme in ML \glossAlgebraic data *)
     (* type A representation defined by a set of \ugvalue *)
     (* constructors. Every value of the type is made by *)
     (* using or applying one of the type's value    *)
     (* constructors. An algebraic data type is defined with *)
     (* the keyword [[datatype]]. Mutually recursive *)
     (* algebraic data types are defined with an initial *)
     (* [[datatype]], and individual definitions are *)
     (* separated by keyword [[and]]. \gloss*Bound variable *)
     (* A variable introduced by a function definition or *)
     (* other construct and whose meaning is independent of *)
     (* any appearance of its name outside the construct. *)
     (* Formal parameters of functions are bound variables, *)
     (* as are variables introduced by [[let]] forms. *)
     (* Variables that aren't bound are \ugfree. The name of *)
     (* a bound variable can be changed without changing the *)
     (* meaning of the program, provided the new name does *)
     (* not conflict with any variable that is free in the *)
     (* scope of the binding. \glossClausal definition A *)
     (* syntactic form of definition that combines a function *)
     (* definition and a \ugpattern match. It is introduced *)
     (* with the keyword [[fun]], and arms of the pattern are *)
     (* separated by vertical bars. Unlike an ordinary *)
     (* pattern match that is used with [[case]] or  *)
     (* [[handle]], the pattern match in a clausal definition *)
     (* begins with the name of the function being defined. \ *)
     (* glosspar A clausal definition is the idiomatic way to *)
     (* define an ML function that begins with a pattern *)
     (* match. It is preferred over a function whose body is *)
     (* a [[case]] expression. \gloss*Embedding \    *)
     (* gdualindexEmbeddingembeddings A mapping from \ *)
     (* ugmetalanguage values to \ugobject-language values. *)
     (* The mapping always succeeds. For example, any ML *)
     (* [[int]] can be mapped to a micro-Scheme value. *)
     (* An embedded value can be mapped back to the  *)
     (* metalanguage by a \ugprojection. \glossException *)
     (* A way of signaling a named error condition.  *)
     (* Exceptions replace C's [[longjmp]]. An exception acts *)
     (* like a \ugvalue constructor: it can stand by itself, *)
     (* or it can carry one or more values. In ML, evaluating *)
     (* an expression may raise an exception, produce a *)
     (* value, or cause a checked run-time error. \  *)
     (* glossException handler Code that is executed when an *)
     (* exception is raised. Exception handlers replace C's *)
     (* [[setjmp]]. An exception handler may include a \ *)
     (* ugpattern match that determines which exceptions are *)
     (* handled. Our interpreter's primary exception handlers *)
     (* are associated with the \uggeneric read-eval-print *)
     (* loop. \glossExhaustive pattern match A pattern match *)
     (* that is guaranteed to match every possible value. *)
     (* Pattern matches should be exhaustive. If you write *)
     (* one that is not exhaustive, the ML compiler is *)
     (* required to warn you. You should deploy compiler *)
     (* options which turn that warning into an error. \ *)
     (* glossFree variable A variable that is defined outside *)
     (* the function in which it appears. The meaning of a *)
     (* free variable depends on context. The idea of free *)
     (* variable generalizes beyond function definitions to *)
     (* include any language construct that introduces new *)
     (* variables, like a [[let]] expression. Variables that *)
     (* aren't free are \ugbound. \gloss*Interactivity A term *)
     (* I coined to describe the behavior of the \   *)
     (* ugread-eval-print loop. Interactivity determines *)
     (* whether the loop prompts the user before reading *)
     (* input, and whether it prints after evaluating a *)
     (* definition. \gloss*List constructor \        *)
     (* glossonlyindexList constructor Special syntax for *)
     (* writing lists and list patterns in ML. Instead of *)
     (* using cons (written [[::]]) and [[nil]], a list *)
     (* constructor uses square brackets containing zero or *)
     (* more elements separated by commas. If the list *)
     (* constructor appears as an expression, each element is *)
     (* an expression. If the list constructor appears as a \ *)
     (* ugpattern, each element is a pattern. \      *)
     (* glossMetalanguage In an interpreter, the language in *)
     (* which the interpreter is implemented. In a semantics, *)
     (* the language used for semantic description.  *)
     (* A metalanguage describes an \ugobject language. *)
     (* In this chapter, the metalanguage is Standard ML. *)
     (* (The ML in Standard ML stands for ``metalanguage.'') *)
     (* \glossMutable reference cell A location allocated on *)
     (* the heap. In ML, variables stand for values, not for *)
     (* locations, so the only way to get a location is to *)
     (* allocate a mutable reference cell. A reference cell *)
     (* containing a value of type tau has type tau ref. *)
     (* It is created by primitive function [[ref]], which *)
     (* acts like micro-Scheme's [[allocate]] function (\ *)
     (* cpagerefscheme.allocate.int). \qbreak It is  *)
     (* dereferenced by primitive function [[!]], which acts *)
     (* like C's dereferencing operator [[*]]. It is mutated *)
     (* by the infix primitive function [[:=]]; the ML *)
     (* expression \monoboxp := e is equivalent to the C *)
     (* expression \monobox*p = e. \gloss*Mutual recursion *)
     (* (code) \gdualindexMutual recursionmutual recursion *)
     (* Two or more functions, each of which can call the *)
     (* other. In ML, many mutually recursive functions are *)
     (* defined by nesting the definition of one inside the *)
     (* definition of the other. When both have to be called *)
     (* from outside, they can be defined at the same level *)
     (* using keywords [[fun]] and [[and]]. Mutually *)
     (* recursive functions can also be defined in C style, *)
     (* using mutable reference cells. \gloss*Mutual *)
     (* recursion (data) Two or more \ugalgebraic data types, *)
     (* each of which can contain a value of another. Defined *)
     (* using [[datatype]] and keyword [[and]]; in ML, the *)
     (* [[and]] always signifies mutual recursion. In most *)
     (* languages in this book, types [[exp]] and [[value]] *)
     (* are mutually recursive: an [[exp]] can contain a *)
     (* literal [[value]], and a value might be a closure, *)
     (* which contains an [[exp]]. \glossObject language *)
     (* In an interpreter, the language being implemented. *)
     (* In a semantics, the language being described. *)
     (* An object language is described by a \ugmetalanguage. *)
     (* In this chapter, the object language is micro-Scheme. *)
     (* \glossPattern A variable, which matches anything, or *)
     (* a \ugvalue constructor applied to zero or more *)
     (* patterns, which matches only a value created with *)
     (* that constructor. Or a tuple of patterns. \  *)
     (* glossPattern matching The computational process by *)
     (* which a value of \ugalgebraic data type is observed. *)
     (* A pattern match comprises an expression being *)
     (* observed, called the \ugscrutinee, and a list of arms *)
     (* , each of which has a \ugpattern on the left and an *)
     (* expression on the right. The first pattern that *)
     (* matches the scrutinee is chosen, and the     *)
     (* corresponding right-hand side is evaluated. Pattern *)
     (* matching may be used in a [[case]] expression, in an *)
     (* \ugexception handler, or in a \ugclausal definition. *)
     (* Pattern matching is explained at length in \ *)
     (* crefadt.chap. \gloss*Polymorphic type \      *)
     (* gdualindexPolymorphic typepolymorphic types A type *)
     (* with one or more \ugtype variables. A value or *)
     (* function with a polymorphic type may be used with any *)
     (* type replacing the type variable. For example in type *)
     (* \monobox'a env, the [['a]] may stand for \   *)
     (* monoboxvalue ref, which gives us environments that *)
     (* store \ugmutable reference cells. \gloss*Projection \ *)
     (* glossonlyindexProjection A mapping from \    *)
     (* ugobject-language values to \ugmetalanguage values. *)
     (* The mapping might fail. For example, the micro-Scheme *)
     (* value [[3]] cannot meaningfully be projected into an *)
     (* ML function. A projection is the inverse of an \ *)
     (* ugembedding; an attempt to project an embedded value *)
     (* should recover the original value. And some  *)
     (* projections, like [[bool]] in \              *)
     (* chunkrefmlscheme.chunk.bool, always succeed—in a *)
     (* Boolean context, every micro-Scheme value is *)
     (* meaningful. \gloss*Read-eval-print loop The control *)
     (* center of an interactive interpreter. It reads *)
     (* concrete syntax and parses it into abstract syntax, *)
     (* it evaluates the abstract syntax, and it prints the *)
     (* result. If an \ugexception is raised during  *)
     (* evaluation, the exception is handled in the  *)
     (* read-eval-print loop, and looping continues. *)
     (* The read-eval-print loop in \crefmlschemea.chap is *)
     (* reused throughout this book; in every language, *)
     (* it handles extended definitions. True definitions are *)
     (* handled by function [[processDef]], which is *)
     (* different in each interpreter. \glossRedundant *)
     (* pattern An arm in a \ugpattern match that is *)
     (* guaranteed never to be evaluated, because any values *)
     (* it might match are matched by preceding patterns. *)
     (* A redundant pattern match is a sign of a bug in your *)
     (* code—perhaps a misspelling of a \ugvalue constructor. *)
     (* Most ML compilers warn you of redundant patterns. *)
     (* You should deploy compiler options which turn that *)
     (* warning into an error. \qbreak \gloss*Short-circuit *)
     (* conditional \glossonlyindexShort-circuit conditional *)
     (* A conditional operator that evaluates its second *)
     (* operand only when necessary. In Standard ML, the *)
     (* short-circuit conditionals are [[andalso]] and *)
     (* [[orelse]]. Keyword [[and]], which looks like it *)
     (* should be a conditional, actually means mutual *)
     (* recursion. Thanks, Professor Milner. \glossType *)
     (* abbreviation An abbreviation for a type, defined with *)
     (* keyword [[type]]. May take one or more \ugtype *)
     (* variables as parameters. When there are no type *)
     (* parameters, a type abbreviation acts just like C's *)
     (* [[typedef]]. \glossType variable In ML, a name that *)
     (* begins with a quote mark, like [['a]]. Stands for an *)
     (* unknown type. When used in an ML type, a type *)
     (* variable makes the type \ugpolymorphic. \glossValue *)
     (* constructor A name that either constitutes a value of *)
     (* \ugalgebraic data type, like [[nil]] or [[NONE]], or *)
     (* that produces a value of algebraic data type when *)
     (* applied to a value or a tuple of values, like [[::]] *)
     (* or [[SOME]]. {nrglossary}                    *)
     (*                                              *)
     (* Further reading                              *)
     (*                                              *)
     (* To learn Standard ML, you have several good choices. *)
     (* The most comprehensive published book is by \ *)
     (* citetpaulson:working-programmer:1996, but it may be *)
     (* more than you need. The much shorter book by \ *)
     (* citetfelleisen:little-mler introduces ML using an *)
     (* idiosyncratic, dialectical style. If you can learn *)
     (* from that style, the information is good. If you are *)
     (* a proficient C programmer, you might like the book by *)
     (* \citetullman:elements-ml-programming:1997. This book *)
     (* has helped many C programmers make a transition *)
     (* to ML, but it also has a problem: the ML that it *)
     (* teaches is far from idiomatic.               *)
     (*                                              *)
     (* There are also several good unpublished resources. *)
     (* Harper's \citeyearparharper:introduction:1986 *)
     (* introduction is short, sweet, and easy to follow, but *)
     (* it is for an older version of Standard ML. More *)
     (* recently, \citetharper:programming-standard has *)
     (* released an unfinished textbook on programming in *)
     (* Standard ML; it is up to date with the language, but *)
     (* the style is less congenial to beginners. \  *)
     (* citettofte:tips:2009 presents ``tips'' on Standard *)
     (* ML, which I characterize as a 20-page quick-reference *)
     (* card. You probably can't get by on the ``tips'' *)
     (* alone, but when you are working at the computer, they *)
     (* are useful.                                  *)
     (*                                              *)
     (* \qbreak                                      *)
     (*                                              *)
     (* Exercises                                    *)
     (*                                              *)
     (* The exercises are summarized in \            *)
     (* crefpagemlscheme.tab.ex-synopsis. The highlights *)
     (* encourage you to extend or improve micro-Scheme: *)
     (*                                              *)
     (*   • In \crefmlscheme.ex.varargs, you extend *)
     (*  micro-Scheme so a function can take an unbounded *)
     (*  number of arguments.                        *)
     (*   • In \crefmlscheme.ex.primitives-by-composition, *)
     (*  you develop a different technique for using *)
     (*  ML functions as micro-Scheme primitives: instead *)
     (*  of applying functions to the ML functions, you  *)
     (*  compose each ML function with an embedding  *)
     (*  function and a projection function. It's a very *)
     (*  type-oriented way of building an interpreter. *)
     (*   • In \crefmlscheme.ex.closure-code, you use facts *)
     (*  about free variables to change the representation *)
     (*  of closures, and you measure to see if the change *)
     (*  matters.                                    *)
     (*                                              *)
     (* \Crefmlscheme.ex.varargs,mlscheme.ex.closure-code are *)
     (* very satisfying.                             *)
     (*                                              *)

(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
     (*                                              *)
     (* Exercises                             Sections Notes *)
     (* \labelcref mlscheme.ex.cond,          [->],    Working with *)
     (* mlscheme.ex.varargs                   [->]     syntax and *)
     (*                                             semantics: add *)
     (*                                             [[cond]], *)
     (*                                             support *)
     (*                                             variadic *)
     (*                                             functions. *)
     (* \labelcref                            [->],    micro-Scheme *)
     (* mlscheme.ex.eliminate-CLOSURE,        [->]     closures *)
     (* mlscheme.ex.projectList,                       represented as *)
     (* mlscheme.ex.embedding,                         ML functions; *)
     (* mlscheme.ex.primitives-by-composition          embedding and *)
     (*                                             projection *)
     (*                                             functions. *)
     (* \labelcref mlscheme.ex.derivations,   [->],    Derivations of *)
     (* mlscheme.ex.proofchecker              [->]     operational *)
     (*                                             semantics *)
     (*                                             represented as *)
     (*                                             ML data *)
     (*                                             structures. *)
     (* \labelcref mlscheme.ex.closure-proof, [<-]     Prove that *)
     (* mlscheme.ex.closure-code                       closures use *)
     (*                                             only free *)
     (*                                             variables, and *)
     (*                                             use that proof *)
     (*                                             to improve the *)
     (*                                             implementation *)
     (*                                             (§[->]). *)
     (*                                              *)
     (* Synopsis of all the exercises, with most relevant *)
     (* sections                                     *)
     (*                                              *)
     (* [*]                                          *)

(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
     (* \qvfilbreak1.2in                             *)
     (*                                              *)
     (* Retrieval practice and other short questions *)
     (*                                              *)
     (* {retrieval}                                  *)
     (* What's one way to produce an ML value of type \ *)
     (* monoboxname * int?                           *)
     (* What ML values inhabit the type \monobox(name * int) *)
     (* list?                                        *)
     (* In type \monobox'a env, what can the [['a]]  *)
     (* stand for?                                   *)
     (* What are [[[]]] and [[::]]? How are they pronounced? *)
     (* In ML, any two-argument function can be defined as  *)
     (* [[infix]]. Functions [[+]] and [[*]] you know. What *)
     (* do functions [[@]] and [[^]] do?             *)
     (* From function [[bind]], what species of value is *)
     (* produced by the ML expression \monobox(name, v) :: *)
     (* rho?                                         *)
     (* What micro-Scheme definition form corresponds to ML's *)
     (* [[fun]]?                                     *)
     (* Why is ML's definition of [[find]] split into two *)
     (* clauses? How does the ML evaluator decide which *)
     (* clause to execute? What does each clause do? *)
     (* During evaluation, what would cause exception *)
     (* [[BindListLength]] to be raised?             *)
     (* In this chapter, what's the object language and *)
     (* what's the metalanguage?                     *)
     (* Can an ML value of type [[int]] always be embedded *)
     (* into a micro-Scheme [[value]]? If so, how? If not, *)
     (* why not?                                     *)
     (* Can a micro-Scheme [[value]] always be projected into *)
     (* an ML value of type [[int]]? If so, how? If not, *)
     (* why not?                                     *)
     (* Can an ML function of type \monoboxint * int -> int *)
     (* always be embedded into a micro-Scheme primitive of *)
     (* type \monoboxexp * value list -> value? If so, how? *)
     (* If not, why not?                             *)
     (* Suppose you want to change the semantics of  *)
     (* micro-Scheme so that in [[if]] expressions and *)
     (* [[while]] loops, the number zero is treated as *)
     (* falsehood, as in \js. What interpreter code do you *)
     (* change and how?                              *)
     (* In chunk [[<<apply closure [[clo]] to [[args]] *)
     (* ((mlscheme))>>]], explain what [[bindList]]  *)
     (* constructs and why.                          *)
     (* In expression \monobox(lambda (n) (+ 1 n)), what *)
     (* names are free?                              *)
     (* In expression \monobox(lambda (x) (f (g x))), what *)
     (* names are free?                              *)
     (* In expression \monobox(lambda (f g) (lambda (x) (f (g *)
     (* x)))), what names are free?                  *)
     (* Besides [[lambda]], what other syntactic form of *)
     (* expression can introduce new names that are bound in *)
     (* that expression? {retrieval}                 *)
     (*                                              *)
     (* Working with syntax and semantics            *)
     (*                                              *)
     (* {exercises}                                  *)
     (* [*] Syntactic sugar for [[cond]]. \crefpage  *)
     (* (scheme.cond-sugar describes syntactic sugar for \ *)
     (* lisp's original conditional expression: the [[cond]] *)
     (* form. Add a [[cond]] form to micro-Scheme. Start with *)
     (* this code:                                   *)
     (* <boxed values 14>=                           *)
     val _ = op desugarCond : (exp * exp) list -> exp
     (* [[funty]] stand for \tau, [[actualtypes]]    *)
     (* stand for \ldotsntau, and [[rettype]] stand for alpha *)
     (* . The first premise is implemented by a call to *)
     (* [[typesof]] and the second by a call to      *)
     (* [[freshtyvar]]. The constraint is represented just as *)
     (* written in the rule.                         *)

        in  desugarCond <$> many qa
        end
       )
     (* <rows added to ML \uscheme's [[exptable]] in exercises>= *)
     (* add syntactic sugar here, each row preceded by a comma *)
     ]
  end
(* To support some of the exercises in the main text, *)
(* the list of parsers includes a placeholder where more *)
(* parsers can be added.                        *)

(* <parsers and [[xdef]] streams for \uscheme>= *)
val exp = fullSchemeExpOf (atomicSchemeExpOf name) exptable
(* <parsers and [[xdef]] streams for \uscheme>= *)
val deftable = usageParsers
  [ ("(define f (args) body)",
        let val formals  = formalsOf "(x1 x2 ...)" name "define"
        in  curry DEFINE <$> name <*> (pair <$> formals <*> exp)
        end)
  , ("(val x e)", curry VAL <$> name <*> exp)
  ]
(* Parsers for micro-Scheme definitions         *)
(*                                              *)
(* I segregate the definition parsers by the ML type of *)
(* definition they produce. Parser [[deftable]] parses *)
(* the true definitions.                        *)
(* <boxed values 144>=                          *)
val _ = op deftable : def parser
(* <parsers and [[xdef]] streams for \uscheme>= *)
val testtable = usageParsers
  [ ("(check-expect e1 e2)", curry CHECK_EXPECT <$> exp <*> exp)
  , ("(check-assert e)",           CHECK_ASSERT <$> exp)
  , ("(check-error e)",            CHECK_ERROR  <$> exp)
  ]
(* Parser [[testtable]] parses the unit tests.  *)
(* <boxed values 145>=                          *)
val _ = op testtable : unit_test parser
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <parsers and [[xdef]] streams for \uscheme>= *)
val xdeftable = usageParsers
  [ ("(use filename)", USE <$> name)
  (* <rows added to \uscheme\ [[xdeftable]] in exercises>= *)
  (* add syntactic sugar here, each row preceded by a comma *) 
  ]
(* Parser [[xdeftable]] handles those extended  *)
(* definitions that are not unit tests. It is also where *)
(* you would extend the parser with new syntactic forms *)
(* of definition, like the [[record]] form described in *)
(* \crefpage(scheme.record-sugar.               *)
(* <boxed values 146>=                          *)
val _ = op xdeftable : xdef parser
(* <parsers and [[xdef]] streams for \uscheme>= *)
val xdef =  DEF  <$> deftable
        <|> TEST <$> testtable
        <|>          xdeftable
        <|> badRight "unexpected right bracket"
        <|> DEF <$> EXP <$> exp
        <?> "definition"
(* The [[xdef]] parser combines all the types of *)
(* extended [*]                                 *)
(* <boxed values 147>=                          *)
val _ = op xdef : xdef parser
(* definition, plus an error case.              *)

(* <parsers and [[xdef]] streams for \uscheme>= *)
val xdefstream = 
  interactiveParsedStream (schemeToken, xdef)
(* Finally, function [[xdefstream]], which is the *)
(* externally visible interface to the parsing, uses the *)
(* lexer and parser to make a function that converts a *)
(* stream of lines to a stream of extended definitions. *)
(* <boxed values 148>=                          *)
val _ = op xdefstream : string * line stream * prompts -> xdef stream
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <shared definitions of [[filexdefs]] and [[stringsxdefs]]>= *)
fun filexdefs (filename, fd, prompts) =
      xdefstream (filename, filelines fd, prompts)
fun stringsxdefs (name, strings) =
      xdefstream (name, streamOfList strings, noPrompts)
(* <boxed values 54>=                           *)
val _ = op xdefstream   : string * line stream     * prompts -> xdef stream
val _ = op filexdefs    : string * TextIO.instream * prompts -> xdef stream
val _ = op stringsxdefs : string * string list               -> xdef stream



(*****************************************************************)
(*                                                               *)
(*   EVALUATION, TESTING, AND THE READ-EVAL-PRINT LOOP FOR \USCHEME *)
(*                                                               *)
(*****************************************************************)

(* <evaluation, testing, and the read-eval-print loop for \uscheme>= *)
(* <definitions of [[eval]], [[evaldef]], [[basis]], and [[processDef]] for \uscheme ((elided))>= *)
(* <definitions of [[eval]] and [[evaldef]] for \uscheme>= *)
fun eval (e, rho) =
  let val go = applyWithLimits id in go end (* OMIT *)
  let fun ev (LITERAL v) = v
        (* A [[VAR]] or [[SET]] form looks up a name [[x]] in  *)
        (* [[rho]]. The name is expected to be bound to a *)
        (* mutable reference cell, which is ML's version of a *)
        (* pointer to a location allocated on the heap. Such *)
        (* locations are read and written not by using special *)
        (* syntax like C's [[*]], but by using functions [[!]] *)
        (*  and [[:=]], which are in the initial basis of *)
        (* Standard ML. (The [[:=]] symbol, like the [[+]] *)
        (*  symbol, is an ordinary ML function that is declared *)
        (* to be infix.)                                *)
        (* <more alternatives for [[ev]] for \uscheme>= *)
        | ev (VAR x) = !(find (x, rho))
        | ev (SET (x, e)) = 
            let val v = ev e
            in  find (x, rho) := v;
                v
            end
        (* Because the right-hand side of [[SET]], here called *)
        (* [[e]], is evaluated in the same environment as the *)
        (* [[SET]], it can be evaluated using [[ev]].   *)

        (* An [[IF]] or [[WHILE]] form must interpret a *)
        (* micro-Scheme value as a Boolean. Both forms use the *)
        (* projection function [[projectBool]].         *)
        (* <more alternatives for [[ev]] for \uscheme>= *)
        | ev (IFX (e1, e2, e3)) = ev (if projectBool (ev e1) then e2 else e3)
        | ev (WHILEX (guard, body)) = 
            if projectBool (ev guard) then 
              (ev body; ev (WHILEX (guard, body)))
            else
              BOOLV false
        (* The code used to evaluate a [[while]] loop is nearly *)
        (* identical to the rule for lowering [[while]] loops in *)
        (* \crefschemes.chap (\cpagerefschemes.tab.lower). *)
        (*                                              *)
        (* A [[BEGIN]] form is evaluated by evaluating its *)
        (* subexpressions in order, retaining the value of the *)
        (* last one. The subexpressions are evaluated by *)
        (* auxiliary function [[b]], which remembers the value *)
        (* of the last expression in an accumulating parameter *)
        (* [[lastval]]. To ensure that an empty [[BEGIN]] is *)
        (* evaluated correctly, [[lastval]] is initially a *)
        (* micro-Scheme [[#f]].                         *)
        (* <more alternatives for [[ev]] for \uscheme>= *)
        | ev (BEGIN es) =
            let fun b (e::es, lastval) = b (es, ev e)
                  | b (   [], lastval) = lastval
            in  b (es, BOOLV false)
            end
        (* <more alternatives for [[ev]] for \uscheme>= *)
        | ev (LAMBDA (xs, e)) = CLOSURE ((xs, e), rho)
        (* An application is evaluated by first evaluating the *)
        (* expression [[f]] that appears in the function *)
        (* position. How the result is applied depends on *)
        (* whether [[f]] evaluates to a primitive or a closure. *)
        (* As in C, a primitive is applied by applying it to the *)
        (* syntax [[e]] and to the values of the arguments. *)
        (* <more alternatives for [[ev]] for \uscheme>= *)
        | ev (e as APPLY (f, args)) = 
               (case ev f
                  of PRIMITIVE prim => prim (e, map ev args)
                   | CLOSURE clo    =>
                       (* The pattern \monoboxe as APPLY (f, args) matches an *)

                      (* [[APPLY]] node. On the right-hand side, [[e]] stands *)

                     (* for the entire node, and [[f]] and [[args]] stand for *)

                              (* the children.                                *)

                              (*                                              *)

                              (* A closure is applied by first creating fresh *)

                              (* locations to hold the values of the actual   *)

                        (* parameters. In \crefscheme.chap, the locations are *)

                        (* allocated by function [[allocate]]; here, they are *)

                     (* allocated by the built-in function [[ref]]. Calling \ *)

                     (* monoboxref v allocates a new location and initializes *)

                        (* it to v. The ML expression \monoboxmap ref actuals *)

                              (* does half the work of \crefscheme.chap's     *)

                              (* [[bindalloclist]]; the other half is done by *)

                              (* [[bindList]]. \mdbuseschemebindalloclist     *)

                         (* <apply closure [[clo]] to [[args]] ((mlscheme))>= *)
                                       let val ((formals, body), savedrho) = clo
                                           val actuals = map ev args
                                       in  eval (body, bindList (formals, map
                                                         ref actuals, savedrho))
                                           handle BindListLength => 
                                               raise RuntimeError (
                                      "Wrong number of arguments to closure; " ^
                                                                   "expected ("
                                                       ^ spaceSep formals ^ ")")
                                       end
                   | v => raise RuntimeError
                                  ("Applied non-function " ^ valueString v)
               )
        (* <more alternatives for [[ev]] for \uscheme>= *)
        | ev (LETX (LET, bs, body)) =
            let val (names, rightSides) = ListPair.unzip bs
        (* If the number of actual parameters doesn't match the *)
        (* number of formal parameters, [[bindList]] raises the *)
        (* [[BindListLength]] exception, which [[eval]] catches *)
        (* using [[handle]]. The handler then raises    *)
        (* [[RuntimeError]].                            *)
        (*                                              *)
        (* A [[LET]] form is most easily evaluated by first *)
        (* unzipping the list of pairs [[bs]] into a pair of *)
        (* lists \monobox(names, rightSides); function  *)
        (* [[ListPair.unzip]] is from the [[ListPair]] module in *)
        (* ML's Standard Basis Library. Each right-hand side is *)
        (* then evaluated with [[ev]] and stored in a fresh *)
        (* location by [[ref]]. To do the whole list at once, *)
        (* I use [[map]] with the function composition \monobox *)
        (* rev o ev. Finally, the body of the [[LET]] is *)
        (* evaluated in a new environment built by [[bindList]]; *)
        (* since [[ev]] works only with the current [[rho]], the *)
        (* body must be evaluated by [[eval]].          *)
        (* <boxed values 6>=                            *)
        val _ = ListPair.unzip : ('a * 'b) list -> 'a list * 'b list
            in  eval (body, bindList (names, map (ref o ev) rightSides, rho))
            end
        (* <more alternatives for [[ev]] for \uscheme>= *)
        | ev (LETX (LETSTAR, bs, body)) =
            let fun step ((x, e), rho) = bind (x, ref (eval (e, rho)), rho)
            in  eval (body, foldl step rho bs)
            end
        (* <more alternatives for [[ev]] for \uscheme>= *)
        | ev (LETX (LETREC, bs, body)) =
            let val (names, rightSides) = ListPair.unzip bs
                val rho' =
                  bindList (names, map (fn _ => ref (unspecified())) rightSides,
                                                                            rho)
                val updates = map (fn (x, rightSide) => (x, eval (rightSide,
                                                                      rho'))) bs
        (* As in \crefscheme.chap, a [[LETREC]] form is *)
        (* evaluated by first building a new environment *)
        (* [[rho']] that binds each name to a fresh location, *)
        (* then evaluating each right-hand side in the new *)
        (* environment, updating the fresh locations, and *)
        (* finally evaluating the body. The updates are *)
        (* performed by [[List.app]], which, just like  *)
        (* micro-Scheme's [[app]], applies a function to every *)
        (* element of a list, just for its side effect. *)
        (* Functions [[List.app]] and [[map]] are used here with *)
        (* anonymous functions, each of which is written with  *)
        (* [[fn]]—which is ML's way of writing [[lambda]]. *)
        (* <boxed values 7>=                            *)
        val _ = List.app : ('a -> unit) -> 'a list -> unit
            in  List.app (fn (x, v) => find (x, rho') := v) updates; 
                eval (body, rho')
            end
(* The same Boolean projection function is used in \cref *)
(* scheme.chap, but without the jargon; there, the *)
(* projection function is called [[istrue]].    *)
(*                                              *)
(* A list of values can be embedded as a single value by *)
(* converting ML's [[::]] and [[[]]] to micro-Scheme's *)
(* [[PAIR]] and [[NIL]]. The corresponding projection is *)
(* left as \crefmlscheme.ex.projectList. [*]    *)
(* <boxed values 5>=                            *)
val _ = op embedList : value list -> value
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* Evaluation                                   *)
(*                                              *)
(* [*] The machinery above is enough to write an *)
(* evaluator, which takes an expression and an  *)
(* environment and produces a value. Because the *)
(* environment rarely changes, my evaluator is  *)
(* structured as a nested pair of mutually recursive *)
(* functions. The outer function, [[eval]], takes both *)
(* expression [[e]] and environment [[rho]] as  *)
(* arguments. The inner function, [[ev]], takes only an *)
(* expression as argument; it uses the [[rho]] from the *)
(* outer function.                              *)
(*                                              *)
(* Function [[ev]] begins with a clause that evaluates a *)
(* [[LITERAL]] form, which evaluates to the carried *)
(* value [[v]]. \mlsflabeleval                  *)
(* <boxed values 5>=                            *)
val _ = op eval : exp * value ref env -> value
val _ = op ev   : exp                 -> value
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

  in  ev e
  end
(* <definitions of [[eval]] and [[evaldef]] for \uscheme>= *)
fun withNameBound (x, rho) =
  (find (x, rho); rho)
  handle NotFound _ => bind (x, ref (unspecified ()), rho)
(* Evaluating definitions                       *)
(*                                              *)
(* As in Chapter [->], true definitions are evaluated by *)
(* [[evaldef]]. This function takes a definition and an *)
(* environment, and it returns a new environment and the *)
(* interpreter's (string) response. (The C versions of *)
(* [[evaldef]] in \crefimpcore.chap,scheme.chap print *)
(* the response, but the ML code in this chapter is used *)
(* not only for micro-Scheme, but also for statically *)
(* typed languages in \cref                     *)
(* typesys.chap,ml.chap,adt.chap. For those languages, *)
(* it is better to return a response from evaluation, so *)
(* the response from evaluation can be combined with a *)
(* response from type checking.)                *)
(*                                              *)
(* When a definition introduces a new name, that *)
(* definition is evaluated in an environment that *)
(* already includes the name being defined. If the name  *)
(* [[x]] is not already bound, the [[NotFound]] *)
(* exception is handled, and [[x]] is bound to a fresh *)
(* location that is initialized with an unspecified *)
(* value.                                       *)
(* <boxed values 8>=                            *)
val _ = op withNameBound : name * value ref env -> value ref env
(* <definitions of [[eval]] and [[evaldef]] for \uscheme>= *)
fun evaldef (VAL (x, e), rho) =
      let val rho = withNameBound (x, rho)
          val v   = eval (e, rho)
          val _   = find (x, rho) := v
          val response = case e of LAMBDA _ => x
                                 | _ => valueString v
(* Given a [[VAL]] form with binding to name [[x]] and *)
(* right-hand side [[e]], [[evaldef]] first uses *)
(* [[withNameBound]] to make sure [[x]] is bound to a *)
(* location in the environment. It then evaluates [[e]] *)
(* and stores its value in [[x]]'s location. It also *)
(* computes a response, which is usually the value. But *)
(* if the definition binds a [[lambda]] expression, the *)
(* response is instead the name [[x]]. \mlsflabelevaldef *)
(* <boxed values 9>=                            *)
val _ = op evaldef : def  * value ref env -> value ref env * string
      in  (rho, response)
      end
(* As in \crefscheme.chap, [[define]] is syntactic sugar *)
(* for [[val]] with [[lambda]].                 *)
(* <definitions of [[eval]] and [[evaldef]] for \uscheme>= *)
  | evaldef (DEFINE (f, lambda), rho) =
      let val (xs, e) = lambda
      in  evaldef (VAL (f, LAMBDA lambda), rho)
      end
(* The [[EXP]] form doesn't bind a name; [[evaldef]] *)
(* just evaluates the expression, binds the result to  *)
(* [[it]], and responds with the value.         *)
(* <definitions of [[eval]] and [[evaldef]] for \uscheme>= *)
  | evaldef (EXP e, rho) =        
      let val v   = eval (e, rho)
          val rho = withNameBound ("it", rho)
          val _   = find ("it", rho) := v
      in  (rho, valueString v)
      end
(* The differences between [[VAL]] and [[EXP]] are *)
(* subtle: for [[VAL]], the semantics demands that the *)
(* name be added to environment [[rho]] before  *)
(* evaluating expression [[e]]. For [[EXP]], the name  *)
(* [[it]] isn't bound until after evaluating the first *)
(* [[EXP]] form.                                *)

(* When processing a definition, [[processXDef]] must *)
(* recover from any errors that occur. It uses functions *)
(* [[withHandlers]] and [[caught]]. Calling \monobox *)
(* withHandlers f a caught normally applies function  *)
(* [[f]] to argument [[a]] and returns the result. *)
(* But when the application of [[f]] raises an exception *)
(* that the interpreter should recover from,    *)
(* [[withHandlers]] calls [[caught]] with an appropriate *)
(* error message. Here, [[caught]] passes the message to *)
(* [[errmsg]], then returns the original [[basis]] *)
(* unchanged.                                   *)
(*                                              *)
(* The language-dependent [[basis]] is, for     *)
(* micro-Scheme, the single environment rho, which maps *)
(* each name to a mutable location that holds a value. *)
(* The basis is the second parameter to [[processDef]], *)
(* which calls [[evaldef]], prints its response, and *)
(* returns a new basis.                         *)
(* <definitions of [[eval]], [[evaldef]], [[basis]], and [[processDef]] for \uscheme>= *)
type basis = value ref env
fun processDef (d, rho, interactivity) =
  let val (rho', response) = evaldef (d, rho)
      val _ = if echoes interactivity then println response else ()
  in  rho'
  end
fun dump_names basis = app (println o fst) basis  (*OMIT*)
(* <shared unit-testing utilities>=             *)
fun failtest strings = 
  (app eprint strings; eprint "\n"; false)
(* <boxed values 34>=                           *)
val _ = op failtest : string list -> bool
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(*  {combinators} \theaderUnit-testing functions *)
(*  provided by each language \combinatoroutcomeexp *)
(*  -> value error \combinatortyexp -> ty error \ *)
(*  combinatortestEqualsvalue * value -> bool \ *)
(*  combinatorasSyntacticValueexp -> value option \ *)
(*  combinatorvalueStringvalue -> string \combinator *)
(*  expStringexp -> string \combinator          *)
(*  testIsGoodunit_test list * basis -> bool \theader *)
(*  Shared functions for unit testing \combinator *)
(*  whatWasExpectedexp * value error -> string \ *)
(*  combinatorcheckExpectPassesexp * exp -> bool \ *)
(*  combinatorcheckErrorPassesexp -> bool \combinator *)
(*  numberOfGoodTestsunit_test list * basis -> int \ *)
(*  combinatorprocessTestsunit_test list * basis -> *)
(*  unit {combinators}                          *)
(*                                              *)
(* Unit-testing functions                       *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* In each bridge language, test results are reported *)
(* the same way. The report's format is stolen from the *)
(* DrRacket programming environment. If there are no *)
(* tests, there is no report.                   *)
(* <shared unit-testing utilities>=             *)
fun reportTestResultsOf what (npassed, nthings) =
  case (npassed, nthings)
    of (_, 0) => ()  (* no report *)
     | (0, 1) => println ("The only " ^ what ^ " failed.")
     | (1, 1) => println ("The only " ^ what ^ " passed.")
     | (0, 2) => println ("Both " ^ what ^ "s failed.")
     | (1, 2) => println ("One of two " ^ what ^ "s passed.")
     | (2, 2) => println ("Both " ^ what ^ "s passed.")
     | _ => if npassed = nthings then
              app print ["All ", intString nthings, " " ^ what ^ "s passed.\n"]
            else if npassed = 0 then
              app print ["All ", intString nthings, " " ^ what ^ "s failed.\n"]
            else
              app print [intString npassed, " of ", intString nthings,
                          " " ^ what ^ "s passed.\n"]
val reportTestResults = reportTestResultsOf "test"
(* <shared definition of [[withHandlers]]>=     *)
fun withHandlers f a caught =
  f a
  handle RuntimeError msg   => caught ("Run-time error <at loc>: " ^ msg)
       | NotFound x         => caught ("Name " ^ x ^ " not found <at loc>")
       | Located (loc, exn) =>
           withHandlers (fn _ => raise exn)
                        a
                        (fn s => caught (fillAtLoc (s, loc)))
       (* In addition to [[RuntimeError]], [[NotFound]], and *)
       (* [[Located]], [[withHandlers]] catches many exceptions *)
       (* that are predefined ML's Standard Basis Library. *)
       (* These exceptions signal things that can go wrong when *)
       (* evaluating an expression or reading a file.  *)

(* <other handlers that catch non-fatal exceptions and pass messages to [[caught]]>= *)
       | Div                => caught ("Division by zero <at loc>")
       | Overflow           => caught ("Arithmetic overflow <at loc>")
       | Subscript          => caught ("Array index out of bounds <at loc>")
       | Size               => caught (
                                "Array length too large (or negative) <at loc>")
       | IO.Io { name, ...} => caught ("I/O error <at loc>: " ^ name)
       (* These exception handlers are used in all the *)
       (* bridge-language interpreters.                *)

(* <definition of [[testIsGood]] for \uscheme>= *)
fun testIsGood (test, rho) =
  let fun outcome e =
        withHandlers (fn e => OK (eval (e, rho))) e (ERROR o stripAtLoc)
      (* <[[asSyntacticValue]] for \uscheme, \timpcore, \tuscheme, and \nml>= *)
      fun asSyntacticValue (LITERAL v) = SOME v
        | asSyntacticValue _           = NONE
      (* <boxed values 131>=                          *)
      val _ = op asSyntacticValue : exp -> value option

    (* <shared [[check{Expect,Assert,Error}Passes]], which call [[outcome]]>= *)
      (* <shared [[whatWasExpected]]>=                *)
      fun whatWasExpected (e, outcome) =
        case asSyntacticValue e
          of SOME v => valueString v
           | NONE =>
               case outcome
                 of OK v => valueString v ^ " (from evaluating " ^ expString e ^
                                                                             ")"
                  | ERROR _ =>  "the result of evaluating " ^ expString e
      (* These functions are used in parsing and elsewhere. *)
      (*                                              *)
      (* Unit testing                                 *)
      (*                                              *)
      (* When running a unit test, each interpreter has to *)
      (* account for the possibility that evaluating an *)
      (* expression causes a run-time error. Just as in *)
      (* Chapters [->] and [->], such an error shouldn't *)
      (* result in an error message; it should just cause the *)
      (* test to fail. (Or if the test expects an error, it *)
      (* should cause the test to succeed.) To manage errors *)
      (* in C, each interpreter had to fool around with *)
      (* [[set_error_mode]]. In ML, things are simpler: the *)
      (* result of an evaluation is converted either to [[OK]] *)
      (*  v, where v is a value, or to [[ERROR]] m, where m is *)
      (* an error message, as described above. To use this *)
      (* representation, I define some utility functions. *)
      (*                                              *)
      (* When a [[check-expect]] fails, function      *)
      (* [[whatWasExpected]] reports what was expected. If the *)
      (* thing expected was a syntactic value,        *)
      (* [[whatWasExpected]] shows just the value. Otherwise *)
      (* it shows the syntax, plus whatever the syntax *)
      (* evaluated to. The definition of [[asSyntacticValue]] *)
      (* is language-dependent.                       *)
      (* <boxed values 30>=                           *)
      val _ = op whatWasExpected  : exp * value error -> string
      val _ = op asSyntacticValue : exp -> value option
      (* <shared [[checkExpectPassesWith]], which calls [[outcome]]>= *)
      val cxfailed = "check-expect failed: "
      fun checkExpectPassesWith equals (checkx, expectx) =
        case (outcome checkx, outcome expectx)
          of (OK check, OK expect) => 
               equals (check, expect) orelse
               failtest [cxfailed, " expected ", expString checkx,
                         " to evaluate to ", whatWasExpected (expectx, OK expect
                                                                              ),
                         ", but it's ", valueString check, "."]
           | (ERROR msg, tried) =>
               failtest [cxfailed, " expected ", expString checkx,
                         " to evaluate to ", whatWasExpected (expectx, tried),
                         ", but evaluating ", expString checkx,
                         " caused this error: ", msg]
           | (_, ERROR msg) =>
               failtest [cxfailed, " expected ", expString checkx,
                         " to evaluate to ", whatWasExpected (expectx, ERROR msg
                                                                              ),
                         ", but evaluating ", expString expectx,
                         " caused this error: ", msg]
      (* \qbreak Function [[checkExpectPassesWith]] runs a *)
      (* [[check-expect]] test and uses the given [[equals]] *)
      (* to tell if the test passes. If the test does not *)
      (* pass, [[checkExpectPasses]] also writes an error *)
      (* message. Error messages are written using    *)
      (* [[failtest]], which, after writing the error message, *)
      (* indicates failure by returning [[false]].    *)
      (* <boxed values 31>=                           *)
      val _ = op checkExpectPassesWith : (value * value -> bool) -> exp * exp ->
                                                                            bool
      val _ = op outcome  : exp -> value error
      val _ = op failtest : string list -> bool

(* <shared [[checkAssertPasses]] and [[checkErrorPasses]], which call [[outcome]]>= *)
      val cafailed = "check-assert failed: "
      fun checkAssertPasses checkx =
            case outcome checkx
              of OK check =>
                   projectBool check orelse
                   failtest [cafailed, " expected assertion ", expString checkx,
                             " to hold, but it doesn't"]
               | ERROR msg =>
                   failtest [cafailed, " expected assertion ", expString checkx,
                             " to hold, but evaluating it caused this error: ",
                                                                            msg]
      (* \qtrim1 Function [[checkAssertPasses]] does the *)
      (* analogous job for [[check-assert]].          *)
      (* <boxed values 32>=                           *)
      val _ = op checkAssertPasses : exp -> bool

(* <shared [[checkAssertPasses]] and [[checkErrorPasses]], which call [[outcome]]>= *)
      val cefailed = "check-error failed: "
      fun checkErrorPasses checkx =
            case outcome checkx
              of ERROR _ => true
               | OK check =>
                   failtest [cefailed, " expected evaluating ", expString checkx
                                                                               ,
                             " to cause an error, but evaluation produced ",
                             valueString check]
      (* Function [[checkErrorPasses]] does the analogous job *)
      (* for [[check-error]].                         *)
      (* <boxed values 33>=                           *)
      val _ = op checkErrorPasses : exp -> bool
      fun checkExpectPasses (cx, ex) = checkExpectPassesWith testEquals (cx, ex)
      fun passes (CHECK_EXPECT (c, e)) = checkExpectPasses (c, e)
        | passes (CHECK_ASSERT c)      = checkAssertPasses c
        | passes (CHECK_ERROR c)       = checkErrorPasses  c
(* In micro-Scheme, a test is good if it passes. *)
(* (In some other languages, a good test must also be *)
(* well typed.) The ``pass'' functions themselves are *)
(* defined in \crefmlinterps.chap.              *)
(* <boxed values 130>=                          *)
val _ = op testIsGood : unit_test * basis -> bool
val _ = op outcome    : exp -> value error
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

  in  passes test
  end
(* <shared definition of [[processTests]]>=     *)
fun processTests (tests, rho) =
      reportTestResults (numberOfGoodTests (tests, rho), length tests)
and numberOfGoodTests (tests, rho) =
      let val testIsGood = fn args => (resetComputationLimits (); testIsGood
                                                               args) in (*OMIT*)
      foldr (fn (t, n) => if testIsGood (t, rho) then n + 1 else n) 0 tests
      end
                                                                                
                                                                        (*OMIT*)
(* \qbreak Function [[processTests]] is shared among all *)
(* bridge languages. For each test, it calls the *)
(* language-dependent [[testIsGood]], adds up the number *)
(* of good tests, and reports the result. [*]   *)
(* <boxed values 35>=                           *)
val _ = op processTests : unit_test list * basis -> unit
(* <shared read-eval-print loop>=               *)
fun readEvalPrintWith errmsg (xdefs, basis, interactivity) =
  let val unitTests = ref []

(* <definition of [[processXDef]], which can modify [[unitTests]] and call [[errmsg]]>= *)
      fun processXDef (xd, basis) =
        let (* <definition of [[useFile]], to read from a file>= *)
            fun useFile filename =
              let val fd = TextIO.openIn filename
                  val (_, printing) = interactivity
                  val inter' = (NOT_PROMPTING, printing)
              in  readEvalPrintWith errmsg (filexdefs (filename, fd, noPrompts),
                                                                  basis, inter')
                  before TextIO.closeIn fd
              end
            fun try (USE filename) = useFile filename
              | try (TEST t)       = (unitTests := t :: !unitTests; basis)
              | try (DEF def)      = processDef (def, basis, interactivity)
              | try (DEFS ds)      = foldl processXDef basis (map DEF ds)
                                                                        (*OMIT*)
            fun caught msg = (errmsg (stripAtLoc msg); basis)
            val () = resetComputationLimits ()     (* OMIT *)
        in  withHandlers try xd caught
        end 
      (* The extended-definition forms [[USE]] and [[TEST]] *)
      (* are implemented in exactly the same way for every *)
      (* language: internal function [[try]] passes each *)
      (* [[USE]] to [[useFile]], and it adds each [[TEST]] to *)
      (* the mutable list [[unitTests]]—just as in the C code *)
      (* in \crefpage(impcore.readevalprint. Function [[try]] *)
      (* passes each true definition [[DEF]] to function *)
      (* [[processDef]], which does the language-dependent *)
      (* work.                                        *)
      (* <boxed values 62>=                           *)
      val _ = op errmsg     : string -> unit
      val _ = op processDef : def * basis * interactivity -> basis
      val basis = streamFold processXDef basis xdefs
      val _     = processTests (!unitTests, basis)
(* Function [[testIsGood]], which can be shared among *)
(* languages that share the same definition of  *)
(* [[unit_test]], says whether a test passes (or in a *)
(* typed language, whether the test is well-typed and *)
(* passes). Function [[testIsGood]] has a slightly *)
(* different interface from the corresponding C function *)
(* [[test_result]]. The reasons are discussed in \cref *)
(* mlschemea.chap on \cpagerefmlschemea.testIsGood. *)
(* These pieces can be used to define a single version *)
(* of [[processTests]] (\crefpage               *)
(* ,mlinterps.processTests) and a single read-eval-print *)
(* loop, each of which is shared among many bridge *)
(* languages. The pieces are organized as follows: \ *)
(* mdbusemlinterpsprocessTests                  *)
(* <boxed values 61>=                           *)
type basis = basis
val _ = op processDef   : def * basis * interactivity -> basis
val _ = op testIsGood   : unit_test      * basis -> bool
val _ = op processTests : unit_test list * basis -> unit
(* Given [[processDef]] and [[testIsGood]], function *)
(* [[readEvalPrintWith]] processes a stream of extended *)
(* definitions. As in the C version, a stream is created *)
(* using [[filexdefs]] or [[stringsxdefs]].     *)
(*                                              *)
(* Function [[readEvalPrintWith]] has a type that *)
(* resembles the type of the C function         *)
(* [[readevalprint]], but the ML version takes an extra *)
(* parameter [[errmsg]]. Using this parameter, I issue a *)
(* special error message when there's a problem in the *)
(* initial basis (see function [[predefinedError]] on \ *)
(* cpagerefmlinterps.predefinedError). \mdbuse  *)
(* mlinterpspredefinedError The special error message *)
(* helps with some of the exercises in \cref    *)
(* typesys.chap,ml.chap, where if something goes wrong *)
(* with the implementation of types, an interpreter *)
(* could fail while trying to read its initial basis. *)
(* (Failure while reading the basis can manifest in *)
(* mystifying ways; the special message demystifies the *)
(* failure.) \mlsflabelreadEvalPrintWith [*]    *)
(* <boxed values 61>=                           *)
val _ = op readEvalPrintWith : (string -> unit) ->                     xdef
                                         stream * basis * interactivity -> basis
val _ = op processXDef       : xdef * basis -> basis
(* The [[Located]] exception is raised by function *)
(* [[atLoc]]. Calling \monoboxatLoc f x applies [[f]] *)
(* to [[x]] within the scope of handlers that convert *)
(* recognized exceptions to the [[Located]] exception: *)

  in  basis
  end



(*****************************************************************)
(*                                                               *)
(*   IMPLEMENTATIONS OF \USCHEME\ PRIMITIVES AND DEFINITION OF [[INITIALBASIS]] *)
(*                                                               *)
(*****************************************************************)

(* <implementations of \uscheme\ primitives and definition of [[initialBasis]]>= *)
(* <utility functions for building primitives in \uscheme>= *)
fun inExp f = 
  fn (e, vs) => f vs
                handle RuntimeError msg =>
                  raise RuntimeError ("in " ^ expString e ^ ", " ^ msg)
(* <boxed values 10>=                           *)
val _ = op inExp : (value list -> value) -> (exp * value list -> value)
(* [[funty]] stand for \tau, [[actualtypes]]    *)
(* stand for \ldotsntau, and [[rettype]] stand for alpha *)
(* . The first premise is implemented by a call to *)
(* [[typesof]] and the second by a call to      *)
(* [[freshtyvar]]. The constraint is represented just as *)
(* written in the rule.                         *)

(* <utility functions for building primitives in \uscheme>= *)
fun arityError n args =
  raise RuntimeError ("expected " ^ intString n ^
                      " but got " ^ intString (length args) ^ " arguments")
fun unaryOp  f = (fn [a]    => f a      | args => arityError 1 args)
fun binaryOp f = (fn [a, b] => f (a, b) | args => arityError 2 args)
(* <boxed values 11>=                           *)
val _ = op unaryOp  : (value         -> value) -> (value list -> value)
val _ = op binaryOp : (value * value -> value) -> (value list -> value)
(* [[bindList]] tried to                        *)
(*              extend an environment, but it passed *)
(*              two lists (names and values) of *)
(*              different lengths.              *)
(* RuntimeError    Something else went wrong during *)
(*              evaluation, i.e., during the    *)
(*              execution of [[eval]].          *)
(* \bottomrule                                  *)
(*                                              *)
(* Exceptions defined especially for this interpreter  *)
(* [*]                                          *)
(* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ *)
(*                                              *)
(* Abstract syntax and values                   *)
(*                                              *)
(* An abstract-syntax tree can contain a literal value. *)
(* A value, if it is a closure, can contain an  *)
(* abstract-syntax tree. These two types are therefore *)
(* mutually recursive, so I define them together, using *)
(* [[and]].                                     *)
(*                                              *)
(* These particular types use as complicated a nest of *)
(* definitions as you'll ever see. The keyword  *)
(* [[datatype]] defines a new algebraic datatype; the *)
(* keyword [[withtype]] introduces a new type   *)
(* abbreviation that is mutually recursive with the *)
(* [[datatype]]. The first group of [[and]] keywords *)
(* define additional algebraic datatypes, and the second *)
(* group of [[and]] keywords define additional type *)
(* abbreviations. Everything in the whole nest is *)
(* mutually recursive. [*] [*]                  *)

(* <utility functions for building primitives in \uscheme>= *)
fun arithOp f = binaryOp (fn (NUM n1, NUM n2) => NUM (f (n1, n2)) 
                           | (NUM n, v) =>
                              (* <report [[v]] is not an integer>=            *)
                                           raise RuntimeError (
                                "expected an integer, but got " ^ valueString v)
                           | (v, _)     =>
                              (* <report [[v]] is not an integer>=            *)
                                           raise RuntimeError (
                                "expected an integer, but got " ^ valueString v)
                         )
(* Functions [[unaryOp]] and [[binaryOp]] help implement *)
(* any micro-Scheme primitive that is a ``unary *)
(* operator'' or ``binary operator.''           *)
(*                                              *)
(* The first lifting step is given a function like [[+]] *)
(* that expects and returns ML integers, and it produces *)
(* a new function \monoboxarithOp + of type \monobox *)
(* value list -> value. The anonymous function passed to *)
(* [[binaryOp]] has type \monoboxvalue * value -> value. *)
(* <boxed values 12>=                           *)
val _ = op arithOp: (int * int -> int) -> (value list -> value)
(* <utility functions for building primitives in \uscheme>= *)
fun predOp f     = unaryOp  (embedBool o f)
fun comparison f = binaryOp (embedBool o f)
fun intcompare f = comparison (fn (NUM n1, NUM n2) => f (n1, n2)
                                | (NUM n, v) =>
                              (* <report [[v]] is not an integer>=            *)
                                                raise RuntimeError (
                                "expected an integer, but got " ^ valueString v)
                                | (v, _)     =>
                              (* <report [[v]] is not an integer>=            *)
                                                raise RuntimeError (
                                "expected an integer, but got " ^ valueString v)
                              )
(* The ML keyword [[op]] converts an infix identifier to *)
(* an ordinary value, so \monoboxarithOp op + passes the *)
(* value [[+]] (a binary function) to the function *)
(* [[arithOp]].                                 *)
(*                                              *)
(* Primitives like [[<]] and [[null?]] return Booleans, *)
(* so they can't be lifted by [[arithOp]].      *)
(* For primitives like these, the first and middle *)
(* lifting steps are performed by functions [[predOp]], *)
(* [[comparison]], and [[intcompare]].          *)
(* <boxed values 13>=                           *)
val _ = op predOp     : (value         -> bool) -> (value list -> value)
val _ = op comparison : (value * value -> bool) -> (value list -> value)
val _ = op intcompare : (int   * int   -> bool) -> (value list -> value)
(* <utility functions for building primitives in \uscheme>= *)
fun errorPrimitive (_, [v]) = raise RuntimeError (valueString v)
  | errorPrimitive (e, vs)  = inExp (arityError 1) (e, vs)
(* <boxed values 128>=                          *)
val _ = op errorPrimitive : exp * value list -> value list
val primitiveBasis =
  let val rho =
        foldl (fn ((name, prim), rho) =>
                 bind (name, ref (PRIMITIVE (inExp prim)), rho))
              emptyEnv
              ((* Now micro-Scheme primitives like [[+]] and [[*]] can *)
               (* be defined by applying first [[arithOp]] and then *)
               (* [[inExp]] to their ML counterparts.          *)
               (*                                              *)
               (* The micro-Scheme primitives are organized into a list *)
               (* of (name, function) pairs, in Noweb code chunk *)
               (* [[]].                                        *)
               (* Each primitive on the list has type \monoboxvalue *)
               (* list -> value. In \chunkrefmlscheme.inExp-applied, *)
               (* each primitive is passed to [[inExp]], and the *)
               (* results are used build micro-Scheme's initial *)
               (* environment. [Actually, the list contains all the *)
               (* primitives except one: the [[error]] primitive, which *)
               (* must not be wrapped in [[inExp]].] The list of *)
               (* primitives begins with these four elements:  *)
               (* <primitives for \uscheme\ [[::]]>=           *)
               ("+", arithOp op +  ) :: 
               ("-", arithOp op -  ) :: 
               ("*", arithOp op *  ) :: 
               ("/", arithOp op div) ::
               (* micro-Scheme's primitive predicates are implemented *)
               (* by ML primitives ([[<]] and [[>]]), by function *)
               (* [[equalatoms]] (defined in \crefmlschemea.chap), and *)
               (* by anonymous functions.                      *)
               (* <primitives for \uscheme\ [[::]]>=           *)
               ("<", intcompare op <) :: 
               (">", intcompare op >) ::
               ("=", comparison equalatoms) ::
               ("null?",    predOp (fn (NIL    ) => true | _ => false)) ::
               ("boolean?", predOp (fn (BOOLV _) => true | _ => false)) ::
               (* Primitive functions and the initial basis    *)
               (*                                              *)
               (* Defining the remaining primitives            *)
               (*                                              *)
               (* Some primitives are defined in \crefmlscheme.chap. *)
               (* The rest are here.                           *)
               (* <primitives for \uscheme\ [[::]]>=           *)
               ("number?",  predOp (fn (NUM   _) => true | _ => false)) ::
               ("symbol?",  predOp (fn (SYM   _) => true | _ => false)) ::
               ("pair?",    predOp (fn (PAIR  _) => true | _ => false)) ::
               ("function?",
                     predOp (fn (PRIMITIVE _) => true
                              | (CLOSURE   _) => true
                              | _ => false)) ::
               (* The list primitives are also implemented by simple *)
               (* anonymous functions:                         *)
               (* <primitives for \uscheme\ [[::]]>=           *)
               ("cons", binaryOp (fn (a, b) => PAIR (a, b))) ::
               ("car",  unaryOp  (fn (PAIR (car, _)) => car 
                                   | NIL => raise RuntimeError
                                                     "car applied to empty list"
                                   | v => raise RuntimeError
                                            ("car applied to non-list " ^
                                                             valueString v))) ::
               ("cdr",  unaryOp  (fn (PAIR (_, cdr)) => cdr 
                                   | NIL => raise RuntimeError
                                                     "cdr applied to empty list"
                                   | v => raise RuntimeError
                                            ("cdr applied to non-list " ^
                                                             valueString v))) ::
               (* The ML-version of micro-Scheme includes a secret *)
               (* [[hash]] primitive.                          *)
               (* <primitives for \uscheme\ [[::]]>=           *)
               ("hash",  unaryOp (fn SYM s => NUM (fnvHash s)
                                   | v => raise RuntimeError
                                             (valueString v ^ " is not a symbol"
                                                                          ))) ::
               (* The printing primitives are all similar.     *)
               (* <primitives for \uscheme\ [[::]]>=           *)
               ("println", unaryOp (fn v => (print (valueString v ^ "\n"); v)))
                                                                              ::
               ("print",   unaryOp (fn v => (print (valueString v);        v)))
                                                                              ::
               ("printu",  unaryOp (fn NUM n => (printUTF8 n; NUM n)
                                     | v => raise RuntimeError
                                              (valueString v ^
                                               " is not a Unicode code point")))
                                                                          :: [])
      val rho = bind ("error", ref (PRIMITIVE errorPrimitive), rho)
  in  rho
  end
(* When reading predefined functions, the interpreter *)
(* echoes no responses, and to issue error messages, it *)
(* uses the special function [[predefinedError]]. *)
(* <implementations of \uscheme\ primitives and definition of [[initialBasis]]>= *)
val predefs = 
               [ ";  In more complex examples, the primitives' definitions "
               , ";  have to be used carefully; a literal S-expression "
               , ";  might look like a long list even when it's not. "
               , ";  For example, list \\monobox(a (b (c d))) looks long, "
               , ";  but it has only two elements: the symbol a and the "
               , ";  list \\monobox(b (c d)). Its cdr is therefore the "
               , ";  single-element list \\monobox((b (c d))).     "
               , ";                                               "
               , ";  Primitives [[cons]], [[car]], and [[cdr]] are often "
               , ";  explained with diagrams. Any nonempty list can be "
               , ";  drawn as a box that contains two pointers, one of "
               , ";  which points to the [[car]], and the other to the  "
               , ";  [[cdr]]. This box helps explain not only the behavior "
               , ";  but also the cost of running Scheme programs, so it "
               , ";  has a name—it is a cons cell. If the [[cdr]] of a "
               , ";  cons cell is the empty list, there's nothing to "
               , ";  point to; instead, it is drawn as a slash. Using "
               , ";  these conventions, the list (a b c) is drawn like "
               , ";  this:                                        "
               , ";  <predefined uScheme functions>=           "
               , "(define caar (xs) (car (car xs)))"
               , "(define cadr (xs) (car (cdr xs)))"
               , "(define cdar (xs) (cdr (car xs)))"
               , ";  <predefined uScheme functions ((elided))>= "
               , ";  List operations                              "
               , ";                                               "
               , ";  Nobody should use these operations. I'm not sure why "
               , ";  I have kept them. Tradition? \\basislabelcaddr,cddr "
               , ";  <more predefined combinations of [[car]] and [[cdr]]>= "
               , "(define cddr  (sx) (cdr (cdr  sx)))"
               , "(define caaar (sx) (car (caar sx)))"
               , "(define caadr (sx) (car (cadr sx)))"
               , "(define cadar (sx) (car (cdar sx)))"
               , "(define caddr (sx) (car (cddr sx)))"
               , "(define cdaar (sx) (cdr (caar sx)))"
               , "(define cdadr (sx) (cdr (cadr sx)))"
               , "(define cddar (sx) (cdr (cdar sx)))"
               , "(define cdddr (sx) (cdr (cddr sx)))"
               , ";  <more predefined combinations of [[car]] and [[cdr]]>= "
               , "(define caaaar (sx) (car (caaar sx)))"
               , "(define caaadr (sx) (car (caadr sx)))"
               , "(define caadar (sx) (car (cadar sx)))"
               , "(define caaddr (sx) (car (caddr sx)))"
               , "(define cadaar (sx) (car (cdaar sx)))"
               , "(define cadadr (sx) (car (cdadr sx)))"
               , "(define caddar (sx) (car (cddar sx)))"
               , "(define cadddr (sx) (car (cdddr sx)))"
               , ";  <more predefined combinations of [[car]] and [[cdr]]>= "
               , "(define cdaaar (sx) (cdr (caaar sx)))"
               , "(define cdaadr (sx) (cdr (caadr sx)))"
               , "(define cdadar (sx) (cdr (cadar sx)))"
               , "(define cdaddr (sx) (cdr (caddr sx)))"
               , "(define cddaar (sx) (cdr (cdaar sx)))"
               , "(define cddadr (sx) (cdr (cdadr sx)))"
               , "(define cdddar (sx) (cdr (cddar sx)))"
               , "(define cddddr (sx) (cdr (cdddr sx)))"
               , ";  These definitions appear in chunk [[<<predefined "
               , ";  micro-Scheme functions>>]], from which they are built "
               , ";  into the micro-Scheme interpreter itself and are "
               , ";  evaluated when the interpreter starts. Definitions "
               , ";  are built in for all combinations of [[car]] and "
               , ";  [[cdr]] up to depth five, ending with [[cdddddr]], "
               , ";  but the others are relegated to the Supplement. "
               , ";                                               "
               , ";  If applying [[car]] or [[cdr]] several times in "
               , ";  succession is tiresome, so is applying [[cons]] "
               , ";  several times in succession. Common cases are "
               , ";  supported by more predefined functions: \\basislabel "
               , ";  list1,list2,list3                            "
               , ";  <predefined uScheme functions>=           "
               , "(define list1 (x)     (cons x '()))"
               , "(define list2 (x y)   (cons x (list1 y)))"
               , "(define list3 (x y z) (cons x (list2 y z)))"
               , ";  Interestingly, [[append]] never looks at \\ys; "
               , ";  it inspects only \\xs. And like any list, \\xs is "
               , ";  formed using either [['()]] or [[cons]]. If \\xs is "
               , ";  empty, [[append]] returns \\ys. If \\xs is \\monobox "
               , ";  (cons \\metaz \\zs), [[append]] returns \\metaz followed "
               , ";  by \\zs followed by \\ys. The behavior of [[append]] "
               , ";  can be specified precisely using two algebraic laws:  "
               , ";  [*] {llaws} \\monolaw(append '() \\ys)\\ys \\monolaw "
               , ";  (append (cons \\metaz \\zs) \\ys)(cons \\metaz (append \\ "
               , ";  zs \\ys)) {llaws} In the code, argument [[xs]] holds \\ "
               , ";  xs, argument [[ys]] holds \\ys, \\metaz is \\monobox(car "
               , ";  xs), and \\zs is \\monobox(cdr xs): \\basislabelappend "
               , ";  <predefined uScheme functions>=           "
               , "(define append (xs ys)"
               , "  (if (null? xs)"
               , "     ys"
               , "     (cons (car xs) (append (cdr xs) ys))))"
               , ";  This [[simple-reverse]] function is expensive: "
               , ";  [[append]] takes O(n) time and space,\\notation O(...) "
               , ";  asymptotic complexity and so [[simple-reverse]] takes "
               , ";  O(n^2) time and space, where n is the length of the "
               , ";  list. But list reversal can be implemented in linear "
               , ";  time. In Scheme, reversal is made efficient by using "
               , ";  a trick: take two lists, \\xs and \\ys, and return the "
               , ";  reverse of \\xs, followed by (unreversed) \\ys. List \\ "
               , ";  xs is either empty or is z followed by \\zs, and the "
               , ";  computation obeys these laws: {llaws} \\mathlawR( "
               ,
              ";  epsilon)\\followedby\\ys\\ys \\mathlawR(z\\followedby\\zs)\\ "
               ,
               ";  followedby\\ys(R(\\zs)\\followedby z)\\followedby\\ys= R(\\ "
               , ";  zs)\\followedby(z \\followedby\\ys) {llaws} Translated "
               , ";  back to Scheme, the laws for ``reverse-append'' are "
               , ";  {llaws} \\monolaw(revapp '() \\ys)\\ys \\monolaw(revapp "
               ,
                ";  (cons \\metaz \\zs) \\ys)(revapp \\zs (cons \\metaz \\ys)) "
               , ";  {llaws} The code looks like this: \\basislabelrevapp "
               , ";  <predefined uScheme functions>=           "
               , "(define revapp (xs ys) ; (reverse xs) followed by ys"
               , "  (if (null? xs)"
               , "     ys"
               , "     (revapp (cdr xs) (cons (car xs) ys))))"
               , ";  Function [[revapp]] takes time and space linear in "
               , ";  the size of [[xs]]. Using it with an empty list makes "
               , ";  predefined function [[reverse]] equally efficient. \\ "
               , ";  basislabelreverse                            "
               , ";  <predefined uScheme functions>=           "
               , "(define reverse (xs) (revapp xs '()))"
               , ";  Coding with S-expressions\\nochap: Lists of lists "
               , ";                                               "
               , ";  [*]                                          "
               , ";                                               "
               , ";  Even more recursion happens when a list element is "
               , ";  itself a list, which can contain other lists, and "
               , ";  so on. Such lists, together with the atoms (rule [->] "
               , ";  , \\cpagerefscheme.atoms), constitute the ordinary "
               , ";  S-expressions.                               "
               , ";                                               "
               , ";  An ordinary S-expression is either an atom or a list "
               , ";  of ordinary S-expressions. [The empty list [['()]] is "
               , ";  \\emph{both} an atom \\emph{and} a list of ordinary "
               , ";  S-expressions.] An atom is identified by predefined "
               , ";  function [[atom?]]:[*] \\basislabelatom?      "
               , ";  <predefined uScheme functions ((elided))>= "
               , ";  More cases, for [[list4]] to [[list8]], are defined "
               , ";  in the Supplement. In full Scheme, all possible cases "
               , ";  are handled by a single, variadic function, list, "
               , ";  which takes any number of arguments and returns a "
               , ";  list containing those arguments (\\cref       "
               , ";  scheme.ex.list).                             "
               , ";                                               "
               ,
";  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ "
               , ";  \\advanceby 1.6pt \\advanceby -0.35pt          "
               , ";                                               "
               , ";  |>p0.25\\mysize >p0.75 Equality and inequality on "
               , ";  \\mysize| [[=]], [[!   atoms                  "
               , ";  =]]                                          "
               , ";                     Recursive equality on fully "
               , ";  [[equal?]]            general S-expressions  "
               , ";                     (isomorphism, not object  "
               , ";                     identity)                 "
               , ";  [[/]], [[*]], [[-]],  Integer arithmetic     "
               , ";  [[+]], [[mod]]                               "
               , ";  [[>]], [[<]], [[>=]], Integer comparison     "
               , ";  [[<=]]                                       "
               , ";  [[lcm]], [[gcd]],     Binary operations on integers "
               , ";  [[min]], [[max]]                             "
               , ";  [[lcm*]], [[gcd*]],   The same operations, but taking "
               , ";  [[max*]], [[min*]]    one nonempty list of integers "
               , ";                     as argument               "
               , ";                     Basic operations on Booleans, "
               , ";  [[not]], [[and]],     which, unlike their    "
               , ";  [[or]]                counterparts in full Scheme, "
               , ";                     evaluate all their arguments "
               , ";  [[symbol?]],                                 "
               , ";  [[number?]],                                 "
               , ";  [[boolean?]],         Type predicates        "
               , ";  [[null?]], [[pair?]],                        "
               , ";  [[function?]]                                "
               , ";                     Type predicate saying whether a "
               , ";  [[atom?]]             value is an atom \\break(not a "
               , ";                     function and not a pair)  "
               , ";  [[cons]], [[car]],    The basic list operations "
               , ";  [[cdr]]                                      "
               , ";                     Abbreviations for combinations "
               , ";  [[caar]], [[cdar]],   of list operations, including "
               , ";  [[cadr]], [[cddr]], \\ also [[caaar]], [[cdaar]], "
               , ";  ensuremath...         [[caadr]], [[cdadr]], and so "
               , ";                     on, all the way to [[cddddr]]. "
               , ";  [[list1]], [[list2]], Convenience functions for "
               , ";  [[list3]], [[list4]], creating lists, including also "
               , ";  \\ensuremath...        [[list5]] to [[list8]] "
               , ";                     The elements of one list  "
               , ";  [[append]]            followed by the elements of "
               , ";                     another                   "
               , ";  [[revapp]]            The elements of one list, "
               , ";                     reversed, followed by another "
               , ";  [[reverse]]           A list reversed        "
               , ";  [[bind]], [[find]]    Insertion and lookup for "
               , ";                     association lists         "
               , ";  [[filter]]            Those elements of a list "
               , ";                     satisfying a predicate    "
               , ";  [[exists?]]           Does any element of a list "
               , ";                     satisfy a predicate?      "
               , ";  [[all?]]              Do all elements of a list "
               , ";                     satisfy a predicate?      "
               , ";                     List of results of applying a "
               , ";  [[map]]               function to each element of "
               , ";                     a list                    "
               , ";  [[takewhile]]         The longest prefix of a list "
               , ";                     satisfying a predicate    "
               , ";  [[dropwhile]]         What's not taken by    "
               , ";                     [[takewhile]]             "
               , ";                     Elements of a list combined by "
               , ";  [[foldl]], [[foldr]]  an operator, which associates "
               , ";                     to left or right, respectively "
               , ";  [[o]]                 Function composition   "
               , ";  [[curry]]             The curried function equivalent "
               , ";                     to some binary function   "
               , ";  [[uncurry]]           The binary function equivalent "
               , ";                     to some curried function  "
               , ";  [[println]],          Primitives that print one value "
               , ";  [[print]]                                    "
               , ";  [[printu]]            Primitive that prints a Unicode "
               , ";                     character                 "
               , ";                     Primitive that aborts the "
               , ";  [[error]]             computation with an error "
               , ";                     message                   "
               , ";                                               "
               , ";  The initial basis of micro-Scheme [*]        "
               , ";                                               "
               ,
";  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ "
               , ";                                               "
               , ";  [*] Three predefined functions are similar but not "
               , ";  identical to functions found in Impcore: the Boolean "
               , ";  functions [[and]], [[or]], and [[not]]. Instead of "
               , ";  Impcore's 1 and 0, they return Boolean values. "
               ,
";  <definitions of predefined uScheme functions [[and]], [[or]], and [[not]]>= "
               , "(define and (b c) (if b  c  b))"
               , "(define or  (b c) (if b  b  c))"
               , "(define not (b)   (if b #f #t))"
               , ";  <predefined uScheme functions>=           "
               , "(define atom? (x)"
               ,
              "  (or (symbol? x) (or (number? x) (or (boolean? x) (null? x)))))"
               , ";  Inspecting multiple inputs: Equality on S-expressions "
               , ";                                               "
               , ";  Functions like [[length]], [[append]], [[insert]], "
               , ";  and [[has?]] inspect only one list or one    "
               , ";  S-expression. A function that inspects two   "
               , ";  S-expressions must prepare for all forms of both "
               , ";  inputs, for a total of four cases. As an example, "
               , ";  function [[equal?]] compares two S-expressions for "
               , ";  equality—they are equal if they are formed from the "
               , ";  same atoms in the same way. Breaking the inputs down "
               , ";  by cases, two atoms are equal if they are the same, "
               , ";  as tested with primitive [[=]]. Two lists are equal "
               , ";  if they contain (recursively) equal elements in equal "
               , ";  positions. An atom and a nonempty list are never "
               , ";  equal. {llaws} \\monolaw[,] (equal? \\meta\\sx_1 \\meta\\ "
               , ";  sx_2)(= \\meta\\sx_1 \\meta\\sx_2) if \\meta\\sx_1 is an "
               , ";  atom and \\meta\\sx_2 is an atom               "
               ,
                ";  \\monolaw[, if \\meta\\sx_1 is an atom] (equal? \\meta\\sx "
               , ";  _1 (cons \\metaw \\metaz)))[[#f]] \\monolaw[, if \\meta\\ "
               , ";  sx_2 is an atom] (equal? (cons \\metax \\metay) \\meta\\ "
               , ";  sx_2)[[#f]] \\monolaw(equal? (cons \\metax \\metay) "
               , ";  (cons \\metaw \\metaz)) (and (equal? \\metax \\metaw) "
               , ";  (equal? \\metay \\metaz)) {llaws} These laws call for "
               , ";  four cases, but in an implementation, the first two "
               , ";  laws can be combined: the second law calls for "
               , ";  [[equal?]] to return [[#f]], but when \\meta\\sx_1 is "
               , ";  an atom and \\meta\\sx_2 is \\monobox(cons \\metaw \\meta "
               , ";  z), \\monobox(= \\meta\\sx_1 \\meta\\sx_2) always returns "
               , ";  false, so both cases where \\meta\\sx_1 is an atom may "
               , ";  use [[=]]: \\basislabelequal? [*]             "
               , ";  <predefined uScheme functions>=           "
               , "(define equal? (sx1 sx2)"
               , "  (if (atom? sx1)"
               , "    (= sx1 sx2)"
               , "    (if (atom? sx2)"
               , "        #f"
               , "        (and (equal? (car sx1) (car sx2))"
               , "             (equal? (cdr sx1) (cdr sx2))))))"
               , ";  If [[member?]] used \\monobox= instead of [[equal?]], "
               , ";  this last example wouldn't work; I encourage you to "
               , ";  explain why (\\schemexset-with-=).            "
               , ";                                               "
               , ";  Association lists                            "
               , ";                                               "
               , ";  [*]                                          "
               , ";                                               "
               , ";  A list of ordered pairs can represent a classic data "
               , ";  structure of symbolic computing: the finite map (also "
               , ";  called associative array, dictionary, and table). "
               , ";  Finite maps are ubiquitous; for example, in this book "
               , ";  they are used to represent the environments found in "
               , ";  operational semantics and in interpreters. (In an "
               , ";  interpreter or compiler, an environment is often "
               , ";  called a symbol table.)                      "
               , ";                                               "
               , ";  A small map is often represented as an association "
               , ";  list. An association list has the form \\monobox((k_1 "
               , ";  a_1) ... (k_m a_m)),\\notation k a key in an  "
               , ";  association list\\notation a an attribute in an "
               , ";  association list where each k_i is a symbol, called "
               , ";  a key, and each a_i is an arbitrary value, called an  "
               , ";  attribute. A pair \\monobox(k_i a_i) is made with "
               , ";  function [[make-alist-pair]] and inspected with "
               , ";  functions [[alist-pair-key]] and             "
               , ";  [[alist-pair-attribute]]: {llaws} \\monolaw   "
               , ";  (alist-pair-key (make-alist-pair \\metak \\metaa))\\meta "
               , ";  k \\monolaw(alist-pair-attribute (make-alist-pair \\ "
               , ";  metak \\metaa))\\metaa {llaws} The pair is represented "
               , ";  by a two-element list, so the three \\basislabel "
               , ";  make-alist-pair,alist-pair-key,alist-pair-attribute "
               , ";  [[alist-pair]] functions are implemented as follows: "
               , ";  <predefined uScheme functions>=           "
               , "(define make-alist-pair      (k a)   (list2 k a))"
               , "(define alist-pair-key       (pair)  (car  pair))"
               , "(define alist-pair-attribute (pair)  (cadr pair))"
               , ";  A list of these pairs forms an association list, and "
               , ";  when an association list is nonempty, the key and "
               , ";  attribute of the \\basislabel                 "
               , ";  alist-first-key,alist-first-attribute first pair are "
               , ";  retrieved by these auxiliary functions:      "
               , ";  <predefined uScheme functions>=           "
               ,
     "(define alist-first-key       (alist) (alist-pair-key       (car alist)))"
               ,
     "(define alist-first-attribute (alist) (alist-pair-attribute (car alist)))"
               , ";  An association list is operated on primarily by "
               , ";  functions [[bind]] and [[find]], which add bindings "
               , ";  and retrieve attributes. Their behavior is described "
               , ";  by these laws: [*] {llaws*} \\monolaw(bind \\metak \\ "
               , ";  metaa '())(cons (make-alist-pair \\metak \\metaa) '()) "
               , ";  \\monolaw(bind \\metak \\metaa (cons (make-alist-pair \\ "
               , ";  metak \\metaa') \\ps)) (cons (make-alist-pair \\metak \\ "
               , ";  metaa) \\ps) \\monolaw(bind \\metak \\metaa (cons "
               , ";  (make-alist-pair \\metak' \\metaa') \\ps)) \\monobox(cons "
               , ";  (make-alist-pair \\metak' \\metaa') (bind \\metak \\metaa "
               , ";  \\ps)),                                       "
               , ";  --- --- \\qquadwhen \\metak and \\metak' are different "
               , ";  \\monolaw(find \\metak '())'() \\monolaw(find \\metak "
               , ";  (cons (make-alist-pair \\metak \\metaa) \\ps))\\metaa \\ "
               , ";  monolaw(find \\metak (cons (make-alist-pair \\metak' \\ "
               , ";  metaa) \\ps))(find \\metak \\ps) --- --- \\qquadwhen \\ "
               , ";  metak and \\metak' are different              "
               , ";  {llaws*} A missing attribute is retrieved as [['()]]. "
               , ";  \\basislabelbind,find                         "
               , ";  <predefined uScheme functions>=           "
               , "(define bind (k a alist)"
               , "  (if (null? alist)"
               , "    (list1 (make-alist-pair k a))"
               , "    (if (equal? k (alist-first-key alist))"
               , "      (cons (make-alist-pair k a) (cdr alist))"
               , "      (cons (car alist) (bind k a (cdr alist))))))"
               , "(define find (k alist)"
               , "  (if (null? alist)"
               , "    '()"
               , "    (if (equal? k (alist-first-key alist))"
               , "      (alist-first-attribute alist)"
               , "      (find k (cdr alist)))))"
               , ";  Function [[irand]] has its own private copy of "
               , ";  [[seed]], which only it can access, and which it "
               , ";  updates at each call. And function           "
               , ";  [[repeatable-irand]], which might be used to replay "
               , ";  an execution for debugging, has its own private seed. "
               , ";  So it repeats the same sequence [1, 14, 131, 160, "
               , ";  421, ...] no matter what happens with [[irand]]. "
               , ";                                               "
               , ";  Useful higher-order functions                "
               , ";                                               "
               , ";  [*] The [[lambda]] expression does more than just "
               , ";  encapsulate mutable state; [[lambda]] helps express "
               , ";  and support not just algorithms but also patterns of "
               , ";  computation. What a ``pattern of computation'' might "
               , ";  be is best shown by example.                 "
               , ";                                               "
               , ";  One minor example is the function [[mk-rand]]: it can "
               , ";  be viewed as a pattern that says ``if you tell me how "
               , ";  to get from one number to the next, I can deliver an "
               , ";  entire sequence of numbers starting with 1.'' "
               , ";  This pattern of computation, while handy, is not used "
               , ";  often. More useful patterns can make new functions "
               , ";  from old functions or can express common ways of "
               , ";  programming with lists, like ``do something with "
               , ";  every element.'' Such patterns are presented in the "
               , ";  next few sections.                           "
               , ";                                               "
               , ";  Composition                                  "
               , ";                                               "
               , ";  One of the simplest ways to make a new function is by "
               , ";  composing two old ones. Function [[o]] (pronounced "
               , ";  ``circle'' or ``compose'') returns the composition of "
               , ";  two one-argument functions, often written f og.\\ "
               , ";  stdbreak \\notation [composed with]ofunction  "
               , ";  composition Composition is described by the algebraic "
               , ";  law (f og)(x) = f(g(x)), and like any function that "
               , ";  makes new functions, it returns a [[lambda]]: \\ "
               , ";  basislabelo                                  "
               , ";  <predefined uScheme functions>=           "
               ,
    "(define o (f g) (lambda (x) (f (g x))))          ; ((o f g) x) = (f (g x))"
               , ";  Function composition can negate a predicate by "
               , ";  composing [[not]] with it:                   "
               , ""
               , ";  Functions needn't always be curried by hand. Any "
               , ";  binary function can be converted between its "
               , ";  uncurried and curried forms using the predefined "
               , ";  functions [[curry]] and [[uncurry]]: \\basislabel "
               , ";  curry,uncurry                                "
               , ";  <predefined uScheme functions>=           "
               , "(define curry   (f) (lambda (x) (lambda (y) (f x y))))"
               , "(define uncurry (f) (lambda (x y) ((f x) y)))"
               , ";  More applications of [[foldr]] and [[foldl]] are "
               , ";  suggested in Exercises [->], [->], and [->]. "
               , ";                                               "
               , ";  Visualizations\\cullchap of the standard list "
               , ";  functions                                    "
               , ";                                               "
               , ";  --- \\bigsize#2 --- \\bigsize#2 --- \\bigsize#2 --- \\ "
               , ";  bigsize#2 --- #1 --- \\bigsize#2              "
               , ";  --- \\bigsize#3 --- \\bigsize#2 --- \\bigsize#2 --- \\ "
               , ";  bigsize#3 --- #1 --- \\bigsize#2              "
               , ";                                               "
               , ";  Which list functions should be used when? Functions "
               , ";  [[exists?]] and [[all?]] are not hard to figure out, "
               , ";  but [[map]], [[filter]], and [[foldr]] can be more "
               , ";  mysterious. They can be demystified a bit using "
               , ";  pictures, as inspired by [cite harvey:simply]. "
               , ";                                               "
               , ";  A generic list [[xs]] can be depicted as a list of "
               , ";  circles:                                     "
               , ";                                               "
               , ";   {rowtable} xs --- \\roweq --- \\bigrow\\mycircle  "
               , ";   {rowtable}                                  "
               , ";                                               "
               , ";  If [[f]] is a function that turns one circle into one "
               , ";  triangle, as in \\nomathbreak\\monobox(f \\mycircle) = \\ "
               , ";  mytriangle, then \\monobox(map f xs) turns a list of "
               , ";  circles into a list of triangles.            "
               , ";                                               "
               , ";   {rowtable} xs --- \\roweq --- \\bigrow\\mycircle "
               , ";   --- --- \\bigrow[]\\Bigg\\downarrow            "
               , ";   \\monobox(map f xs) --- \\roweq --- \\bigrow\\  "
               , ";   mytriangle {rowtable}                       "
               , ";                                               "
               , ";  If [[p?]] is a function that takes a circle and "
               , ";  returns a Boolean, as in \\nomathbreak\\monobox(p? \\ "
               , ";  mycircle) = b, then \\monobox(filter p? xs) selects "
               , ";  just some of the circles:                    "
               , ";                                               "
               , ";   {rowtable} xs --- \\roweq --- \\bigrow\\mycircle "
               , ";   --- --- \\mixedrow[]\\Bigg\\downarrow*         "
               , ";   \\monobox(filter p? xs) --- \\roweq --- \\mixedrow\\ "
               , ";   mycircle {rowtable}                         "
               , ";                                               "
               , ";  Finally, if [[f]] is a function that takes a circle "
               , ";  and a box and produces another box, as in \\monobox(f  "
               , ";  \\mycircle \\mybox [[)]] = \\mybox, then \\monobox(fold f "
               , ";  \\mybox xs) folds all of the circles into a single "
               , ";  box:                                         "
               , ";                                               "
               , ";   {rowtable} xs --- \\roweq --- \\bigrow\\mycircle "
               , ";  <predefined uScheme functions>=           "
               , "(define filter (p? xs)"
               , "  (if (null? xs)"
               , "    '()"
               , "    (if (p? (car xs))"
               , "      (cons (car xs) (filter p? (cdr xs)))"
               , "      (filter p? (cdr xs)))))"
               , ";  Function [[map]] is even simpler. There is no "
               , ";  conditional test; the induction step just applies  "
               , ";  [[f]] to the [[car]], then conses. \\basislabelmap "
               , ";  <predefined uScheme functions>=           "
               , "(define map (f xs)"
               , "  (if (null? xs)"
               , "    '()"
               , "    (cons (f (car xs)) (map f (cdr xs)))))"
               , ";  Function [[app]] is like [[map]], except its argument "
               , ";  is applied only for side effect. Function [[app]] is "
               , ";  typically used with [[printu]]. Because [[app]] is "
               , ";  executed for side effects, its behavior cannot be "
               , ";  expressed using simple algebraic laws. \\basislabelapp "
               , ";  <predefined uScheme functions>=           "
               , "(define app (f xs)"
               , "  (if (null? xs)"
               , "    #f"
               , "    (begin (f (car xs)) (app f (cdr xs)))))"
               , ";  Each of the preceding functions processes every "
               , ";  element of its list argument. Functions [[exists?]] "
               , ";  and [[all?]] don't necessarily do so. Function "
               , ";  [[exists?]] stops the moment it finds a satisfying "
               , ";  element; [[all?]] stops the moment it finds a non "
               , ";  -satisfying element. \\basislabelexists?,all? "
               , ";  <predefined uScheme functions>=           "
               , "(define exists? (p? xs)"
               , "  (if (null? xs)"
               , "    #f"
               , "    (if (p? (car xs)) "
               , "      #t"
               , "      (exists? p? (cdr xs)))))"
               , "(define all? (p? xs)"
               , "  (if (null? xs)"
               , "    #t"
               , "    (if (p? (car xs))"
               , "      (all? p? (cdr xs))"
               , "      #f)))"
               , ";  Finally, [[foldr]] and [[foldl]], although simple, "
               , ";  are not necessarily easy to understand. Study their "
               , ";  algebraic laws, and remember that \\monobox(car xs) is "
               , ";  always a first argument to [[combine]], and [[zero]] "
               , ";  is always a second argument. \\basislabelfoldl,foldr "
               , ";  <predefined uScheme functions>=           "
               , "(define foldr (combine zero xs)"
               , "  (if (null? xs)"
               , "    zero"
               , "    (combine (car xs) (foldr combine zero (cdr xs)))))"
               , "(define foldl (combine zero xs)"
               , "  (if (null? xs)"
               , "    zero"
               , "    (foldl combine (combine (car xs) zero) (cdr xs))))"
               , ";  \\qbreak                                      "
               , ";                                               "
               , ";  Unicode code points                          "
               , ";                                               "
               , ";  micro-Scheme has no string literals; it has only "
               , ";  quoted symbols. To print a character that can't "
               , ";  appear in a quoted symbol, use one of these code "
               , ";  points:                                      "
               , ";  <predefined uScheme functions>=           "
               , "(val newline      10)   (val left-round    40)"
               , "(val space        32)   (val right-round   41)"
               , "(val semicolon    59)   (val left-curly   123)"
               , "(val quotemark    39)   (val right-curly  125)"
               , "                        (val left-square   91)"
               , "                        (val right-square  93)"
               , ";  Integer functions                            "
               , ";                                               "
               , ";  The non-primitive integer operations are defined "
               , ";  exactly as they would be in Impcore. First, the "
               , ";  comparisons.                                 "
               , ";  <predefined uScheme functions>=           "
               , "(define <= (x y) (not (> x y)))"
               , "(define >= (x y) (not (< x y)))"
               , "(define != (x y) (not (= x y)))"
               , ";  Next, [[min]] and [[max]].                   "
               , ";  <predefined uScheme functions>=           "
               , "(define max (x y) (if (> x y) x y))"
               , "(define min (x y) (if (< x y) x y))"
               , ";  Finally, negation, modulus, greatest common divisor, "
               , ";  and least common multiple.                   "
               , ";  <predefined uScheme functions>=           "
               , "(define negated (n) (- 0 n))"
               , "(define mod (m n) (- m (* n (/ m n))))"
               , "(define gcd (m n) (if (= n 0) m (gcd n (mod m n))))"
               , "(define lcm (m n) (if (= m 0) 0 (* m (/ n (gcd m n)))))"
               , ";  The functions below, by contrast, are silver. "
               , ";  (``Gold'' would be a variadic [[list]] function such "
               , ";  as would be enabled by completing \\cref      "
               , ";  mlscheme.ex.varargs in \\crefmlscheme.chap. Or a "
               , ";  variadic [[list]] primitive.) \\basislabel    "
               , ";  list4,list5,list6,list7,list8                "
               , ";  <predefined uScheme functions>=           "
               , "(define list4 (x y z a)         (cons x (list3 y z a)))"
               , "(define list5 (x y z a b)       (cons x (list4 y z a b)))"
               , "(define list6 (x y z a b c)     (cons x (list5 y z a b c)))"
               , "(define list7 (x y z a b c d)   (cons x (list6 y z a b c d)))"
               ,
               "(define list8 (x y z a b c d e) (cons x (list7 y z a b c d e)))"
                ]

val initialBasis =
  let val xdefs = stringsxdefs ("predefined functions", predefs)
  in  readEvalPrintWith predefinedFunctionError
                        (xdefs, primitiveBasis, noninteractive)
  end
(* Using primitives to build an initial basis   *)
(*                                              *)
(* A basis for micro-Scheme comprises a single value *)
(* environment. The initial basis is built by starting *)
(* with the empty environment, binding the primitive *)
(* operators, then reading the predefined functions. *)
(*                                              *)
(* \qbreak All the primitives on the list defined by *)
(* [[]] are lifted                              *)
(* using [[inExp]]. Only the [[errorPrimitive]] is bound *)
(* straight into the environment. [*] \makenowebnotdef *)
(* (from \LAadditions to the micro-Scheme initial basis *)
(* \upshape[->]\RA)                             *)
(* <boxed values 129>=                          *)
val _ = op primitiveBasis : basis
val _ = op initialBasis : basis


(*****************************************************************)
(*                                                               *)
(*   FUNCTION [[RUNSTREAM]], WHICH EVALUATES INPUT GIVEN [[INITIALBASIS]] *)
(*                                                               *)
(*****************************************************************)

(* <function [[runStream]], which evaluates input given [[initialBasis]]>= *)
fun runStream inputName input interactivity basis = 
  let val _ = setup_error_format interactivity
      val prompts = if prompts interactivity then stdPrompts else noPrompts
      val xdefs = filexdefs (inputName, input, prompts)
  in  readEvalPrintWith eprintln (xdefs, basis, interactivity)
  end 
(* A last word about function [[readEvalPrintWith]]: you *)
(* might be wondering, ``where does it read, evaluate, *)
(* and print?'' It has helpers for that: reading is a *)
(* side effect of [[streamGet]], which is called by *)
(* [[streamFold]], and evaluating and printing are done *)
(* by [[processDef]]. But the function is called *)
(* [[readEvalPrintWith]] because when you want reading, *)
(* evaluating, and printing to happen, you call \monobox *)
(* readEvalPrintWith eprintln, passing your extended *)
(* definitions and your environments.           *)
(*                                              *)
(* Handling exceptions                          *)
(*                                              *)
(* When an exception is raised, a bridge-language *)
(* interpreter must ``catch'' or ``handle'' it. *)
(* An exception is caught using a syntactic form written *)
(* with the keyword [[handle]]. (This form resembles a *)
(* combination of a [[case]] expression with the *)
(* [[try-catch]] form from \crefschemes.chap.) Within *)
(* the [[handle]], every exception that the interpreter *)
(* recognizes is mapped to an error message tailored for *)
(* that exception. To be sure that every exception is *)
(* responded to in the same way, no matter where it is *)
(* handled, I write just a single [[handle]] form, and I *)
(* deploy it in a higher-order, continuation-passing *)
(* function: [[withHandlers]].                  *)
(*                                              *)
(* In normal execution, calling \monoboxwithHandlers f a *)
(* caught applies function [[f]] to argument [[a]] and *)
(* returns the result. But when the application f a *)
(* raises an exception, [[withHandlers]] uses [[handle]] *)
(* to recover from the exception and to pass an error *)
(* message to [[caught]], which acts as a failure *)
(* continuation (\crefpage,scheme.cps). Each error *)
(* message contains the string [["<at loc>"]], which can *)
(* be removed (by [[stripAtLoc]]) or can be filled in *)
(* with an appropriate source-code location (by  *)
(* [[fillAtLoc]]).                              *)
(*                                              *)
(* The most important exceptions are [[NotFound]], *)
(* [[RuntimeError]], and [[Located]]. Exception *)
(* [[NotFound]] is defined in \crefmlscheme.chap; the *)
(* others are defined in this appendix. Exceptions *)
(* [[NotFound]] and [[RuntimeError]] signal problems *)
(* with an environment or with evaluation, respectively. *)
(* Exception [[Located]] wraps another exception [[exn]] *)
(* in a source-code location. When [[Located]] is *)
(* caught, [[withHandlers]] calls itself recursively *)
(* with a function that ``re-raises'' exception [[exn]] *)
(* and with a failure continuation that fills in the *)
(* source location in [[exn]]'s error message.  *)
(* <boxed values 63>=                           *)
val _ = op withHandlers : ('a -> 'b) -> 'a -> (string -> 'b) -> 'b
(* A bridge-language interpreter can be run on standard *)
(* input or on a named file. Either one can be converted *)
(* to a stream, so the code that runs an interpreter is *)
(* defined on a stream, by function [[runStream]]. This *)
(* runs the code found in a given, named input, using a *)
(* given interactivity mode. The interactivity mode *)
(* determines both the error format and the prompts. *)
(* Function [[runStream]] then starts the       *)
(* read-eval-print loop, using the initial basis. [*] \ *)
(* nwnarrowboxes                                *)
(* <boxed values 63>=                           *)
val _ = op runStream : string -> TextIO.instream -> interactivity -> basis ->
                                                                           basis


(*****************************************************************)
(*                                                               *)
(*   LOOK AT COMMAND-LINE ARGUMENTS, THEN RUN                    *)
(*                                                               *)
(*****************************************************************)

(* <look at command-line arguments, then run>=  *)
fun runPathWith interactivity ("-", basis) =
      runStream "standard input" TextIO.stdIn interactivity basis
  | runPathWith interactivity (path, basis) =
      let val fd = TextIO.openIn path
      in  runStream path fd interactivity basis
          before TextIO.closeIn fd
      end 
(* <boxed values 64>=                           *)
val _ = op runPathWith : interactivity -> (string * basis -> basis)
(* <look at command-line arguments, then run>=  *)
val usage = ref (fn () => ())
(* If an interpreter doesn't recognize a command-line *)
(* option, it can print a usage message. A usage-message *)
(* function needs to know the available options, but *)
(* each available option is associated with a function *)
(* that performs an action, and if something goes wrong, *)
(* the action function might need to call the usage *)
(* function. I resolve this mutual recursion by first *)
(* allocating a mutual cell to hold the usage function, *)
(* then updating it later. This is also how [[letrec]] *)
(* is implemented in micro-Scheme.              *)
(* <boxed values 65>=                           *)
val _ = op usage : (unit -> unit) ref
(* \qbreak To represent actions that might be called for *)
(* by command-line options, I define type [[action]]. *)
(* <look at command-line arguments, then run>=  *)
datatype action
  = RUN_WITH of interactivity  (* call runPathWith on remaining arguments *)
  | DUMP     of unit -> unit   (* dump information *)
  | FAIL     of string         (* signal a bad command line *)
  | DEFAULT                    (* no command-line options were given *)
(* The default action is to run the interpreter in its *)
(* most interactive mode.                       *)
(* <look at command-line arguments, then run>=  *)
val default_action = RUN_WITH (PROMPTING, ECHOING)
(* <look at command-line arguments, then run>=  *)
fun perform (RUN_WITH interactivity, []) =
      perform (RUN_WITH interactivity, ["-"])
  | perform (RUN_WITH interactivity, args) =
      ignore (foldl (runPathWith interactivity) initialBasis args)
  | perform (DUMP go, [])     = go ()
  | perform (DUMP go, _ :: _) = perform (FAIL "Dump options take no files", [])
  | perform (FAIL msg, _)     = (eprintln msg; !usage())
  | perform (DEFAULT, args)   = perform (default_action, args)
(* Now micro-Scheme primitives like [[+]] and [[*]] can *)
(* be defined by applying first [[arithOp]] and then *)
(* [[inExp]] to their ML counterparts.          *)
(*                                              *)
(* The micro-Scheme primitives are organized into a list *)
(* of (name, function) pairs, in Noweb code chunk *)
(* [[]].                                        *)
(* Each primitive on the list has type \monoboxvalue *)
(* list -> value. In \chunkrefmlscheme.inExp-applied, *)
(* each primitive is passed to [[inExp]], and the *)
(* results are used build micro-Scheme's initial *)
(* environment. [Actually, the list contains all the *)
(* primitives except one: the [[error]] primitive, which *)
(* must not be wrapped in [[inExp]].] The list of *)
(* primitives begins with these four elements:  *)
(* <boxed values 66>=                           *)
val _ = op perform: action * string list -> unit
(* <look at command-line arguments, then run>=  *)
fun merge (_, a as FAIL _) = a
  | merge (a as FAIL _, _) = a
  | merge (DEFAULT, a) = a
  | merge (_, DEFAULT) = raise InternalError "DEFAULT on the right in MERGE"
  | merge (RUN_WITH _, right as RUN_WITH _) = right
  | merge (DUMP f, DUMP g) = DUMP (g o f)
  | merge (_, r) = FAIL "Interpret or dump, but don't try to do both"
(* <boxed values 67>=                           *)
val _ = op merge: action * action -> action
(* <look at command-line arguments, then run>=  *)
val actions =
  [ ("",    RUN_WITH (PROMPTING,     ECHOING))
  , ("-q",  RUN_WITH (NOT_PROMPTING, ECHOING))
  , ("-qq", RUN_WITH (NOT_PROMPTING, NOT_ECHOING))
  , ("-names",      DUMP (fn () => dump_names initialBasis))
  , ("-primitives", DUMP (fn () => dump_names primitiveBasis))
  , ("-help",       DUMP (fn () => !usage ()))
  ]
                                                          (*OMIT*)
val unusedActions =  (* reveals answers to homeworks *)   (*OMIT*)
  [ ("-predef",     DUMP (fn () => app println predefs))  (*OMIT*)
  ]                                                       (*OMIT*)
(* Each possible command-line option is associated with *)
(* an action. Options [[-q]] and [[-qq]] suppress *)
(* prompts and echos. Options [[-names]] and    *)
(* [[-primitives]] dump information found in the initial *)
(* basis.                                       *)
(* <boxed values 68>=                           *)
val _ = op actions : (string * action) list
(* The [[xdeftable]] is shared with the Impcore parser. *)
(* Function [[reduce_to_xdef]] is almost shareable as *)
(* well, but not quite---the abstract syntax of *)
(* [[DEFINE]] is different.                     *)

(* \qbreak Now that the available command-line options *)
(* are known, I can define a usage function. Function *)
(* [[CommandLine.name]] returns the name by which the *)
(* interpreter was invoked.                     *)
(* <look at command-line arguments, then run>=  *)
val _ = usage := (fn () =>
  ( app eprint ["Usage:\n"]
  ; app (fn (option, action) =>
         app eprint ["       ", CommandLine.name (), " ", option, "\n"]) actions
  ))
(* <look at command-line arguments, then run>=  *)
fun action option =
  case List.find (curry op = option o fst) actions
    of SOME (_, action) => action
     | NONE => FAIL ("Unknown option " ^ option)
(* Options are parsed by function [[action]].   *)
(* <boxed values 69>=                           *)
val _ = op action : string -> action
(* The [[xdeftable]] is shared with the Impcore parser. *)
(* Function [[reduce_to_xdef]] is almost shareable as *)
(* well, but not quite---the abstract syntax of *)
(* [[DEFINE]] is different.                     *)

(* <look at command-line arguments, then run>=  *)
fun strip_options a [] = (a, [])
  | strip_options a (arg :: args) =
      if String.isPrefix "-" arg andalso arg <> "-" then
          strip_options (merge (a, action arg)) args
      else
          (a, arg :: args)

val _ = if hasOption "NORUN" then ()
        else perform (strip_options DEFAULT (CommandLine.arguments ()))
(* <boxed values 70>=                           *)
val _ = op strip_options : action -> string list -> action * string list
(* Lexical analysis, parsing, and reading input using ML *)
(*                                              *)
(* [*][*] \invisiblelocaltableofcontents[*]     *)
(*                                              *)
(* How is a program represented? If you have worked *)
(* through this book, you will believe (I hope) that the *)
(* most fundamental and most useful representation of a *)
(* program is its abstract-syntax tree. But syntax trees *)
(* aren't easy to create or specify directly, so syntax *)
(* usually has to be written using a sequence of *)
(* characters. To help myself write parsers by hand, *)
(* I have created [I~say ``created,'' but it would be *)
(* more accurate to say ``stolen.'' ] a set of  *)
(* higher-order functions designed especially to *)
(* manipulate parsers. Such functions are known as *)
(* parsing combinators. My parsing combinators appear in *)
(* this appendix.                               *)
(*                                              *)
(* Most parsing techniques have been invented for use in *)
(* compilers. and a typical compiler swallows programs *)
(* in large gulps, one file at a time. Unlike these *)
(* typical compilers, the interpreters in this book are *)
(* interactive, and they swallow just one line at a *)
(* time. Interactivity imposes additional requirements: *)
(*                                              *)
(*   • Before reading a line of input, an interactive *)
(*  interpreter should issue a suitable prompt. *)
(*  The prompt should tell the user whether the *)
(*  parser is waiting for a new definition or is in *)
(*  the middle of parsing a current definition—which *)
(*  means that the line-reading functions must be in *)
(*  cahoots with the parser.                    *)
(*   • If a parser encounters an error, it can't just *)
(*  give up. It needs to get itself back into a state *)
(*  where the user can continue to interact.    *)
(*                                              *)
(* These requirements make my parsing combinators a bit *)
(* different from standard ones. In particular, in order *)
(* to be sure that the actions of printing a prompt and *)
(* reading a line of input occur in the proper sequence, *)
(* I manage these actions using the lazy streams defined *)
(* in \crefmlinterps.streams. Unlike the lazy streams *)
(* built into Haskell, these lazy streams can do input *)
(* and output and can perform other actions.    *)
(*                                              *)
(* Parsing is about turning a stream of lines (from a *)
(* file or from a list of strings) into a stream of *)
(* extended definitions. It happens in stages:  *)
(*                                              *)
(*   • In a stream of lines, each line is split into *)
(*  characters.                                 *)
(*   • A lexical analyzer turns a stream of characters *)
(*  into a stream of tokens. Using              *)
(*  [[streamConcatMap]] with the lexical analyzer *)
(*  then turns a stream of lines into a stream of *)
(*  tokens.                                     *)
(*   • A parser turns a stream of tokens into a stream *)
(*  of syntax. I define parsers for expressions, true *)
(*  definitions, unit tests, and extended       *)
(*  definitions.                                *)
(*                                              *)
(* The fundamental parser is [[one]], which takes one *)
(* token from a stream and produces that token. Other *)
(* parsers are built on top of [[one]], usually using *)
(* higher-order functions. Functions [[<>]] and [[<*>]] *)
(* act like [[map]] for parsers, applying a function the *)
(* result a parser returns. Function [[sat]] acts like *)
(* [[filter]], allowing a parser to fail if it doesn't *)
(* recognize its input. Functions [[<*>]], [[<*]], and  *)
(* [[*>]] combine parsers in sequence, and function *)
(* [[<|>]] defines a parser as a choice between two *)
(* other parsers. Functions [[many]] and [[many1]] turn *)
(* a parser for a thing into a parser for a list of *)
(* things; function [[optional]] does the same thing for *)
(* ML's [[option]] type. These functions are known *)
(* collectively as parsing combinators, and together *)
(* they form a powerful language for defining lexical *)
(* analyzers and parsers.                       *)
(*                                              *)
(* I divide parsers and parsing combinators into three *)
(* groups:                                      *)
(*                                              *)
(*   • A stream transformer doesn't care what comes in *)
(*  or goes out; it is polymorphic in both the input *)
(*  and output type. Stream transformers are used to *)
(*  build both lexical analyzers and parsers.   *)
(*   • A lexer is a stream transformer that is *)
(*  specialized to take a stream of characters as *)
(*  input. Lexers may be defined with any output *)
(*  type, but a value of that output type should *)
(*  represent a token.                          *)
(*   • A parser is a stream transformer that is *)
(*  specialized to take a stream of tokens as input. *)
(*  A parser's input stream also includes source-code *)
(*  locations and end-of-line markers. Parsers may be *)
(*  defined with any output type, but the rest of the *)
(*  interpreter is most interested in the parser that *)
(*  produces a stream of definitions (abstract-syntax *)
(*  trees).                                     *)
(*                                              *)
(* The polymorphic functions are described in \crefpage *)
(* (lazyparse.fig.xformer; the specialized functions are *)
(* described in \crefpage(lazyparse.fig.lexers-parsers. *)
(*                                              *)
(* The code is divided among these chunks:      *)

