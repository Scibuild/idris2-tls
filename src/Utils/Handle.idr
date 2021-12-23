module Utils.Handle

import Data.Vect
import Data.Nat
import Control.Monad.Error.Either
import Control.Linear.LIO

public export
ReadHack : (t_ok : Type) -> (t_read_failed : Type) -> Bool -> Type
ReadHack t_ok t_read_failed False = t_read_failed
ReadHack t_ok t_read_failed True = Res (List Bits8) (const t_ok)

public export
WriteHack : (t_ok : Type) -> (t_write_failed : Type) -> Bool -> Type
WriteHack t_ok t_write_failed False = t_write_failed
WriteHack t_ok t_write_failed True = t_ok

public export
record Handle (t_ok : Type) (t_closed : Type) (t_read_failed : Type) (t_write_failed : Type) where
  constructor MkHandle
  1 underlying : t_ok
  do_read : forall m. LinearIO m => (1 _ : t_ok) -> (len : Nat) -> L1 m $ Res Bool $ ReadHack t_ok t_read_failed
  do_write : forall m. LinearIO m => (1 _ : t_ok) -> List Bits8 -> L1 m $ Res Bool $ WriteHack t_ok t_write_failed
  do_close : forall m. LinearIO m => (1 _ : t_ok) -> L1 m t_closed

public export
close : LinearIO m => (1 _ : Handle t_ok t_closed t_read_failed t_write_failed) -> L1 m t_closed
close (MkHandle x do_read do_write do_close) = do_close x

public export
read : LinearIO m => (1 _ : Handle t_ok t_closed t_read_failed t_write_failed) -> (len : Nat) -> L1 m $ Res Bool $ \case
  False => t_read_failed
  True => Res (List Bits8) (\_ => Handle t_ok t_closed t_read_failed t_write_failed)
read (MkHandle x do_read do_write do_close) len = do
  (True # (output # x)) <- do_read x len
  | (False # x) => pure1 $ False # x
  pure1 $ True # (output # MkHandle x do_read do_write do_close)

public export
write : LinearIO m => (1 _ : Handle t_ok t_closed t_read_failed t_write_failed) -> (input : List Bits8) -> L1 m $ Res Bool $ \case
  False => t_write_failed
  True => Handle t_ok t_closed t_read_failed t_write_failed
write (MkHandle x do_read do_write do_close) input = do
  (True # x) <- do_write x input
  | (False # x) => pure1 $ False # x
  pure1 $ True # MkHandle x do_read do_write do_close

{-
socket_to_handle : (1 _ : Socket Open) -> Handle (Socket Open) (Socket Closed) (Res SocketError $ \_ => Socket Closed) (Res Nat $ \_ => Socket Closed)
socket_to_handle sock = MkHandle
  sock
  ( \sock, len => do
      (Right (result, _) # sock) <- recv sock len
      | (Left err # sock) => pure1 $ False # (err # sock)
      pure1 $ True # ([{- result, fuck Network.recv -}] # sock)
  )
  ( \sock, input => do
      (Nothing # sock) <- send sock (?fuck_Network_send input)
      | (Just err # sock) => pure1 $ False # (err # sock)
      pure1 $ True # sock
  )
  close
-}
