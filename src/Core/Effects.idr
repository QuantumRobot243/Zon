module Core.Effects

import Effect
import Effect.StdIO

%default total

-- Define an effect for auditing.
-- This allows us to separate auditing logic from the core business logic.
data AUDIT : Effect where
  LogEvent : String -> String -> AUDIT (IO ())

-- Map the AUDIT effect to an AuditPlugin implementation.
-- This is how our 'AuditPlugin' becomes an 'effect handler'.
public export
handleAudit : (pluginId : String) ->
              (AuditPlugin pluginId `with` (audit : AuditPlugin pluginId)) ->
              Handler AUDIT IO
handleAudit pluginId audit =
  { handle = \eff =>
      case eff of
        LogEvent eventType details => logEvent eventType details
  }

-- A convenience function to perform an audit event in any effect context
-- that includes the AUDIT effect.
auditLog : HasFC a AUDIT => String -> String -> Eff a ()
auditLog eventType details = call (LogEvent eventType details)
