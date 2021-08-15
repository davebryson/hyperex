defmodule Hyperex.Storage.MemoryStore do
  @moduledoc """
  Store used by feed
  """
  alias Hyperex.MemoryPager
  alias Hyperex.SparseBitfield
  alias Hyperex.MerkleStream
  alias Hyperex.Flattree

  use GenServer

  @header_offset 32

  defstruct [:data, :nodes, :bitfield]

  @spec start :: :ignore | {:error, any} | {:ok, pid}
  def start() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def read_data(index) do
    GenServer.call(__MODULE__, {:read_data, index})
  end

  def write_data(data) do
    GenServer.call(__MODULE__, {:write_data, data})
  end

  def write_node(node) do
    GenServer.call(__MODULE__, {:write_node, node})
  end

  def set_bitfield(index) do
    GenServer.call(__MODULE__, {:set_bitfield, index})
  end

  def total_data_bytes() do
    GenServer.call(__MODULE__, {:total_bytes})
  end

  ### Callbacks ###

  def init(_) do
    {:ok,
     %__MODULE__{
       data: MemoryPager.new(),
       nodes: MemoryPager.new(),
       bitfield: SparseBitfield.new()
     }}
  end

  def handle_call({:write_data, data}, _from, state) do
    {_, offset} = MemoryPager.info(state.data)
    s1 = MemoryPager.write(state.data, offset, data)
    {:reply, :ok, Map.put(state, :data, s1)}
  end

  def handle_call({:read_data, index}, _from, state) do
    case SparseBitfield.get(state.bitfield, index) do
      false ->
        {:reply, {:error, :not_found}, state}

      _ ->
        {offset, amt} = data_offset(state, index)
        {:ok, bytes} = MemoryPager.read(state.data, offset, amt)
        {:reply, {:ok, bytes}, state}
    end
  end

  def handle_call({:write_node, {:treenode, index, _, size, _, hash}}, _from, state) do
    bytes = MerkleStream.node_to_bytes(hash, size)
    offset = calculate_node_offset(index)
    s1 = MemoryPager.write(state.nodes, offset, bytes)
    {:reply, :ok, Map.put(state, :nodes, s1)}
  end

  def handle_call({:set_bitfield, index}, _from, state) do
    {s1, _} = SparseBitfield.set(state.bitfield, index, true)
    {:reply, :ok, Map.put(state, :bitfield, s1)}
  end

  def handle_call({:total_bytes}, _from, state) do
    {_, offset} = MemoryPager.info(state.data)
    {:reply, offset, state}
  end

  ### Helpers ###

  defp get_node(state, index) do
    offset = calculate_node_offset(index)
    {:ok, bytes} = MemoryPager.read(state.nodes, offset, 40)
    MerkleStream.node_from_bytes(index, bytes)
  end

  @spec calculate_node_offset(pos_integer) :: pos_integer
  defp calculate_node_offset(index) do
    @header_offset + 40 * index
  end

  defp data_offset(state, index) do
    leaf_index = 2 * index
    roots = Flattree.full_roots(leaf_index)

    offset =
      List.foldl(roots, 0, fn index, acc ->
        {:treenode, _index, _parent, size, _data, _hash} = get_node(state, index)
        acc + size
      end)

    {:treenode, _index, _parent, leafsize, _data, _hash} = get_node(state, leaf_index)

    # go through the roots and get increment offset
    # when done with them get the node for the leaf_index
    # and add to offset (len) for end
    # return range: {offset, offset+len}
    # IO.inspect(leafsize, label: "LEAFSIZE?")
    {offset, leafsize}
  end
end
