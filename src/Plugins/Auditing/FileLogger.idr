module Plugins.Auditing.FileLogger

import Core.Interfaces
import Effect.StdIO
import Data.String

%default total

public export
fileAuditPluginId : String
fileAuditPluginId = "file-logger"

implementation AuditPlugin fileAuditPluginId where
  logEvent eventType details =
    putStrLn ("AUDIT (File): Writing to logfile.log: [" ++ eventType ++ "] " ++ details)
    -- In a real app, this would use a file handle and actually write to a file.
    -- (e.g., using System.File or System.IO from the effect package)
