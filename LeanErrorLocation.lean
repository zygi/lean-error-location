import Lean.Elab.Term
import AssertCmd

namespace LeanErrorLocation
open Lean
open Lean.Elab.Term

-- This library exports two macros:
-- 1) `__lineNum__` : gets replaced with an instance of the CodeLocation structure below.
-- 2) `withCL[...]` : expects an argument `(f: CodeLocation -> α)` and replaces it with `(f __lineNum__)`.
--
-- As an example, also exports `mkIOUserError`, a wrapper to construct an IO.userError with code
-- location. Example usage:
-- `throw withCL[mkIOUserError "error"]` -- will return `IO.userError "error at {codeloc}"`
--
-- Note: remember that the location you're getting at macro expansion time. If you do
-- ```
-- def a := toString __lineNum__
-- #eval a
-- ```
-- you'll get the code location of the line with `def a`, not the one with `#eval`.

structure CodeLocation where
  fileName: String
  posInFile: Position
  deriving Repr, BEq, Inhabited

instance : ToString CodeLocation where
  toString cl := s!"{cl.fileName}:{cl.posInFile.line}:{cl.posInFile.column}" 

syntax (name:=lineNumMacro) "__lineNum__" : term

@[termElab lineNumMacro]
def expandLineNumMacro : TermElab := fun stx _ => do
let ctx ← read
let arg := stx.getArg 0
match arg with
  | Syntax.atom i _ => do
    let posInFile ← match i.getPos? with
      | none => Lean.Elab.throwUnsupportedSyntax
      | some x => x
    let resolvedPos := ctx.fileMap.toPosition posInFile
    let newStx : Syntax ←
      `(CodeLocation.mk ($(Syntax.mkStrLit ctx.fileName))
          (Position.mk 
            $(Syntax.mkNumLit $ toString resolvedPos.line)
            $(Syntax.mkNumLit $ toString resolvedPos.column)))
    elabTerm newStx none
  | _ => Lean.Elab.throwUnsupportedSyntax

macro "withCL[" fn:term "]" : term=> `(($fn) __lineNum__)

def mkIOUserError (s: String) (cl: CodeLocation) := IO.userError s!"{s} at {cl}"

section Test

def arg1 := toString __lineNum__
#assert (arg1 == "<input>:57:21" || arg1 == "LeanErrorLocation.lean:57:21") == true

def arg2 := withCL[mkIOUserError "tragedy! horror!"].toString
#assert (arg2 ==
           toString (IO.userError "tragedy! horror! at <input>:60:12") ||
         arg2 ==
           toString (IO.userError "tragedy! horror! at LeanErrorLocation.lean:60:12")) == true

end Test

end LeanErrorLocation
