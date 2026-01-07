module Core.Util

import Data.List
import Data.String

%default total

public export
listContains : Eq a => a -> List a -> Bool
listContains _ [] = False
listContains x (y :: ys) = (x == y) || listContains x ys
