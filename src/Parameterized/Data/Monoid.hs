{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE PolyKinds #-}

module Parameterized.Data.Monoid
    ( module Parameterized.Data.Semigroup
    , PMEmpty(..)
    , PMonoid
    ) where

import Data.Kind
import Parameterized.Data.Semigroup

-- | Parameterized version of mempty in Monoid.
class PMEmpty (n :: k -> Type) (id :: k) | n -> id where
    pmempty :: n id

-- | Parameterized version of Monoid.
type PMonoid n id t u v = (PMEmpty n id, PSemigroup n t u v)
