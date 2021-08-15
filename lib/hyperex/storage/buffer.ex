defmodule Hyperex.Storage.Buffer do
  @moduledoc """
  Mutable,sized byte array
  """
  use Bitwise

  defstruct data: {}, size: 0

  @type state() :: %{data: tuple(), size: pos_integer()}

  @spec new(pagesize :: integer | none()) ::
          {:error, :bad_pagesize}
          | state()
  def new(pagesize \\ 1024) do
    case power_of_two(pagesize) do
      true ->
        buf = init_memory(pagesize)
        {:ok, %__MODULE__{data: buf, size: pagesize}}

      _ ->
        {:error, :bad_pagesize}
    end
  end

  @spec write(state(), offset :: pos_integer(), bits :: bitstring) :: state()
  def write(memory, offset, bits) do
    bytes = for <<byte::8 <- bits>>, do: <<byte>>

    # TODO: Need to check, not trying to overflow pagesize?
    # Or is memory pager handling this?
    # offset + length(bytes) > pagesize

    mem =
      bytes
      |> Enum.with_index()
      |> Enum.reduce(memory.data, fn {byte, idx}, acc ->
        put_elem(acc, offset + idx, byte)
      end)

    Map.put(memory, :data, mem)
  end

  @spec read(state(), offset :: pos_integer, size :: pos_integer) :: bitstring
  def read(memory, offset, size) do
    for i <- offset..(offset + (size - 1)), into: <<>>, do: elem(memory.data, i)
  end

  @spec delete(state(), offset :: pos_integer, length :: pos_integer) :: state()
  def delete(memory, offset, length) do
    write(memory, offset, <<0::integer-(length * 8)>>)
  end

  @spec size(state()) :: pos_integer()
  def size(memory) do
    memory.size
  end

  defp init_memory(pagesize) do
    <<0>>
    |> List.duplicate(pagesize)
    |> List.to_tuple()
  end

  defp power_of_two(value) do
    case Bitwise.band(value, 1) do
      0 -> true
      _ -> false
    end
  end
end
