defmodule Hyperex.Storage.RandomStorage do
  @moduledoc """
  Behaviour for all random storage implementation to follow
  """

  @doc """
  Read `length` of bytes from the given `offset`
  """
  @callback read(offset :: pos_integer(), length :: pos_integer()) ::
              binary() | {:error, :not_found}

  @doc """
  Write `data` at the given offset
  """
  @callback write(offset :: pos_integer(), data :: binary()) :: none()
end
