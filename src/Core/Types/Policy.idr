module Core.Types.Policy

import Core.Types.Capability
import Core.Types.Session
import Data.SortedSet
import Data.SortedMap

%default total

public export
data PolicyEffect = Allow | Deny

public export
Eq PolicyEffect where
  Allow == Allow = True
  Deny == Deny = True
  _ == _ = False

public export
Show PolicyEffect where
  show Allow = "Allow"
  show Deny = "Deny"

public export
record Condition where
  constructor MkCondition
  attribute : String
  operator : String
  value : String

public export
Eq Condition where
  (MkCondition a1 o1 v1) == (MkCondition a2 o2 v2) =
    a1 == a2 && o1 == o2 && v1 == v2

public export
record PolicyStatement where
  constructor MkPolicyStatement
  effect : PolicyEffect
  capabilities : List Capability
  conditions : List Condition

public export
record Policy where
  constructor MkPolicy
  policyId : String
  policyName : String
  statements : List PolicyStatement
  priority : Nat

public export
Eq Policy where
  p1 == p2 = p1.policyId == p2.policyId

public export
Ord Policy where
  compare p1 p2 = compare p1.priority p2.priority

public export
evaluateCondition : Condition -> SortedMap String String -> Bool
evaluateCondition (MkCondition attr "eq" val) context =
  case lookup attr context of
    Just v => v == val
    Nothing => False
evaluateCondition (MkCondition attr "neq" val) context =
  case lookup attr context of
    Just v => v /= val
    Nothing => True
evaluateCondition (MkCondition attr "contains" val) context =
  case lookup attr context of
    Just v => isInfixOf val v
    Nothing => False
evaluateCondition _ _ = False

public export
evaluateStatement : PolicyStatement ->
                   CapabilityType ->
                   String ->
                   SortedMap String String ->
                   Maybe PolicyEffect
evaluateStatement stmt capType resource context =
  let capMatches = any (\c => c.capType == capType &&
                       matches c.resource resource) stmt.capabilities
      conditionsMatch = all (\cond => evaluateCondition cond context)
                           stmt.conditions
  in if capMatches && conditionsMatch then Just stmt.effect else Nothing

public export
evaluatePolicy : Policy ->
                CapabilityType ->
                String ->
                SortedMap String String ->
                Maybe PolicyEffect
evaluatePolicy policy capType resource context =
  let results = mapMaybe (\stmt => evaluateStatement stmt capType resource context)
                        policy.statements
  in case results of
       [] => Nothing
       (x :: xs) => Just x
