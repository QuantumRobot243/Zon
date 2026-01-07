module Core.Interfaces.Auditing

import Core.Types.Session
import Core.Types.Capability
import Data.SortedMap

%default total

public export
data AuditEventType =
  AuthenticationAttempt | AuthenticationSuccess | AuthenticationFailure |
  AuthorizationCheck | AuthorizationGranted | AuthorizationDenied |
  ResourceAccess | ResourceModification | ResourceDeletion |
  PolicyViolation | SecurityAlert | SessionCreated | SessionExpired

public export
Show AuditEventType where
  show AuthenticationAttempt = "AUTH_ATTEMPT"
  show AuthenticationSuccess = "AUTH_SUCCESS"
  show AuthenticationFailure = "AUTH_FAILURE"
  show AuthorizationCheck = "AUTHZ_CHECK"
  show AuthorizationGranted = "AUTHZ_GRANTED"
  show AuthorizationDenied = "AUTHZ_DENIED"
  show ResourceAccess = "RESOURCE_ACCESS"
  show ResourceModification = "RESOURCE_MODIFICATION"
  show ResourceDeletion = "RESOURCE_DELETION"
  show PolicyViolation = "POLICY_VIOLATION"
  show SecurityAlert = "SECURITY_ALERT"
  show SessionCreated = "SESSION_CREATED"
  show SessionExpired = "SESSION_EXPIRED"

public export
record AuditEvent where
  constructor MkAuditEvent
  eventId : String
  eventType : AuditEventType
  timestamp : Integer
  userId : String
  sessionId : String
  resourceId : String
  details : SortedMap String String
  severity : Nat

public export
interface AuditProvider (provider : String) where
  logEvent : AuditEvent -> IO ()
  queryEvents : AuditEventType -> Integer -> Integer -> IO (List AuditEvent)
  getEventsByUser : String -> Integer -> Integer -> IO (List AuditEvent)
  getEventsByResource : String -> Integer -> Integer -> IO (List AuditEvent)

public export
interface ComplianceReporting where
  generateReport : Integer -> Integer -> IO String
  checkCompliance : List Policy -> IO Bool
  exportAuditLog : Integer -> Integer -> IO String
