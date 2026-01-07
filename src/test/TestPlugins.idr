-- src/test/TestPlugins.idr
module Test.TestPlugins -- This line has been changed to reflect the directory structure

import Core.Interfaces
import Core.Models
import Plugins.Authentication.StaticUserAuth
import Plugins.Authentication.JWTAuth
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
-- Helper for creating dummy UserSessions
--------------------------------------------------------------------------------
mkUser : String -> List String -> List RuntimeCapability -> UserSession
mkUser userId roles caps = MkUserSession userId "Test User" roles caps

--------------------------------------------------------------------------------
-- Tests for Audit Plugins
--------------------------------------------------------------------------------

testConsoleLogger : Test
testConsoleLogger = Group "Plugins.Auditing.ConsoleLogger"
  [ test "logEvent in ConsoleLogger prints to console" $ do
      -- This test primarily ensures the implementation compiles and can be called.
      -- Actual output verification would require mocking StdIO or capturing stdout.
      -- For this example, we assume observation of printed output.
      logEvent "TEST_LOG" "Console message from plugin test."
      putStrLn "(Verify 'AUDIT (Console): [TEST_LOG] Console message...' above)"
      assertBool "logEvent call completed for console audit" True
  ]

testFileLogger : Test
testFileLogger = Group "Plugins.Auditing.FileLogger"
  [ test "logEvent in FileLogger prints simulated file write message" $ do
      logEvent "FILE_AUDIT" "File message from plugin test."
      putStrLn "(Verify 'AUDIT (File): Writing to logfile.log...' above)"
      assertBool "logEvent call completed for file audit" True
  ]

--------------------------------------------------------------------------------
-- Tests for Authentication Plugins
--------------------------------------------------------------------------------

testStaticUserAuth : Test
testStaticUserAuth = Group "Plugins.Authentication.StaticUserAuth"
  [ test "Admin login successful" $ do
      sessionM <- authenticate "admin" "password"
      assertBool "Admin session should be Just" (isJust sessionM)
      case sessionM of
        Just sess => do
          assertEq sess.userId "1"
          assertEq sess.userName "Admin User"
          assertBool "Admin has AdminOp capability" (listContains (MkRuntimeCapability AdminOp "any") sess.capabilities)
          assertBool "Admin has Read all capability" (listContains (MkRuntimeCapability Read "all") sess.capabilities)
        _ => pure () -- Should not happen if isJust is true

  , test "Editor login successful" $ do
      sessionM <- authenticate "editor" "password"
      assertBool "Editor session should be Just" (isJust sessionM)
      case sessionM of
        Just sess => do
          assertEq sess.userId "2"
          assertEq sess.userName "Editor User"
          assertBool "Editor has Write my-docs capability" (listContains (MkRuntimeCapability Write "my-docs") sess.capabilities)
          assertBool "Editor does not have AdminOp capability" (not $ listContains (MkRuntimeCapability AdminOp "any") sess.capabilities)
        _ => pure ()

  , test "Failed login for invalid credentials" $ do
      sessionM <- authenticate "invalid" "user"
      assertBool "Invalid login should be Nothing" (isNothing sessionM)
  ]

testJWTAuth : Test
testJWTAuth = Group "Plugins.Authentication.JWTAuth"
  [ test "JWT User login successful" $ do
      sessionM <- authenticate "jwt-user" "valid-jwt-token-for-user"
      assertBool "JWT User session should be Just" (isJust sessionM)
      case sessionM of
        Just sess => do
          assertEq sess.userId "3"
          assertEq sess.userName "JWT User"
          assertBool "JWT User has Read project-a capability" (listContains (MkRuntimeCapability Read "project-a") sess.capabilities)
        _ => pure ()

  , test "JWT Admin login successful" $ do
      sessionM <- authenticate "jwt-admin" "valid-jwt-token-for-admin"
      assertBool "JWT Admin session should be Just" (isJust sessionM)
      case sessionM of
        Just sess => do
          assertEq sess.userId "4"
          assertEq sess.userName "JWT Admin"
          assertBool "JWT Admin has AdminOp any capability" (listContains (MkRuntimeCapability AdminOp "any") sess.capabilities)
        _ => pure ()

  , test "Failed JWT login for invalid token" $ do
      sessionM <- authenticate "jwt-user" "bad-token"
      assertBool "Invalid JWT login should be Nothing" (isNothing sessionM)
  ]

--------------------------------------------------------------------------------
-- Tests for Authorization Plugins
--------------------------------------------------------------------------------

testRBACAuthZ : Test
testRBACAuthZ = Group "Plugins.Authorization.RBAC"
  [ test "RBAC adds admin capabilities for admin role" $ do
      let initialCaps = [MkRuntimeCapability Read "some-data"]
      let session = mkUser "adminId" ["admin", "developer"] initialCaps
      authorizedSession <- authorize session
      assertBool "Session should retain initial caps" (listContains (MkRuntimeCapability Read "some-data") authorizedSession.capabilities)
      assertBool "RBAC should add Delete all-critical-data for admin" (listContains (MkRuntimeCapability Delete "all-critical-data") authorizedSession.capabilities)
      assertBool "RBAC should add AdminOp system for admin" (listContains (MkRuntimeCapability AdminOp "system") authorizedSession.capabilities)

  , test "RBAC does not add admin capabilities for non-admin role" $ do
      let initialCaps = [MkRuntimeCapability Read "some-data"]
      let session = mkUser "devId" ["developer"] initialCaps
      authorizedSession <- authorize session
      assertBool "Session should retain initial caps" (listContains (MkRuntimeCapability Read "some-data") authorizedSession.capabilities)
      assertBool "RBAC should NOT add Delete all-critical-data for non-admin" (not $ listContains (MkRuntimeCapability Delete "all-critical-data") authorizedSession.capabilities)
      assertBool "RBAC should NOT add AdminOp system for non-admin" (not $ listContains (MkRuntimeCapability AdminOp "system") authorizedSession.capabilities)
  ]

testABACAuthZ : Test
testABACAuthZ = Group "Plugins.Authorization.ABAC"
  [ test "ABAC adds capabilities for Admin User (userId '1')" $ do
      let initialCaps = [MkRuntimeCapability Read "default-data"]
      let session = mkUser "1" ["admin"] initialCaps
      authorizedSession <- authorize session
      assertBool "Session should retain initial caps" (listContains (MkRuntimeCapability Read "default-data") authorizedSession.capabilities)
      assertBool "ABAC should add Write admin-reports for userId '1'" (listContains (MkRuntimeCapability Write "admin-reports") authorizedSession.capabilities)
      assertBool "ABAC should add Delete temp-files for userId '1'" (listContains (MkRuntimeCapability Delete "temp-files") authorizedSession.capabilities)

  , test "ABAC adds capabilities for JWT User (userId '3')" $ do
      let initialCaps = [MkRuntimeCapability Write "private-repo"]
      let session = mkUser "3" ["developer"] initialCaps
      authorizedSession <- authorize session
      assertBool "Session should retain initial caps" (listContains (MkRuntimeCapability Write "private-repo") authorizedSession.capabilities)
      assertBool "ABAC should add Read public-data for userId '3'" (listContains (MkRuntimeCapability Read "public-data") authorizedSession.capabilities)

  , test "ABAC does not add capabilities for other users" $ do
      let initialCaps = [MkRuntimeCapability Read "common-data"]
      let session = mkUser "99" ["guest"] initialCaps
      authorizedSession <- authorize session
      assertBool "Session should retain initial caps" (listContains (MkRuntimeCapability Read "common-data") authorizedSession.capabilities)
      assertBool "ABAC should NOT add specific capabilities for unknown userId" (length authorizedSession.capabilities == length initialCaps)
  ]

testPlugins : Test
testPlugins = Group "Plugin Module Tests"
  [ testConsoleLogger
  , testFileLogger
  , testStaticUserAuth
  , testJWTAuth
  , testRBACAuthZ
  , testABACAuthZ
  ]

-- The `main` function for the executable will be defined in the .ipkg as:
-- main = Test.runTestTT Test.TestPlugins.testPlugins
