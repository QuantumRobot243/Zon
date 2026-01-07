module Plugins.Auditing.ConsoleLogger

import Core.Interfaces
import Effect.StdIO
import Data.String

%default total

public export
consoleAuditPluginId : String
consoleAuditPluginId = "console-logger"

implementation AuditPlugin consoleAuditPluginId where
  logEvent eventType details =
    putStrLn ("AUDIT (Console): [" ++ eventType ++ "] " ++ details)
