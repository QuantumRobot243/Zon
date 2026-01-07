module Core.Manager

import Core.Interfaces
import Core.Effects
import Core.Util
import Data.List
import Data.String
import Effect.StdIO

%default total

-- A proof-generating function that checks if a *runtime* capability exists
-- and, if so, constructs the *compile-time proof*.
-- This function is a trusted bridge.
private
checkAndProveCapability : (c : CapabilityType) -> (resource : String) -> List RuntimeCapability -> Maybe (HasCapability c resource)
checkAndProveCapability c res [] = Nothing
checkAndProveCapability c res (rc :: rcs) =
  if rc.capType == c && rc.resourceId == res
    then Just MkCapabilityProof
    else checkAndProveCapability c res rcs

-- Main authentication function that returns a session along with the ability
-- to prove specific capabilities.
-- It also performs auditing.
public export
authenticateUser : (authNPluginId : String) ->
                   (AuthNPlugin authNPluginId `with` (authN : AuthNPlugin authNPluginId)) ->
                   (authZPluginId : String) ->
                   (AuthZPlugin authZPluginId `with` (authZ : AuthZPlugin authZPluginId)) ->
                   (auditPluginId : String) ->
                   (AuditPlugin auditPluginId `with` (audit : AuditPlugin auditPluginId)) ->
                   (username : String) ->
                   (password : String) ->
                   IO (Maybe UserSession)
authenticateUser authNPluginId authN authZPluginId authZ auditPluginId audit username password = do
  logEvent "AUTHENTICATION_ATTEMPT" ("User: " ++ username)
  authResult <- authenticate username password
  case authResult of
    Just session => do
      logEvent "AUTHENTICATION_SUCCESS" ("User: " ++ session.userName ++ ", AuthN by: " ++ authNPluginId)
      authorizedSession <- authorize session
      logEvent "AUTHORIZATION_PROCESS" ("User: " ++ authorizedSession.userName ++ ", AuthZ by: " ++ authZPluginId)
      pure (Just authorizedSession)
    Nothing => do
      logEvent "AUTHENTICATION_FAILURE" ("User: " ++ username ++ ", AuthN by: " ++ authNPluginId)
      pure Nothing

-- Helper to retrieve a compile-time proof from a UserSession.
-- This is what application code will call before a sensitive action.
public export
getCapabilityProof : (session : UserSession) ->
                     (c : CapabilityType) ->
                     (resource : String) ->
                     Maybe (HasCapability c resource)
getCapabilityProof session c resource =
  checkAndProveCapability c resource session.capabilities

-- Helper to explicitly log an audit event using the configured plugin.
public export
doAudit : (pluginId : String) ->
          (AuditPlugin pluginId `with` (audit : AuditPlugin pluginId)) ->
          (eventType : String) ->
          (details : String) ->
          IO ()
doAudit pluginId audit eventType details = logEvent eventType details
