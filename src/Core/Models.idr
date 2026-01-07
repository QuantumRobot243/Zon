module Core.Models

import Core.Interfaces

-- Re-exporting for convenience, using public export for top-level types.
public export
data HasCapability = Core.Interfaces.HasCapability
public export
record RuntimeCapability = Core.Interfaces.MkRuntimeCapability
public export
record UserSession = Core.Interfaces.MkUserSession
public export
data CapabilityType = Core.Interfaces.Read | Core.Interfaces.Write | Core.Interfaces.Delete | Core.Interfaces.AdminOp
