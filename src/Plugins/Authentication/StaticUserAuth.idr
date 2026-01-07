module Plugins.Authentication.StaticUserAuth

import Core.Interfaces
import Core.Effects
import Effect.StdIO

%default total

public export
staticAuthPluginId : String
staticAuthPluginId = "static-user-auth"

implementation AuthNPlugin staticAuthPluginId where
  authenticate "admin" "password" = pure . Just $ MkUserSession "1" "Admin User" ["admin", "editor"]
                                       [ MkRuntimeCapability AdminOp "any",
                                         MkRuntimeCapability Read "all",
                                         MkRuntimeCapability Write "all",
                                         MkRuntimeCapability Delete "all"]
  authenticate "editor" "password" = pure . Just $ MkUserSession "2" "Editor User" ["editor"]
                                       [ MkRuntimeCapability Read "my-docs",
                                         MkRuntimeCapability Write "my-docs"]
  authenticate _ _ = pure Nothing
