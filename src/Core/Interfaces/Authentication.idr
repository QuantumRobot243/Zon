module Core.Interfaces.Authentication

import Core.Types.Session
import Core.Types.Capability

%default total

public export
data AuthenticationMethod = Password | Token | Certificate | Biometric

public export
Show AuthenticationMethod where
  show Password = "Password"
  show Token = "Token"
  show Certificate = "Certificate"
  show Biometric = "Biometric"

public export
record AuthenticationContext where
  constructor MkAuthContext
  method : AuthenticationMethod
  timestamp : Integer
  metadata : List (String, String)

public export
record AuthenticationResult where
  constructor MkAuthResult
  success : Bool
  session : Maybe UserSession
  reason : String
  context : AuthenticationContext

public export
interface AuthenticationProvider (provider : String) where
  authenticate : String -> String -> IO AuthenticationResult
  validateCredentials : String -> String -> IO Bool
  refreshToken : String -> IO (Maybe String)
  revokeSession : String -> IO Bool

public export
interface MultiFactorAuth (provider : String) where
  requiresMFA : String -> IO Bool
  generateMFAChallenge : String -> IO String
  verifyMFAResponse : String -> String -> IO Bool
