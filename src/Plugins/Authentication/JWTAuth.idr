module Plugins.Authentication.JWTAuth

import Core.Interfaces
import Core.Models
import Core.Effects
import Effect.StdIO

%default total

jwtAuthPluginId : String
jwtAuthPluginId = "jwt-authentication"

-- In a real scenario, this would parse and validate a JWT token
-- and extract user information and claims (capabilities).
-- For this example, it's a simplified stub.
implementation AuthNPlugin jwtAuthPluginId where
  authenticate "jwt-user" token =
    if token == "valid-jwt-token-for-user"
      then do
        -- Imagine parsing claims from the JWT to build capabilities
        let capabilities = [MkRuntimeCapability Read "project-a", MkRuntimeCapability Write "project-a"]
        pure . Just $ MkUserSession "3" "JWT User" ["developer"] capabilities
      else do
        putStrLn "Invalid JWT token."
        pure Nothing

  authenticate "jwt-admin" token =
    if token == "valid-jwt-token-for-admin"
      then do
        let capabilities = [MkRuntimeCapability Read "all", MkRuntimeCapability Write "all", MkRuntimeCapability AdminOp "any"]
        pure . Just $ MkUserSession "4" "JWT Admin" ["admin", "developer"] capabilities
      else do
        putStrLn "Invalid JWT token for admin."
        pure Nothing

  authenticate _ _ = pure Nothing
