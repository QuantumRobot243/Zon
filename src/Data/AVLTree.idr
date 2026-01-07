module Data.AVLTree

import Data.Nat
import Decidable.Order

%default total

public export
data Ordering = LT | EQ | GT

public export
data AVLTree : (a : Type) -> Type where
  Empty : Ord a => AVLTree a
  Node : Ord a => (height : Nat) ->
         (value : a) ->
         (left : AVLTree a) ->
         (right : AVLTree a) ->
         AVLTree a

public export
height : AVLTree a -> Nat
height Empty = 0
height (Node h _ _ _) = h

public export
balanceFactor : AVLTree a -> Int
balanceFactor Empty = 0
balanceFactor (Node _ _ l r) = cast (height l) - cast (height r)

public export
rotateLeft : Ord a => AVLTree a -> AVLTree a
rotateLeft Empty = Empty
rotateLeft (Node _ x a Empty) = Node (height a + 1) x a Empty
rotateLeft (Node _ x a (Node _ y b c)) =
  Node (max (height newLeft) (height c) + 1) y newLeft c
  where
    newLeft : AVLTree a
    newLeft = Node (max (height a) (height b) + 1) x a b

public export
rotateRight : Ord a => AVLTree a -> AVLTree a
rotateRight Empty = Empty
rotateRight (Node _ y Empty b) = Node (height b + 1) y Empty b
rotateRight (Node _ y (Node _ x a b) c) =
  Node (max (height a) (height newRight) + 1) x a newRight
  where
    newRight : AVLTree a
    newRight = Node (max (height b) (height c) + 1) y b c

public export
rebalance : Ord a => AVLTree a -> AVLTree a
rebalance Empty = Empty
rebalance tree@(Node _ _ left right) =
  let bf = balanceFactor tree in
  if bf > 1 then
    if balanceFactor left < 0
      then rotateRight (Node (height tree) (value tree) (rotateLeft left) right)
      else rotateRight tree
  else if bf < -1 then
    if balanceFactor right > 0
      then rotateLeft (Node (height tree) (value tree) left (rotateRight right))
      else rotateLeft tree
  else tree
  where
    value : AVLTree a -> a
    value (Node _ v _ _) = v
    value Empty = believe_me ()

public export
insert : Ord a => a -> AVLTree a -> AVLTree a
insert x Empty = Node 1 x Empty Empty
insert x tree@(Node h y left right) =
  case compare x y of
    LT => rebalance (Node (max (height newLeft) (height right) + 1) y newLeft right)
      where newLeft = insert x left
    GT => rebalance (Node (max (height left) (height newRight) + 1) y left newRight)
      where newRight = insert x right
    EQ => tree

public export
member : Ord a => a -> AVLTree a -> Bool
member _ Empty = False
member x (Node _ y left right) =
  case compare x y of
    LT => member x left
    GT => member x right
    EQ => True
