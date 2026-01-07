module Plugins.Authorization.ABAC

import Core.Interfaces
import Core.Effects
import Effect.StdIO

%default total

abacAuthZPluginId : String
abacAuthZPluginId = "abac-authz"

-- In a real ABAC system, this would involve comparing user attributes
-- (e.g., department, location) with resource attributes and policies.
-- For this example, we'll add some capabilities based on user ID.
implementation AuthZPlugin abacAuthZPluginId where
  authorize session = do
    putStrLn ("ABAC Plugin: Authorizing user " ++ session.userName ++ " with ID " ++ session.userId)
    let newCapabilities =
          if session.userId == "1" -- Admin User from StaticAuth
            then [MkRuntimeCapability Write "admin-reports", MkRuntimeCapability Delete "temp-files"]
            else if session.userId == "3" -- JWT User from JWTAuth
              then [MkRuntimeCapability Read "public-data"]
              else []
    pure $ MkUserSession session.userId session.userName session.userRoles
           (session.capabilities ++ newCapabilities)
