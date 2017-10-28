{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

module Parameterized.Control.Monad.Trans.State.Strict where

import Control.Applicative
import Control.Monad
import qualified Control.Monad.Fail as Fail
import Control.Monad.Fix
import Control.Monad.IO.Class
import Control.Monad.Trans.State.Strict
import Data.Diverse
import qualified GHC.Generics as G
import Parameterized.Control.Monad

newtype ManyState m s a = ManyState
    { runManyState :: StateT s m a
    } deriving ( G.Generic
               , Functor
               , Applicative
               , Monad
               , Alternative
               , MonadPlus
               , MonadFix
               , Fail.MonadFail
               , MonadIO
               )

type instance PId (ManyState m) = Many '[]

instance Monad m => PPointed (ManyState m) where
    ppure = ManyState . pure

-- | Given a ManyState that modifies @Many a@, and another ManyState that modifes @Many b@
-- make a State that accepts @Many (AppendUnique a b)@
-- with the compile time constraint that all the types in (AppendUnique a b) are distinct.
instance ( Monad m
         , Select a c
         , Select b c
         , Amend a c
         , Amend b c
         , c ~ AppendUnique a b
         ) =>
         PApplicative (ManyState m) (Many a) (Many b) (Many c) where
    papply (ManyState (StateT x)) (ManyState (StateT y)) =
        ManyState . StateT $ \c -> do
             (f, a) <- x (select c)
             let c' = amend c a
             (r, b) <- y (select c')
             let c'' = amend c' b
             pure (f r, c'')

instance Alternative m => PEmpty (ManyState m) where
    pempty = ManyState $ StateT $ \_ -> empty

instance ( Monad m
         , Alternative m
         , Select a c
         , Select b c
         , Amend a c
         , Amend b c
         , c ~ AppendUnique a b
         ) =>
         PAlternative (ManyState m) (Many a) (Many b) (Many c) where
    pappend (ManyState (StateT x)) (ManyState (StateT y)) =
        ManyState . StateT $ \c -> x' c <|> y' c
      where
        x' c = do
            (r, a) <- x (select c)
            pure (r, amend c a)
        y' c = do
            (r, b) <- y (select c)
            pure (r, amend c b)

instance ( Monad m
         , Select a c
         , Select b c
         , Amend a c
         , Amend b c
         , c ~ AppendUnique a b
         ) =>
         PMonad (ManyState m) (Many a) (Many b) (Many c) where
    pbind (ManyState (StateT x)) k =
        ManyState . StateT $ \c -> do
             (r, a) <- x (select c)
             let c' = amend c a
                 ManyState (StateT y) = k r
             (r', b) <- y (select c')
             let c'' = amend c' b
             pure (r', c'')

-- --------------------------------------------

-- newtype ChangingState m st a = ChangingState
--     { runChangingState :: At0 st -> m (a, At1 st)
--     } deriving ( G.Generic)

-- instance Functor m => Functor (ChangingState m st) where
--     fmap f m = ChangingState $ \s ->
--         fmap (\(a, s') -> (f a, s')) $ runChangingState m s

-- type instance PId (ManyState m) = forall s. s

-- instance Applicative m => PPointed (ChangingState m) where
--     ppure a = ChangingState $ \s -> pure (a, s)

-- -- | Given a ChangingState that changes state from @s@ to @t@,
-- -- and another ChangingState that changes state from @t@ to @u@
-- -- make a State that changes from @s@ to @u@
-- -- with the compile time constraint that all the types in (AppendUnique a b) are distinct.
-- instance Applicative m => PApplicative (ManyState m) (s, t) (t, u) (s, u) where
--     papply (ManyState x) (ManyState y) =
--         ManyState $ \s -> do
--              (f, t) <- x s
--              (r, u) <- y t
--              pure (f r, u)