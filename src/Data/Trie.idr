module Data.Trie

import Data.List
import Data.SortedMap

%default total

public export
data Trie : Type -> Type where
  MkTrie : (isEnd : Bool) ->
           (children : SortedMap Char (Trie a)) ->
           (value : Maybe a) ->
           Trie a

public export
empty : Trie a
empty = MkTrie False empty Nothing

public export
insert : String -> a -> Trie a -> Trie a
insert str val trie = insertHelper (unpack str) val trie
  where
    insertHelper : List Char -> a -> Trie a -> Trie a
    insertHelper [] val (MkTrie _ children _) =
      MkTrie True children (Just val)
    insertHelper (c :: cs) val (MkTrie isEnd children oldVal) =
      let child = fromMaybe empty (lookup c children)
          newChild = insertHelper cs val child
          newChildren = insert c newChild children
      in MkTrie isEnd newChildren oldVal

public export
lookup : String -> Trie a -> Maybe a
lookup str trie = lookupHelper (unpack str) trie
  where
    lookupHelper : List Char -> Trie a -> Maybe a
    lookupHelper [] (MkTrie _ _ val) = val
    lookupHelper (c :: cs) (MkTrie _ children _) =
      case lookup c children of
        Just child => lookupHelper cs child
        Nothing => Nothing

public export
prefixMatch : String -> Trie a -> List (String, a)
prefixMatch prefix trie =
  case findNode (unpack prefix) trie of
    Just node => collectAll prefix node
    Nothing => []
  where
    findNode : List Char -> Trie a -> Maybe (Trie a)
    findNode [] t = Just t
    findNode (c :: cs) (MkTrie _ children _) =
      lookup c children >>= findNode cs

    collectAll : String -> Trie a -> List (String, a)
    collectAll path (MkTrie isEnd children val) =
      let current = case val of
            Just v => [(path, v)]
            Nothing => []
          childResults = concat $ map (\(c, child) =>
            collectAll (path ++ cast c) child) (toList children)
      in current ++ childResults
