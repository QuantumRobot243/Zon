-- src/test/TestCore.idr
module Test.TestCore -- This line has been changed to reflect the directory structure

import Core.Interfaces
import Core.Models
import Core.Manager
import Core.Util
import Config -- To use concrete plugin instances for authenticateUser tests
import Plugins.Authentication.StaticUserAuth
import Plugins.Authorization.RBAC
import Plugins.Authorization.ABAC
import Plugins.Auditing.ConsoleLogger
import Plugins.Auditing.FileLogger

import Effect.StdIO
import Data.List
import Data.String
import Test -- Assuming idris-test is available

%default total

--------------------------------------------------------------------------------
-- Helper for creating dummy UserSessions with capabilities for proving tests
--------------------------------------------------------------------------------
mkSessionWithCaps : String -> List RuntimeCapability -> UserSession
mkSessionWithCaps userId caps = MkUserSession userId "Test User" [] caps

--------------------------------------------------------------------------------
-- Tests for Core.Util
--------------------------------------------------------------------------------

testListContains : Test
testListContains = Group "Core.Util.listContains"
  [ test "listContains returns True for existing element" $
      assertBool "1 is in [1,2,3]" (listContains 1 [1,2,3])
  , test "listContains returns False for non-existing element" $
      assertBool "4 is not in [1,2,3]" (not $ listContains 4 [1,2,3])
  , test "listContains returns False for empty list" $
      assertBool "empty list does not contain 1" (not $ listContains 1 [])
  , test "listContains works with Strings" $
      assertBool "hello is in [hello,world]" (listContains "hello" ["hello", "world"])
  ]

--------------------------------------------------------------------------------
-- Tests for Core.Interfaces (Equality Instances)
--------------------------------------------------------------------------------

testCapabilityTypeEq : Test
testCapabilityTypeEq = Group "Core.Interfaces.CapabilityType.Eq"
  [ test "CapabilityType equality (same)" $
      assertBool "Read == Read" (Read == Read)
  , test "CapabilityType equality (different)" $
      assertBool "Read != Write" (not $ Read == Write)
  ]

testRuntimeCapabilityEq : Test
testRuntimeCapabilityEq = Group "Core.Interfaces.RuntimeCapability.Eq"
  [ test "RuntimeCapability equality (same)" $
      assertBool "MkRuntimeCapability Read 'res1' == MkRuntimeCapability Read 'res1'"
        (MkRuntimeCapability Read "res1" == MkRuntimeCapability Read "res1")
  , test "RuntimeCapability equality (different capability type)" $
      assertBool "MkRuntimeCapability Read 'res1' != MkRuntimeCapability Write 'res1'"
        (not $ MkRuntimeCapability Read "res1" == MkRuntimeCapability Write "res1")
  , test "RuntimeCapability equality (different resourceId)" $
      assertBool "MkRuntimeCapability Read 'res1' != MkRuntimeCapability Read 'res2'"
        (not $ MkRuntimeCapability Read "res1" == MkRuntimeCapability Read "res2")
  ]

--------------------------------------------------------------------------------
-- Tests for Core.Manager
--------------------------------------------------------------------------------

testCheckAndProveCapability : Test
testCheckAndProveCapability = Group "Core.Manager.checkAndProveCapability"
  [ test "checkAndProveCapability returns Just for matching capability" $
      let caps = [MkRuntimeCapability Read "file1", MkRuntimeCapability Write "file2"]
          proof = checkAndProveCapability Read "file1" caps
      in assertBool "Proof found for Read file1" (isJust proof)
  , test "checkAndProveCapability returns Nothing for non-matching capability type" $
      let caps = [MkRuntimeCapability Read "file1"]
          proof = checkAndProveCapability Write "file1" caps
      in assertBool "No proof for Write file1" (isNothing proof)
  , test "checkAndProveCapability returns Nothing for non-matching resource" $
      let caps = [MkRuntimeCapability Read "file1"]
          proof = checkAndProveCapability Read "file2" caps
      in assertBool "No proof for Read file2" (isNothing proof)
  , test "checkAndProveCapability returns Nothing for empty list" $
      let proof = checkAndProveCapability Read "file1" []
      in assertBool "No proof for empty list" (isNothing proof)
  ]

testGetCapabilityProof : Test
testGetCapabilityProof = Group "Core.Manager.getCapabilityProof"
  [ test "getCapabilityProof returns Just for existing capability" $
      let caps = [MkRuntimeCapability Read "doc.txt"]
          session = mkSessionWithCaps "testId" caps
          proof = getCapabilityProof session Read "doc.txt"
      in assertBool "Proof found for Read doc.txt" (isJust proof)
  , test "getCapabilityProof returns Nothing for missing capability" $
      let caps = [MkRuntimeCapability Write "doc.txt"]
          session = mkSessionWithCaps "testId" caps
          proof = getCapabilityProof session Read "doc.txt"
      in assertBool "No proof for Read doc.txt" (isNothing proof)
  ]

testAuthenticateUser : Test
testAuthenticateUser = Group "Core.Manager.authenticateUser"
  [
    test "Admin login (StaticAuth, RBAC, ConsoleAudit) success" $ do
      let {authNPlugin = cAuthN, authZPlugin = cAuthZ, auditPlugin = cAudit} = consoleSecurityContext
      adminSessionM <- authenticateUser staticAuthPluginId cAuthN rbacAuthZPluginId cAuthZ consoleAuditPluginId cAudit "admin" "password"
      assertBool "Admin login should succeed" (isJust adminSessionM)
      case adminSessionM of
        Just sess => do
          assertEq sess.userId "1"
          assertBool "Admin has AdminOp any capability" (isJust $ getCapabilityProof sess AdminOp "any")
          assertBool "Admin has Delete all-critical-data capability from RBAC" (isJust $ getCapabilityProof sess Delete "all-critical-data")
        Nothing => pure () -- Should not happen if assertBool is True

  , test "Editor login (StaticAuth, RBAC, ConsoleAudit) success" $ do
      let {authNPlugin = cAuthN, authZPlugin = cAuthZ, auditPlugin = cAudit} = consoleSecurityContext
      editorSessionM <- authenticateUser staticAuthPluginId cAuthN rbacAuthZPluginId cAuthZ consoleAuditPluginId cAudit "editor" "password"
      assertBool "Editor login should succeed" (isJust editorSessionM)
      case editorSessionM of
        Just sess => do
          assertEq sess.userId "2"
          assertEq sess.userName "Editor User"
          assertBool "Editor has Read my-docs capability" (isJust $ getCapabilityProof sess Read "my-docs")
          assertBool "Editor does NOT have Delete all-critical-data capability" (isNothing $ getCapabilityProof sess Delete "all-critical-data")
        Nothing => pure () -- Should not happen

  , test "Failed login (StaticAuth, RBAC, ConsoleAudit) for bad credentials" $ do
      let {authNPlugin = cAuthN, authZPlugin = cAuthZ, auditPlugin = cAudit} = consoleSecurityContext
      failSessionM <- authenticateUser staticAuthPluginId cAuthN rbacAuthZPluginId cAuthZ consoleAuditPluginId cAudit "baduser" "badpass"
      assertBool "Login with bad credentials should fail" (isNothing failSessionM)

  , test "JWT Admin login (JWTAuth, ABAC, FileAudit) success" $ do
      let {authNPlugin = fAuthN, authZPlugin = fAuthZ, auditPlugin = fAudit} = fileSecurityContext
      jwtAdminSessionM <- authenticateUser jwtAuthPluginId fAuthN abacAuthZPluginId fAuthZ fileAuditPluginId fAudit "jwt-admin" "valid-jwt-token-for-admin"
      assertBool "JWT Admin login should succeed" (isJust jwtAdminSessionM)
      case jwtAdminSessionM of
        Just sess => do
          assertEq sess.userId "4"
          assertBool "JWT Admin has AdminOp any capability" (isJust $ getCapabilityProof sess AdminOp "any")
          assertBool "JWT Admin has Write admin-reports capability from ABAC" (isJust $ getCapabilityProof sess Write "admin-reports")
        Nothing => pure ()

  , test "JWT User login (JWTAuth, ABAC, FileAudit) success" $ do
      let {authNPlugin = fAuthN, authZPlugin = fAuthZ, auditPlugin = fAudit} = fileSecurityContext
      jwtUserSessionM <- authenticateUser jwtAuthPluginId fAuthN abacAuthZPluginId fAuthZ fileAuditPluginId fAudit "jwt-user" "valid-jwt-token-for-user"
      assertBool "JWT User login should succeed" (isJust jwtUserSessionM)
      case jwtUserSessionM of
        Just sess => do
          assertEq sess.userId "3"
          assertEq sess.userName "JWT User"
          assertBool "JWT User has Read project-a capability" (isJust $ getCapabilityProof sess Read "project-a")
          assertBool "JWT User has Read public-data capability from ABAC" (isJust $ getCapabilityProof sess Read "public-data")
        Nothing => pure ()

  , test "Failed JWT login (JWTAuth, ABAC, FileAudit) for bad token" $ do
      let {authNPlugin = fAuthN, authZPlugin = fAuthZ, auditPlugin = fAudit} = fileSecurityContext
      failSessionM <- authenticateUser jwtAuthPluginId fAuthN abacAuthZPluginId fAuthZ fileAuditPluginId fAudit "jwt-user" "invalid-token"
      assertBool "JWT login with bad token should fail" (isNothing failSessionM)
  ]

testDoAudit : Test
testDoAudit = Group "Core.Manager.doAudit"
  [ test "doAudit calls logEvent (Console Audit)" $ do
      let {auditPlugin = cAudit} = consoleSecurityContext
      -- doAudit itself does IO, the actual log message will be printed.
      -- We're just asserting that calling it doesn't crash and ideally produces output.
      doAudit consoleAuditPluginId cAudit "TEST_EVENT" "This is a console audit test."
      putStrLn "(Check console output for AUDIT message above.)"
      assertBool "doAudit call completed for console" True

  , test "doAudit calls logEvent (File Audit)" $ do
      let {auditPlugin = fAudit} = fileSecurityContext
      doAudit fileAuditPluginId fAudit "TEST_EVENT" "This is a file audit test."
      putStrLn "(Check console output for AUDIT (File) message above.)"
      assertBool "doAudit call completed for file" True
  ]

testCore : Test
testCore = Group "Core Module Tests"
  [ testListContains
  , testCapabilityTypeEq
  , testRuntimeCapabilityEq
  , testCheckAndProveCapability
  , testGetCapabilityProof
  , testAuthenticateUser
  , testDoAudit
  ]

-- The `main` function for the executable will be defined in the .ipkg as:
-- main = Test.runTestTT Test.TestCore.testCore
