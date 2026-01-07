module Plugins.Authentication.EnhancedStaticAuth

import Core.Interfaces.Authentication
import Core.Types.Session
import Core.Types.Capability
import Data.SortedSet

%default total

public export
enhancedStaticAuthId : String
enhancedStaticAuthId = "enhanced-static-auth"

public export
AuthenticationProvider enhancedStaticAuthId where
  authenticate "admin" "password" = do
    let metadata = MkSessionMetadata 0 0 999999999 0 "127.0.0.1"
    let caps = [ MkCapability AdminOp Wildcard
               , MkCapability Read Wildcard
               , MkCapability Write Wildcard
               , MkCapability Delete Wildcard
               ]
    let session = MkUserSession "sess-1" "1" "Admin User"
                    (fromList ["admin", "editor"]) caps Active metadata
    pure (MkAuthResult True (Just session) "Success"
           (MkAuthContext Password 0 []))

  authenticate "editor" "password" = do
    let metadata = MkSessionMetadata 0 0 999999999 0 "127.0.0.1"
    let caps = [ MkCapability Read (Prefix "docs/")
               , MkCapability Write (Prefix "docs/")
               ]
    let session = MkUserSession "sess-2" "2" "Editor User"
                    (fromList ["editor"]) caps Active metadata
    pure (MkAuthResult True (Just session) "Success"
           (MkAuthContext Password 0 []))

  authenticate "viewer" "password" = do
    let metadata = MkSessionMetadata 0 0 999999999 0 "127.0.0.1"
    let caps = [MkCapability Read Wildcard]
    let session = MkUserSession "sess-3" "3" "Viewer User"
                    (fromList ["viewer"]) caps Active metadata
    pure (MkAuthResult True (Just session) "Success"
           (MkAuthContext Password 0 []))

  authenticate _ _ =
    pure (MkAuthResult False Nothing "Invalid credentials"
           (MkAuthContext Password 0 []))

  validateCredentials user pass = do
    result <- authenticate user pass
    pure result.success

  refreshToken sessionId = pure (Just ("refreshed-" ++ sessionId))

  revokeSession _ = pure True

public export
enhancedStaticAuthProvider : AuthenticationProvider enhancedStaticAuthId
enhancedStaticAuthProvider = %search
