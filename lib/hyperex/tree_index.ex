defmodule Hyperex.TreeIndex do
  @moduledoc """
  Tracks nodes serviing as an index for lookup and proofs
  """
  alias Hyperex.SparseBitfield
  alias Hyperex.Flattree

  @type state() :: {pos_integer, :array.array(Hyperex.Storage.Buffer), 0}

  @spec new :: state()
  def new() do
    SparseBitfield.new()
  end

  def get(state, index) do
    SparseBitfield.get(state, index)
  end

  def set(state, index) do
    idx = 2 * index

    case SparseBitfield.set(state, idx, true) do
      {s1, true} -> walk_and_set(s1, idx)
      {s1, false} -> {false, s1}
    end
  end

  defp walk_and_set(state, index) do
    sib_idx = Flattree.sibling(index)

    case SparseBitfield.get(state, sib_idx) do
      true ->
        next_idx = Flattree.parent(index)

        case SparseBitfield.set(state, next_idx, true) do
          {s1, true} -> walk_and_set(s1, next_idx)
          {s1, false} -> {false, s1}
        end

      false ->
        {false, state}
    end
  end

  def blocks(state) do
  end

  def roots(state) do
  end

  def proof(state) do
  end
end
