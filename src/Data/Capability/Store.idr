module Data.Capability.Store

import Data.AVLTree
import Data.SortedMap
import Data.SortedSet

%default total

public export
record CapabilityKey where
  constructor MkCapKey
  capType : String
  resource : String

public export
Eq CapabilityKey where
  (MkCapKey c1 r1) == (MkCapKey c2 r2) = c1 == c2 && r1 == r2

public export
Ord CapabilityKey where
  compare (MkCapKey c1 r1) (MkCapKey c2 r2) =
    case compare c1 c2 of
      EQ => compare r1 r2
      x => x

public export
record CapabilityStore where
  constructor MkCapStore
  capabilities : SortedMap CapabilityKey (SortedSet String)
  resourceIndex : SortedMap String (SortedSet CapabilityKey)
  userCapabilities : SortedMap String (SortedSet CapabilityKey)

public export
emptyStore : CapabilityStore
emptyStore = MkCapStore empty empty empty

public export
addCapability : String -> CapabilityKey -> CapabilityStore -> CapabilityStore
addCapability userId key store =
  let userCaps = fromMaybe empty (lookup userId store.userCapabilities)
      newUserCaps = insert key userCaps
      caps = fromMaybe empty (lookup key store.capabilities)
      newCaps = insert userId caps
      resIdx = fromMaybe empty (lookup key.resource store.resourceIndex)
      newResIdx = insert key resIdx
  in MkCapStore
       (insert key newCaps store.capabilities)
       (insert key.resource newResIdx store.resourceIndex)
       (insert userId newUserCaps store.userCapabilities)

public export
hasCapability : String -> CapabilityKey -> CapabilityStore -> Bool
hasCapability userId key store =
  case lookup userId store.userCapabilities of
    Just caps => contains key caps
    Nothing => False

public export
getUserCapabilities : String -> CapabilityStore -> List CapabilityKey
getUserCapabilities userId store =
  case lookup userId store.userCapabilities of
    Just caps => SortedSet.toList caps
    Nothing => []

public export
getResourceCapabilities : String -> CapabilityStore -> List CapabilityKey
getResourceCapabilities resource store =
  case lookup resource store.resourceIndex of
    Just keys => SortedSet.toList keys
    Nothing => []
