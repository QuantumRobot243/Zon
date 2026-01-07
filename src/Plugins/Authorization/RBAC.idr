module Plugins.Authorization.RBAC

import Core.Interfaces
import Core.Effects
import Effect.StdIO

%default total

public export
rbacAuthZPluginId : String
rbacAuthZPluginId = "rbac-authz"

-- Simple RBAC: enhance session capabilities based on roles.
-- In a real system, this would load policies from a config/DB.
implementation AuthZPlugin rbacAuthZPluginId where
  authorize session = do
    putStrLn ("RBAC Plugin: Authorizing user " ++ session.userName ++ " with roles " ++ show session.userRoles)
    let newCapabilities =
          if elem "admin" session.userRoles
            then [MkRuntimeCapability Delete "all-critical-data", MkRuntimeCapability AdminOp "system"]
            else []
    pure $ MkUserSession session.userId session.userName session.userRoles
           (session.capabilities ++ newCapabilities)
