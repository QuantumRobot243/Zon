module App.Main

import App.SecurityOperations
import Config.SecurityContexts
import Core.Types.Capability
import Plugins.Authentication.EnhancedStaticAuth
import Plugins.Authentication.JWTAuthProvider
import Plugins.Authorization.EnhancedRBAC
import Plugins.Authorization.EnhancedABAC
import Plugins.Auditing.StructuredLogger
import Plugins.Auditing.FileAuditLogger

%default total

runUserScenario :
  {authNId : String} -> {authZId : String} -> {auditId : String} ->
  (AuthenticationProvider authNId) =>
  (AuthorizationProvider authZId) =>
  (AuditProvider auditId) =>
  String -> String -> String -> IO ()
runUserScenario username password scenarioName = do
  putStrLn ("\n=== " ++ scenarioName ++ " ===")
  sessionM <- performAuthentication username password
  case sessionM of
    Just session => do
      putStrLn ("Session created: " ++ show session)
      putStrLn ("Capabilities: " ++ show session.capabilities)

      executeWithCapability session Delete "critical-data" deleteCriticalFile
      executeWithCapability session Read "docs/readme.md"
        (\proof => do
          content <- readDocument "docs/readme.md" proof
          putStrLn content)
      executeWithCapability session Write "docs/report.txt"
        (writeDocument "docs/report.txt")
      executeWithCapability session Execute "scripts/deploy.sh" executeScript
      executeWithCapability session AdminOp "system" performAdminOperation
      executeWithCapability session Read "project-X/src/main.idr"
        (\proof => do
          content <- readDocument "project-X/src/main.idr" proof
          putStrLn content)
      executeWithCapability session Write "project-Y/config.toml"
        (writeDocument "project-Y/config.toml")

    Nothing => putStrLn "Authentication failed"

export
main : IO ()
main = do
  putStrLn "╔══════════════════════════════════════════════╗"
  putStrLn "║  Advanced Security Framework Demonstration  ║"
  putStrLn "╚══════════════════════════════════════════════╝"

  runUserScenario @{enhancedStaticAuthProvider}
                  @{enhancedRBACProvider}
                  @{structuredLoggerProvider}
                  "admin" "password"
                  "Admin with Enhanced Static Auth + RBAC + Structured Logging"

  runUserScenario @{enhancedStaticAuthProvider}
                  @{enhancedRBACProvider}
                  @{structuredLoggerProvider}
                  "editor" "password"
                  "Editor with Enhanced Static Auth + RBAC + Structured Logging"

  runUserScenario @{enhancedStaticAuthProvider}
                  @{enhancedRBACProvider}
                  @{structuredLoggerProvider}
                  "viewer" "password"
                  "Viewer with Enhanced Static Auth + RBAC + Structured Logging"

  runUserScenario @{jwtAuthProvider}
                  @{enhancedABACProvider}
                  @{fileAuditLoggerProvider}
                  "jwt-admin" "valid-jwt-token-admin"
                  "JWT Admin with JWT Auth + ABAC + File Logging"

  runUserScenario @{jwtAuthProvider}
                  @{enhancedABACProvider}
                  @{fileAuditLoggerProvider}
                  "jwt-user" "valid-jwt-token-user"
                  "JWT User with JWT Auth + ABAC + File Logging"

  putStrLn "\n╔══════════════════════════════════════════════╗"
  putStrLn "║         All Scenarios Completed              ║"
  putStrLn "╚══════════════════════════════════════════════╝"
