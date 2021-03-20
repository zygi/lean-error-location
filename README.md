#### A small library providing macros to add source location to monadic error handling.

This library exports two macros:
1) `__lineNum__` : gets replaced with an instance of the CodeLocation structure below.
2) `withCL[...]` : expects an argument `(f: CodeLocation -> α)` and replaces it with `(f __lineNum__)`.

As an example, it also exports `mkIOUserError`, a wrapper to construct an IO.userError with code
location. Example usage:
`throw withCL[mkIOUserError "error"]` -- will return `IO.userError "error at {codeloc}"`

Note: remember that the location you're getting at macro expansion time. If you do
```lean4
def a := toString __lineNum__
#eval a
```
you'll get the code location of the line with `def a`, not the one with `#eval`.
