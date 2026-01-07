module Config.SecurityContexts

import Core.Types.Session
import Core.Interfaces.Authentication
import Core.Interfaces.Authorization
import Core.Interfaces.Auditing
import Plugins.Authentication.EnhancedStaticAuth
import Plugins.Authentication.JWTAuthProvider
import Plugins.Authorization.EnhancedRBAC
import Plugins.Authorization.EnhancedABAC
import Plugins.Auditing.StructuredLogger
import Plugins.Auditing.FileAuditLogger

%default total

public export
record SecurityContext (authNId : String) (authZId : String) (auditId : String) where
  constructor MkSecurityContext
  authNProvider : AuthenticationProvider authNId
  authZProvider : AuthorizationProvider authZId
  auditProvider : AuditProvider auditId

public export
defaultSecurityContext : SecurityContext enhancedStaticAuthId enhancedRBACId
                                        structuredLoggerId
defaultSecurityContext = MkSecurityContext %search %search %search

public export
jwtSecurityContext : SecurityContext jwtAuthProviderId enhancedABACId
                                    fileAuditLoggerId
jwtSecurityContext = MkSecurityContext %search %search %search

public export
highSecurityContext : SecurityContext jwtAuthProviderId enhancedRBACId
                                     structuredLoggerId
highSecurityContext = MkSecurityContext %search %search %search
