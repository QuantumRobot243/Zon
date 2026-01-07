module App

import Core.Interfaces
import Core.Manager
import Core.Effects
import Config

import Effect.StdIO
import Control.Monad.Trans

%default total

-- Example of a sensitive function that *requires* a compile-time proof.
public export
deleteCriticalFile : (proof : HasCapability Delete "critical.log") -> IO ()
deleteCriticalFile proof =
  putStrLn "Proof for deleting critical.log received. Proceeding with deletion!"
  -- ... actual file deletion logic ...

public export
readUserFile : (resource : String) -> (proof : HasCapability Read resource) -> IO String
readUserFile resource proof = do
  putStrLn ("Proof for reading " ++ resource ++ " received. Reading data...")
  pure ("Content of " ++ resource)

public export
updateProjectA : (proof : HasCapability Write "project-a") -> IO ()
updateProjectA proof = do
  putStrLn "Proof for writing to project-a received. Updating..."

public export
adminOnlyAction : (proof : HasCapability AdminOp "system") -> IO ()
adminOnlyAction proof = do
  putStrLn "Proof for AdminOp 'system' received. Performing critical admin action."

public export
main : IO ()
main = do
  -- Using the console security context
  let {authNPlugin = cAuthN, authZPlugin = cAuthZ, auditPlugin = cAudit} = consoleSecurityContext
  let authNId = staticAuthPluginId
  let authZId = rbacAuthZPluginId
  let auditId = consoleAuditPluginId

  putStrLn "--- Simulating Admin Login (Static Auth, RBAC, Console Audit) ---"
  adminSessionM <- authenticateUser authNId cAuthN authZId cAuthZ auditId cAudit "admin" "password"

  case adminSessionM of
    Just adminSession => do
      putStrLn ("Admin session created for " ++ adminSession.userName ++ ", Capabilities: " ++ show adminSession.capabilities)

      case getCapabilityProof adminSession Delete "critical.log" of
        Just deleteProof => do
          deleteCriticalFile deleteProof
        Nothing =>
          putStrLn "Admin surprisingly lacks 'delete critical.log' proof. (Shouldn't happen with this setup)"

      case getCapabilityProof adminSession Read "my-docs" of
        Just readProof => do
          content <- readUserFile "my-docs" readProof
          putStrLn content
        Nothing =>
          putStrLn "Admin lacks 'read my-docs' proof. (Shouldn't happen)"

      case getCapabilityProof adminSession AdminOp "system" of
        Just adminProof =>
          adminOnlyAction adminProof
        Nothing =>
          putStrLn "Admin lacks 'admin op system' proof. (Shouldn't happen)"

    Nothing =>
      putStrLn "Admin login failed."

  putStrLn "\n--- Simulating Editor Login (Static Auth, RBAC, Console Audit) ---"
  editorSessionM <- authenticateUser authNId cAuthN authZId cAuthZ auditId cAudit "editor" "password"

  case editorSessionM of
    Just editorSession => do
      putStrLn ("Editor session created for " ++ editorSession.userName ++ ", Capabilities: " ++ show editorSession.capabilities)

      case getCapabilityProof editorSession Read "my-docs" of
        Just readProof => do
          content <- readUserFile "my-docs" readProof
          putStrLn content
        Nothing =>
          putStrLn "Editor lacks 'read my-docs' proof. This is a bug!"

      -- Editor should NOT have Delete "critical.log"
      case getCapabilityProof editorSession Delete "critical.log" of
        Just deleteProof =>
          putStrLn "ERROR: Editor got delete proof unexpectedly!"
          -- If you uncomment the next line, it will compile only if the editor *does* get the proof!
          -- deleteCriticalFile deleteProof
        Nothing =>
          putStrLn "Editor correctly lacks 'delete critical.log' proof. Cannot call deleteCriticalFile."

      case getCapabilityProof editorSession AdminOp "system" of
        Just adminProof =>
          putStrLn "ERROR: Editor got admin proof unexpectedly!"
        Nothing =>
          putStrLn "Editor correctly lacks 'admin op system' proof."
    Nothing =>
      putStrLn "Editor login failed."

  putStrLn "\n--- Simulating JWT Admin Login (JWT Auth, ABAC, File Audit) ---"
  -- Using the file security context
  let {authNPlugin = fAuthN, authZPlugin = fAuthZ, auditPlugin = fAudit} = fileSecurityContext
  let jwtAuthNId = jwtAuthPluginId
  let abacAuthZId = abacAuthZPluginId
  let fileAuditId = fileAuditPluginId

  jwtAdminSessionM <- authenticateUser jwtAuthNId fAuthN abacAuthZId fAuthZ fileAuditId fAudit "jwt-admin" "valid-jwt-token-for-admin"

  case jwtAdminSessionM of
    Just jwtAdminSession => do
      putStrLn ("JWT Admin session created for " ++ jwtAdminSession.userName ++ ", Capabilities: " ++ show jwtAdminSession.capabilities)
      case getCapabilityProof jwtAdminSession Read "all" of
        Just readAllProof => do
          content <- readUserFile "all" readAllProof
          putStrLn content
        Nothing =>
          putStrLn "JWT Admin lacks 'read all' proof. This is a bug!"

      case getCapabilityProof jwtAdminSession Write "admin-reports" of
        Just writeReportProof => do
          updateProjectA writeReportProof -- Renaming for demo, assuming general write capability
        Nothing =>
          putStrLn "JWT Admin lacks 'write admin-reports' proof. This is a bug!"

    Nothing =>
      putStrLn "JWT Admin login failed."
