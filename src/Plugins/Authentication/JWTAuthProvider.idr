module Plugins.Authentication.JWTAuthProvider

import Core.Interfaces.Authentication
import Core.Types.Session
import Core.Types.Capability
import Data.SortedSet
import Data.String

%default total

public export
jwtAuthProviderId : String
jwtAuthProviderId = "jwt-auth-provider"

private
validateJWT : String -> Bool
validateJWT token = isPrefixOf "valid-jwt-token" token

private
extractUsername : String -> String
extractUsername token =
  if token == "valid-jwt-token-admin" then "jwt-admin"
  else if token == "valid-jwt-token-user" then "jwt-user"
  else "unknown"

public export
AuthenticationProvider jwtAuthProviderId where
  authenticate username token = do
    if validateJWT token
      then do
        let metadata = MkSessionMetadata 0 0 999999999 0 "127.0.0.1"
        let (userId, roles, caps) =
          if username == "jwt-admin"
            then ("4", fromList ["admin", "developer"],
                  [ MkCapability Read Wildcard
                  , MkCapability Write Wildcard
                  , MkCapability AdminOp Wildcard
                  ])
            else ("5", fromList ["developer"],
                  [ MkCapability Read (Prefix "project-")
                  , MkCapability Write (Prefix "project-")
                  ])
        let session = MkUserSession ("jwt-sess-" ++ userId) userId username
                        roles caps Active metadata
        pure (MkAuthResult True (Just session) "JWT validated"
               (MkAuthContext Token 0 [("token", token)]))
      else pure (MkAuthResult False Nothing "Invalid JWT"
                  (MkAuthContext Token 0 [("token", token)]))

  validateCredentials username token = do
    result <- authenticate username token
    pure result.success

  refreshToken oldToken =
    if validateJWT oldToken
      then pure (Just ("refreshed-" ++ oldToken))
      else pure Nothing

  revokeSession _ = pure True

public export
jwtAuthProvider : AuthenticationProvider jwtAuthProviderId
jwtAuthProvider = %search
