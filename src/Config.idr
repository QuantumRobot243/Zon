module Config

import Core.Interfaces
import Core.Effects
import Plugins.Authentication.StaticUserAuth
import Plugins.Authentication.JWTAuth
import Plugins.Authorization.RBAC
import Plugins.Authorization.ABAC
import Plugins.Auditing.ConsoleLogger
import Plugins.Auditing.FileLogger

%default total

-- This module defines which concrete plugin implementations are used
-- for our "application" type contexts.

-- We define records to hold the chosen plugin instances.
-- This effectively "configures" our application's security.

-- Example: Console-auditing security configuration
public export
record ConsoleSecurityContext where
  constructor MkConsoleSecurityContext
  authNPlugin : AuthNPlugin staticAuthPluginId
  authZPlugin : AuthZPlugin rbacAuthZPluginId
  auditPlugin : AuditPlugin consoleAuditPluginId

public export
consoleSecurityContext : ConsoleSecurityContext
consoleSecurityContext = MkConsoleSecurityContext
  { authNPlugin = staticAuthPlugin
  , authZPlugin = rbacAuthZPlugin
  , auditPlugin = consoleAuditPlugin
  }

-- Example: File-auditing security configuration
public export
record FileSecurityContext where
  constructor MkFileSecurityContext
  authNPlugin : AuthNPlugin jwtAuthPluginId
  authZPlugin : AuthZPlugin abacAuthZPluginId
  auditPlugin : AuditPlugin fileAuditPluginId

public export
fileSecurityContext : FileSecurityContext
fileSecurityContext = MkFileSecurityContext
  { authNPlugin = jwtAuthPlugin
  , authZPlugin = abacAuthZPlugin
  , auditPlugin = fileAuditPlugin
  }

-- You can create more complex configurations here,
-- potentially allowing different parts of your application to use
-- different sets of plugins.
