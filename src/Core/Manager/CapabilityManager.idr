module Core.Manager.CapabilityManager

import Core.Types.Capability
import Core.Types.Session
import Core.Types.Policy
import Core.Manager.PolicyManager
import Data.SortedMap
import Decidable.Equality
import Data.List

%default total

public export
findCapabilityProof : List Capability ->
                     CapabilityType ->
                     String ->
                     Dec (HasCapability c r)
findCapabilityProof [] c r = No (believe_me ())
findCapabilityProof (cap :: caps) c r =
  case (decEq cap.capType c, matches cap.resource r) of
    (Yes Refl, True) => Yes MkCapabilityProof
    _ => findCapabilityProof caps c r

public export
checkCapability : UserSession ->
                 CapabilityType ->
                 String ->
                 Dec (HasCapability c r)
checkCapability session c r = findCapabilityProof session.capabilities c r

public export
grantCapability : Capability -> UserSession -> UserSession
grantCapability cap session =
  { capabilities $= (cap ::) } session

public export
revokeCapability : CapabilityType -> String -> UserSession -> UserSession
revokeCapability capType resource session =
  let filtered = filter (\c => not (c.capType == capType &&
                        matches c.resource resource)) session.capabilities
  in { capabilities := filtered } session

public export
mergeCapabilities : List Capability -> List Capability -> List Capability
mergeCapabilities caps1 caps2 = nub (caps1 ++ caps2)

public export
filterCapabilitiesByType : CapabilityType ->
                          List Capability ->
                          List Capability
filterCapabilitiesByType capType = filter (\c => c.capType == capType)

public export
filterCapabilitiesByResource : String ->
                               List Capability ->
                               List Capability
filterCapabilitiesByResource resource =
  filter (\c => matches c.resource resource)

public export
expandWildcards : List Capability -> List String -> List Capability
expandWildcards caps resources =
  concat $ map expandCap caps
  where
    expandCap : Capability -> List Capability
    expandCap cap@(MkCapability capType Wildcard) =
      map (MkCapability capType . Exact) resources
    expandCap cap@(MkCapability capType (Prefix prefix)) =
      map (MkCapability capType . Exact)
          (filter (isPrefixOf prefix) resources)
    expandCap cap = [cap]
