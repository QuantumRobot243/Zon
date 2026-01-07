module Core.Manager.SessionManager

import Core.Types.Session
import Core.Types.Capability
import Data.SortedMap
import Data.IORef
import Data.List

%default total

public export
record SessionManager where
  constructor MkSessionManager
  sessions : IORef (SortedMap String UserSession)
  activeCount : IORef Nat

public export
createSessionManager : IO SessionManager
createSessionManager = do
  sessionsRef <- newIORef empty
  countRef <- newIORef 0
  pure (MkSessionManager sessionsRef countRef)

public export
addSession : SessionManager -> UserSession -> IO ()
addSession manager session = do
  sessions <- readIORef manager.sessions
  writeIORef manager.sessions (insert session.sessionId session sessions)
  modifyIORef manager.activeCount S

public export
getSession : SessionManager -> String -> IO (Maybe UserSession)
getSession manager sessionId = do
  sessions <- readIORef manager.sessions
  pure (lookup sessionId sessions)

public export
updateSession : SessionManager -> String -> UserSession -> IO Bool
updateSession manager sessionId session = do
  sessions <- readIORef manager.sessions
  case lookup sessionId sessions of
    Just _ => do
      writeIORef manager.sessions (insert sessionId session sessions)
      pure True
    Nothing => pure False

public export
removeSession : SessionManager -> String -> IO Bool
removeSession manager sessionId = do
  sessions <- readIORef manager.sessions
  case lookup sessionId sessions of
    Just _ => do
      writeIORef manager.sessions (delete sessionId sessions)
      modifyIORef manager.activeCount (finite_pred 1)
      pure True
    Nothing => pure False

public export
getActiveSessions : SessionManager -> IO (List UserSession)
getActiveSessions manager = do
  sessions <- readIORef manager.sessions
  pure (filter isActive (values sessions))

public export
expireSessions : SessionManager -> Integer -> IO Nat
expireSessions manager currentTime = do
  sessions <- readIORef manager.sessions
  let (expired, active) = partition (\s => s.metadata.expiresAt < currentTime) (toList sessions)
  let updatedSessions = fromList (map (\(k, v) => (k, { state := Expired } v)) expired) `union` fromList active
  writeIORef manager.sessions updatedSessions
  let expiredCount = length expired
  modifyIORef manager.activeCount (\c => believe_me (drop expiredCount c))
  pure (cast expiredCount)
