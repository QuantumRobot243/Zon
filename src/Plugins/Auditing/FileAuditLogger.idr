module Plugins.Auditing.FileAuditLogger

import Core.Interfaces.Auditing
import Data.SortedMap

%default total

public export
fileAuditLoggerId : String
fileAuditLoggerId = "file-audit-logger"

private
formatEventForFile : AuditEvent -> String
formatEventForFile event =
  show event.timestamp ++ "," ++
  show event.eventType ++ "," ++
  event.userId ++ "," ++
  event.sessionId ++ "," ++
  event.resourceId ++ "," ++
  show event.severity

public export
AuditProvider fileAuditLoggerId where
  logEvent event =
    putStrLn ("AUDIT (File): Writing to audit.log: " ++
              formatEventForFile event)

  queryEvents eventType startTime endTime = do
    putStrLn ("File query: events of type " ++ show eventType)
    pure []

  getEventsByUser userId startTime endTime = do
    putStrLn ("File query: events for user " ++ userId)
    pure []

  getEventsByResource resource startTime endTime = do
    putStrLn ("File query: events for resource " ++ resource)
    pure []

public export
fileAuditLoggerProvider : AuditProvider fileAuditLoggerId
fileAuditLoggerProvider = %search
