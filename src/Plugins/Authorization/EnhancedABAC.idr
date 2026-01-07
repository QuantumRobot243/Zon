module Plugins.Authorization.EnhancedABAC

import Core.Interfaces.Authorization
import Core.Types.Session
import Core.Types.Policy
import Core.Types.Capability
import Data.SortedMap
import Data.SortedSet
import Data.List

%default total

public export
enhancedABACId : String
enhancedABACId = "enhanced-abac"

private
evaluateUserAttributes : String -> SortedMap String String -> List Capability
evaluateUserAttributes userId attrs =
  case lookup "department" attrs of
    Just "admin" =>
      [ MkCapability Write (Exact "admin-reports")
      , MkCapability Delete (Prefix "temp-")
      ]
    Just "engineering" =>
      [ MkCapability Read (Prefix "code/")
      , MkCapability Write (Prefix "code/")
      ]
    _ => [MkCapability Read (Exact "public-data")]

public export
AuthorizationProvider enhancedABACId where
  authorize session = do
    putStrLn ("ABAC: Authorizing user " ++ session.userName ++
              " with ID " ++ session.userId)
    let attrs = fromList [("department", if session.userId == "4"
                                         then "admin" else "engineering")]
    let attrCaps = evaluateUserAttributes session.userId attrs
    let allCaps = nub (session.capabilities ++ attrCaps)
    pure ({ capabilities := allCaps } session)

  checkAccess context = do
    let cap = context.requestedCapability
    let hasCap = any (\c => c.capType == cap.capType &&
                     matches c.resource (show cap.resource))
                     context.session.capabilities
    if hasCap
      then pure (MkAuthZResult True [cap] [enhancedABACId] "Access granted")
      else pure (MkAuthZResult False [] [enhancedABACId] "Access denied")

  getPoliciesForUser userId = pure []

  evaluatePolicy policy context = pure Nothing

public export
AttributeBasedAccessControl where
  evaluateAttributes attrs context = do
    let caps = evaluateUserAttributes context.session.userId attrs
    pure (MkAuthZResult True caps [enhancedABACId] "Attributes evaluated")

  getUserAttributes userId =
    pure (fromList [("department", "engineering"), ("level", "senior")])

  getResourceAttributes resource =
    pure (fromList [("classification", "public"), ("owner", "system")])

public export
enhancedABACProvider : AuthorizationProvider enhancedABACId
enhancedABACProvider = %search
