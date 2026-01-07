module Core.Manager.PolicyManager

import Core.Types.Policy
import Core.Types.Capability
import Data.SortedMap
import Data.SortedSet
import Data.IORef
import Data.List

%default total

public export
record PolicyManager where
  constructor MkPolicyManager
  policies : IORef (SortedMap String Policy)
  userPolicies : IORef (SortedMap String (SortedSet String))
  rolePolicies : IORef (SortedMap String (SortedSet String))

public export
createPolicyManager : IO PolicyManager
createPolicyManager = do
  policiesRef <- newIORef empty
  userPoliciesRef <- newIORef empty
  rolePoliciesRef <- newIORef empty
  pure (MkPolicyManager policiesRef userPoliciesRef rolePoliciesRef)

public export
addPolicy : PolicyManager -> Policy -> IO ()
addPolicy manager policy = do
  policies <- readIORef manager.policies
  writeIORef manager.policies (insert policy.policyId policy policies)

public export
getPolicy : PolicyManager -> String -> IO (Maybe Policy)
getPolicy manager policyId = do
  policies <- readIORef manager.policies
  pure (lookup policyId policies)

public export
attachPolicyToUser : PolicyManager -> String -> String -> IO ()
attachPolicyToUser manager userId policyId = do
  userPolicies <- readIORef manager.userPolicies
  let currentPolicies = fromMaybe empty (lookup userId userPolicies)
  let updatedPolicies = insert policyId currentPolicies
  writeIORef manager.userPolicies (insert userId updatedPolicies userPolicies)

public export
attachPolicyToRole : PolicyManager -> String -> String -> IO ()
attachPolicyToRole manager roleId policyId = do
  rolePolicies <- readIORef manager.rolePolicies
  let currentPolicies = fromMaybe empty (lookup roleId rolePolicies)
  let updatedPolicies = insert policyId currentPolicies
  writeIORef manager.rolePolicies (insert roleId updatedPolicies rolePolicies)

public export
getUserPolicies : PolicyManager -> String -> IO (List Policy)
getUserPolicies manager userId = do
  policies <- readIORef manager.policies
  userPolicies <- readIORef manager.userPolicies
  case lookup userId userPolicies of
    Just policyIds =>
      pure (mapMaybe (\pid => lookup pid policies) (SortedSet.toList policyIds))
    Nothing => pure []

public export
getRolePolicies : PolicyManager -> String -> IO (List Policy)
getRolePolicies manager roleId = do
  policies <- readIORef manager.policies
  rolePolicies <- readIORef manager.rolePolicies
  case lookup roleId rolePolicies of
    Just policyIds =>
      pure (mapMaybe (\pid => lookup pid policies) (SortedSet.toList policyIds))
    Nothing => pure []

public export
evaluateAccess : PolicyManager ->
                String ->
                List String ->
                CapabilityType ->
                String ->
                SortedMap String String ->
                IO (Maybe PolicyEffect)
evaluateAccess manager userId roles capType resource context = do
  userPolicies <- getUserPolicies manager userId
  rolePolicies <- concat <$> traverse (getRolePolicies manager) roles
  let allPolicies = sortBy compare (userPolicies ++ rolePolicies)
  let results = mapMaybe (\p => evaluatePolicy p capType resource context) allPolicies
  pure (head' results)
