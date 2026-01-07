module Core.Types.Session

import Core.Types.Capability
import Data.Capability.Store
import Data.SortedSet
import Data.SortedMap

%default total

public export
data SessionState = Active | Suspended | Expired | Revoked

public export
Eq SessionState where
  Active == Active = True
  Suspended == Suspended = True
  Expired == Expired = True
  Revoked == Revoked = True
  _ == _ = False

public export
Show SessionState where
  show Active = "Active"
  show Suspended = "Suspended"
  show Expired = "Expired"
  show Revoked = "Revoked"

public export
record SessionMetadata where
  constructor MkSessionMetadata
  createdAt : Integer
  lastAccessedAt : Integer
  expiresAt : Integer
  accessCount : Nat
  ipAddress : String

public export
record UserSession where
  constructor MkUserSession
  sessionId : String
  userId : String
  userName : String
  userRoles : SortedSet String
  capabilities : List Capability
  state : SessionState
  metadata : SessionMetadata

public export
Show UserSession where
  show s = "Session(" ++ s.userName ++ ", " ++
           show (length s.capabilities) ++ " caps, " ++
           show s.state ++ ")"

public export
isActive : UserSession -> Bool
isActive session = session.state == Active

public export
updateLastAccessed : Integer -> UserSession -> UserSession
updateLastAccessed time session =
  let meta = session.metadata
      newMeta = { lastAccessedAt := time, accessCount $= S } meta
  in { metadata := newMeta } session

public export
hasRole : String -> UserSession -> Bool
hasRole role session = contains role session.userRoles

public export
hasAnyRole : List String -> UserSession -> Bool
hasAnyRole roles session = any (\r => hasRole r session) roles

public export
hasAllRoles : List String -> UserSession -> Bool
hasAllRoles roles session = all (\r => hasRole r session) roles
