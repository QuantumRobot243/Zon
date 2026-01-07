module Plugins.Authorization.EnhancedRBAC

import Core.Interfaces.Authorization
import Core.Types.Session
import Core.Types.Policy
import Core.Types.Capability
import Data.SortedMap
import Data.SortedSet
import Data.List

%default total

public export
enhancedRBACId : String
enhancedRBACId = "enhanced-rbac"

private
getRoleCapabilities : String -> List Capability
getRoleCapabilities "admin" =
  [ MkCapability Delete (Exact "critical-data")
  , MkCapability AdminOp (Exact "system")
  , MkCapability Execute Wildcard
  ]
getRoleCapabilities "editor" =
  [ MkCapability Write (Prefix "docs/")
  , MkCapability Delete (Prefix "docs/temp/")
  ]
getRoleCapabilities "developer" =
  [ MkCapability Read (Prefix "project-")
  , MkCapability Write (Prefix "project-")
  , MkCapability Execute (Prefix "scripts/")
  ]
getRoleCapabilities _ = []

public export
AuthorizationProvider enhancedRBACId where
  authorize session = do
    putStrLn ("RBAC: Authorizing " ++ session.userName ++
              " with roles " ++ show (SortedSet.toList session.userRoles))
    let roleCaps = concat $ map getRoleCapabilities
                           (SortedSet.toList session.userRoles)
    let allCaps = nub (session.capabilities ++ roleCaps)
    pure ({ capabilities := allCaps } session)

  checkAccess context = do
    let cap = context.requestedCapability
    let hasCap = any (\c => c.capType == cap.capType &&
                     matches c.resource (show cap.resource))
                     context.session.capabilities
    if hasCap
      then pure (MkAuthZResult True [cap] [enhancedRBACId] "Access granted")
      else pure (MkAuthZResult False [] [enhancedRBACId] "Access denied")

  getPoliciesForUser userId = pure []

  evaluatePolicy policy context = pure Nothing

public export
RoleBasedAccessControl where
  assignRole userId role = do
    putStrLn ("Assigning role " ++ role ++ " to user " ++ userId)
    pure True

  revokeRole userId role = do
    putStrLn ("Revoking role " ++ role ++ " from user " ++ userId)
    pure True

  getRoles userId = pure ["default"]

  getRoleCapabilities role = pure (getRoleCapabilities role)

public export
enhancedRBACProvider : AuthorizationProvider enhancedRBACId
enhancedRBACProvider = %search
