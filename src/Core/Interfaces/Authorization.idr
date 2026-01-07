module Core.Interfaces.Authorization

import Core.Types.Session
import Core.Types.Policy
import Core.Types.Capability
import Data.SortedMap

%default total

public export
record AuthorizationContext where
  constructor MkAuthZContext
  session : UserSession
  requestedCapability : Capability
  environment : SortedMap String String
  timestamp : Integer

public export
record AuthorizationResult where
  constructor MkAuthZResult
  granted : Bool
  capabilities : List Capability
  appliedPolicies : List String
  reason : String

public export
interface AuthorizationProvider (provider : String) where
  authorize : UserSession -> IO UserSession
  checkAccess : AuthorizationContext -> IO AuthorizationResult
  getPoliciesForUser : String -> IO (List Policy)
  evaluatePolicy : Policy -> AuthorizationContext -> IO (Maybe PolicyEffect)

public export
interface RoleBasedAccessControl where
  assignRole : String -> String -> IO Bool
  revokeRole : String -> String -> IO Bool
  getRoles : String -> IO (List String)
  getRoleCapabilities : String -> IO (List Capability)

public export
interface AttributeBasedAccessControl where
  evaluateAttributes : SortedMap String String ->
                      AuthorizationContext ->
                      IO AuthorizationResult
  getUserAttributes : String -> IO (SortedMap String String)
  getResourceAttributes : String -> IO (SortedMap String String)

