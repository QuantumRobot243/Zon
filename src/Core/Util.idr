module Core.Util

import Data.List
import Data.String

%default total

-- Utility for checking if an item exists in a list
-- (Can use `elem` from Data.List if types have `Eq` instance)
public export
listContains : Eq a => a -> List a -> Bool
listContains _ [] = False
listContains x (y :: ys) = (x == y) || listContains x ys
