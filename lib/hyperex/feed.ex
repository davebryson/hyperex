defmodule Hyperex.Feed do
  @moduledoc """

  """

  use GenServer

  alias Hyperex.MerkleStream
  alias Hyperex.Storage.MemoryStore

  # need to track total bytes for write offset

  def start() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def append(data) do
    GenServer.call(__MODULE__, {:append, data})
  end

  def get(index) do
    GenServer.call(__MODULE__, {:get, index})
  end

  def total_bytes() do
    GenServer.call(__MODULE__, {:total_bytes})
  end

  ### Callbacks ###

  def init(_) do
    # create merkle
    tree = MerkleStream.new()

    # start storage
    {:ok, _} = MemoryStore.start()

    {:ok, {tree, 0}}
  end

  def handle_call({:append, data}, _from, {tree, entries}) do
    # write to merkle
    t = MerkleStream.write(tree, data)

    # write data to storage
    :ok = MemoryStore.write_data(data)

    # write merkle nodes to storage
    {:tree, _, nodes, _} = t
    Enum.each(nodes, fn n -> MemoryStore.write_node(n) end)

    # Note: what 'entries' is!
    MemoryStore.set_bitfield(entries)

    # TODO: Tree index

    {:reply, :ok, {t, entries + 1}}
  end

  def handle_call({:get, index}, _from, state) do
    result = MemoryStore.read_data(index)
    {:reply, result, state}
  end

  def handle_call({:total_bytes}, _from, state) do
    total = MemoryStore.total_data_bytes()
    {:reply, total, state}
  end
end
