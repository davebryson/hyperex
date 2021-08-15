defmodule Hyperex.SparseBitfield do
  @moduledoc """
  Space efficent structure to track pieces of information.

  Each piece of information added to a Dat feed relates to an incrementing `index`:

  ```text
  first append = 0
  next = 1
  next = 2
  ....
  ```
  Each index is marked in the SparseBitfield by setting the corresponding `bit` in
  the underlying byte array to true, aligning to the same index used when appending.
  That means we can track 8 indexes in 1 byte.

  For example, the first 8 appends to the feed, fit into the first `byte` of the bitfield:
  ```text
    index: [0,1,2,3,4,5,6,7,8]
     byte:  [1,1,1,1,1,1,1,1]
  ```
  This serves as a lookup index for the data: "Do you have the data for `index` 3?"
  Check the value of `bitfield[3]` if it's `1` (true) then yes.

  """
  alias Hyperex.MemoryPager
  use Bitwise, only_operators: true

  # {page, byte_length, bit_length}
  @type state() :: {pos_integer, :array.array(Hyperex.Storage.Buffer), pos_integer}

  @doc """
  Create a memory pager.
  `pagesize` is the size of each page. Default: 1024
  `pagesize` must be a power of 2
  """

  def new(pagesize \\ 1024) do
    # This will have to change later, when we load data from file
    MemoryPager.new(pagesize)
  end

  @doc """
  Set the bit at the given index.

  if `on` = true, bit is set to 1, else 0

  return the state and a boolean indicating whether
  the set value was different than the last value.
  """
  @spec set(
          state(),
          index :: pos_integer,
          on :: boolean
        ) ::
          {state(), boolean}
  def set(pager, index, on) do
    # return the byte for the given index
    {:ok, byte} = MemoryPager.read(pager, index, 1)

    # are we changing the byte
    changed = is_set?(index, byte) != on

    # set the bit on/off, returning the updated byte
    {:ok, updated_byte} = set_bit(index, byte, on)

    # note, `updated_byte` is an u8, so we put it in a binary
    # to make dialyzer happy
    {
      MemoryPager.write(pager, index, <<updated_byte>>),
      changed
    }
  end

  @doc """
  Get the bit value at the given index.

  Return true if the value is set (1), else 0
  """
  @spec get(state(), index :: pos_integer) ::
          boolean
  def get(pager, index) do
    {:ok, byte} = MemoryPager.read(pager, index, 1)
    is_set?(index, byte)
  end

  @doc """
  Set the bit on the given `byte` for the given `index`.
  if `on` is true, the bit is set to 1, else 0
  """
  @spec set_bit(index :: pos_integer, byte :: <<_::8>>, on :: boolean()) :: {:ok, byte}
  def set_bit(index, <<byte>>, on) do
    idx_mask = 128 >>> (index &&& 7)

    case on do
      true ->
        {:ok, byte ||| idx_mask}

      _ ->
        {:ok, byte &&& Bitwise.bxor(255, idx_mask)}
    end
  end

  @doc """
  Is the bit set on the given `byte` at the given index?
  """
  @spec is_set?(index :: pos_integer, byte :: <<_::8>>) :: boolean
  def is_set?(index, <<byte>>) do
    bit = Bitwise.bsr(byte, 7 - Bitwise.band(index, 7))

    case Bitwise.band(bit, 1) do
      1 -> true
      _ -> false
    end
  end
end
