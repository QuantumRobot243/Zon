module Core.Interfaces

import Data.List
import Data.String

-- 1. Capability Types: These are the "permissions" or "rights".
--    We define them as a simple sum type.
public export
data CapabilityType : Type where
  Read    : CapabilityType
  Write   : CapabilityType
  Delete  : CapabilityType
  AdminOp : CapabilityType
  -- Add more as needed

-- Provide an equality instance for CapabilityType for comparison
public export
Eq CapabilityType where
  Read == Read = True
  Write == Write = True
  Delete == Delete = True
  AdminOp == AdminOp = True
  _ == _ = False

-- A user session stores *runtime* representations of permissions.
-- This is what an AuthZ plugin would *return* after a successful check.
public export
record RuntimeCapability where
  constructor MkRuntimeCapability
  capType : CapabilityType
  resourceId : String

-- Provide an equality instance for RuntimeCapability for comparison
public export
Eq RuntimeCapability where
  MkRuntimeCapability c1 r1 == MkRuntimeCapability c2 r2 = (c1 == c2) && (r1 == r2)

-- A UserSession now holds the identified user information AND
-- a list of runtime capabilities.
public export
record UserSession where
  constructor MkUserSession
  userId : String
  userName : String
  userRoles : List String
  capabilities : List RuntimeCapability
  -- Potentially more attributes for ABAC

-- 2. Type-level proof of a capability:
--    This is the core of "proven, not checked". If you have a value of this type,
--    it means the compiler has proven you possess the capability `c` for `resource`.
--    The `resource` here is a String, but could be a more refined type.
public export
data HasCapability (c : CapabilityType) (resource : String) : Type where
  MkCapabilityProof : HasCapability c resource

-- 3. Interfaces (Type Classes) for our Plugins

-- Authentication Plugin Interface
-- It attempts to authenticate credentials and returns a UserSession if successful.
public export
interface AuthNPlugin (pluginId : String) where
  authenticate : (username : String) -> (password : String) -> IO (Maybe UserSession)

-- Authorization Plugin Interface
-- Given a UserSession, this plugin determines *which* additional runtime capabilities
-- should be part of the session. It takes an existing session and returns an updated one.
public export
interface AuthZPlugin (pluginId : String) where
  authorize : (session : UserSession) -> IO UserSession

-- Auditing Plugin Interface
public export
interface AuditPlugin (pluginId : String) where
  logEvent : (eventType : String) -> (details : String) -> IO ()
