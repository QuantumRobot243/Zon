module Core.Types.Capability

import Decidable.Equality
import Data.String

%default total

public export
data CapabilityType : Type where
  Read    : CapabilityType
  Write   : CapabilityType
  Delete  : CapabilityType
  Execute : CapabilityType
  AdminOp : CapabilityType

public export
Eq CapabilityType where
  Read == Read = True
  Write == Write = True
  Delete == Delete = True
  Execute == Execute = True
  AdminOp == AdminOp = True
  _ == _ = False

public export
Ord CapabilityType where
  compare Read Read = EQ
  compare Read _ = LT
  compare Write Read = GT
  compare Write Write = EQ
  compare Write _ = LT
  compare Delete Read = GT
  compare Delete Write = GT
  compare Delete Delete = EQ
  compare Delete _ = LT
  compare Execute Read = GT
  compare Execute Write = GT
  compare Execute Delete = GT
  compare Execute Execute = EQ
  compare Execute AdminOp = LT
  compare AdminOp AdminOp = EQ
  compare AdminOp _ = GT

public export
Show CapabilityType where
  show Read = "Read"
  show Write = "Write"
  show Delete = "Delete"
  show Execute = "Execute"
  show AdminOp = "AdminOp"

public export
DecEq CapabilityType where
  decEq Read Read = Yes Refl
  decEq Write Write = Yes Refl
  decEq Delete Delete = Yes Refl
  decEq Execute Execute = Yes Refl
  decEq AdminOp AdminOp = Yes Refl
  decEq Read Write = No (\Refl impossible)
  decEq Read Delete = No (\Refl impossible)
  decEq Read Execute = No (\Refl impossible)
  decEq Read AdminOp = No (\Refl impossible)
  decEq Write Read = No (\Refl impossible)
  decEq Write Delete = No (\Refl impossible)
  decEq Write Execute = No (\Refl impossible)
  decEq Write AdminOp = No (\Refl impossible)
  decEq Delete Read = No (\Refl impossible)
  decEq Delete Write = No (\Refl impossible)
  decEq Delete Execute = No (\Refl impossible)
  decEq Delete AdminOp = No (\Refl impossible)
  decEq Execute Read = No (\Refl impossible)
  decEq Execute Write = No (\Refl impossible)
  decEq Execute Delete = No (\Refl impossible)
  decEq Execute AdminOp = No (\Refl impossible)
  decEq AdminOp Read = No (\Refl impossible)
  decEq AdminOp Write = No (\Refl impossible)
  decEq AdminOp Delete = No (\Refl impossible)
  decEq AdminOp Execute = No (\Refl impossible)

public export
data ResourcePattern = Exact String | Wildcard | Prefix String

public export
Eq ResourcePattern where
  (Exact x) == (Exact y) = x == y
  Wildcard == Wildcard = True
  (Prefix x) == (Prefix y) = x == y
  _ == _ = False

public export
Show ResourcePattern where
  show (Exact s) = s
  show Wildcard = "*"
  show (Prefix s) = s ++ "*"

public export
matches : ResourcePattern -> String -> Bool
matches (Exact pattern) resource = pattern == resource
matches Wildcard _ = True
matches (Prefix prefix) resource = isPrefixOf prefix resource

public export
record Capability where
  constructor MkCapability
  capType : CapabilityType
  resource : ResourcePattern

public export
Eq Capability where
  (MkCapability c1 r1) == (MkCapability c2 r2) = c1 == c2 && r1 == r2

public export
Show Capability where
  show (MkCapability cap res) = show cap ++ ":" ++ show res

export
data HasCapability : CapabilityType -> String -> Type where
  Evidence : (c : CapabilityType) -> (r : String) -> HasCapability c r

export
MkCapabilityProof : (c : CapabilityType) -> (r : String) -> HasCapability c r
MkCapabilityProof c r = Evidence c r
