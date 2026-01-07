module App.SecurityOperations

import Core.Types.Session
import Core.Types.Capability
import Core.Interfaces.Authentication
import Core.Interfaces.Authorization
import Core.Interfaces.Auditing
import Core.Manager.CapabilityManager
import Data.SortedMap

%default total

export
performAuthentication :
  {authNId : String} -> {authZId : String} -> {auditId : String} ->
  (AuthenticationProvider authNId) =>
  (AuthorizationProvider authZId) =>
  (AuditProvider auditId) =>
  String -> String -> IO (Maybe UserSession)
performAuthentication username password = do
  logEvent (MkAuditEvent (username ++ "-auth-attempt") AuthenticationAttempt 0 username "" ""
             empty 1)
  result <- authenticate username password
  case result.session of
    Just session => do
      logEvent (MkAuditEvent (session.sessionId ++ "-auth-success") AuthenticationSuccess 0
                 session.userId session.sessionId "" empty 1)
      authorizedSession <- authorize session
      logEvent (MkAuditEvent (authorizedSession.sessionId ++ "-authz-check") AuthorizationCheck 0
                 authorizedSession.userId authorizedSession.sessionId ""
                 empty 1)
      pure (Just authorizedSession)
    Nothing => do
      logEvent (MkAuditEvent (username ++ "-auth-failure") AuthenticationFailure 0 username "" ""
                 empty 2)
      pure Nothing

export
executeWithCapability :
  {auditId : String} ->
  (AuditProvider auditId) =>
  UserSession ->
  CapabilityType ->
  String ->
  (HasCapability c r -> IO ()) ->
  IO ()
executeWithCapability session capType resource action = do
  let reqCap = MkCapability capType (Exact resource)
  case checkCapability session capType resource of
    Yes proof => do
      logEvent (MkAuditEvent (session.sessionId ++ "-" ++ show capType ++ "-" ++ resource ++ "-granted") AuthorizationGranted 0
                 session.userId session.sessionId resource empty 1)
      action proof
      logEvent (MkAuditEvent (session.sessionId ++ "-" ++ show capType ++ "-" ++ resource ++ "-performed") ResourceAccess 0
                 session.userId session.sessionId resource empty 1)
    No _ => do
      logEvent (MkAuditEvent (session.sessionId ++ "-" ++ show capType ++ "-" ++ resource ++ "-denied") AuthorizationDenied 0
                 session.userId session.sessionId resource empty 2)
      putStrLn ("Access denied: " ++ show capType ++ " on " ++ resource)

export
deleteCriticalFile : HasCapability Delete "critical.log" -> IO ()
deleteCriticalFile _ = putStrLn "Successfully deleted critical.log"

export
readDocument : (resource : String) -> HasCapability Read resource -> IO String
readDocument resource _ = do
  putStrLn ("Reading document: " ++ resource)
  pure ("Content of " ++ resource)

export
writeDocument : (resource : String) -> HasCapability Write resource -> IO ()
writeDocument resource _ = putStrLn ("Writing to document: " ++ resource)

export
executeScript : HasCapability Execute "scripts/deploy.sh" -> IO ()
executeScript _ = putStrLn "Executing deployment script"

export
performAdminOperation : HasCapability AdminOp "system" -> IO ()
performAdminOperation _ = putStrLn "Performing critical system administration"
