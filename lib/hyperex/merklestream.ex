defmodule Hyperex.MerkleStream do
  @moduledoc """
  Build an in-memory merkle tree to calculate a root hash
  """
  require Record
  alias Hyperex.Flattree
  use Bitwise, only_operators: true

  Record.defrecord(:tree, roots: [], nodes: [], blocks: 0)
  Record.defrecord(:treenode, index: 0, parent: nil, size: 0, data: <<>>, hash: <<>>)

  @empty_data <<>>

  @doc """
  Create a new tree returning the state
  """
  @spec new([{:treenode, any, any, any, any}]) ::
          {:tree, [{:treenode, any, any, any, any}], list, integer}
  def new(roots \\ []) do
    roots_length = length(roots)

    blocks =
      case roots_length > 0 do
        true ->
          tn = Enum.at(roots, roots_length - 1)
          (1 + Flattree.right_span(treenode(tn, :index))) >>> 1

        _ ->
          0
      end

    nodes = calc_all_parents(roots, [])
    {:tree, roots, nodes, blocks}
  end

  defp calc_all_parents([], acc), do: Enum.reverse(acc)

  defp calc_all_parents([{:treenode, idx, prt, _, _} = n | nodes], acc) do
    if prt == nil do
      updated = treenode(n, parent: Flattree.parent(idx))
      calc_all_parents(nodes, [updated | acc])
    else
      calc_all_parents(nodes, [n | acc])
    end
  end

  @doc """
  Write data to the tree
  """
  @spec write({:tree, any, any, non_neg_integer}, binary) ::
          {:tree, nonempty_maybe_improper_list, nonempty_maybe_improper_list, pos_integer}
  def write({:tree, roots, nodes, blocks}, data) do
    index = 2 * blocks
    blks = blocks + 1

    leaf = create_leaf(index, data)
    {roots1, nodes1} = update_tree([leaf | roots], [leaf | nodes])
    {:tree, roots1, nodes1, blks}
  end

  defp update_tree([n], nodes), do: {[n], nodes}

  defp update_tree([r, l | rest] = roots, nodes) do
    left_parent = treenode(l, :parent)
    right_parent = treenode(r, :parent)

    case left_parent != right_parent do
      true ->
        {roots, nodes}

      _ ->
        internal = create_internal(l, r)

        case length(roots) do
          2 -> update_tree([internal], [internal | nodes])
          _ -> update_tree([internal | rest], [internal | nodes])
        end
    end
  end

  @doc """
  Get the root hash of the current tree
  """
  @spec root_hash({:tree, list, any, any}) :: binary
  def root_hash({:tree, roots, _, _}) do
    h0 = :crypto.hash_init(:sha256)

    h1 =
      List.foldl(roots, h0, fn n, hasher ->
        {:treenode, _, _, _, _, hash} = n
        :crypto.hash_update(hasher, hash)
      end)

    :crypto.hash_final(h1)
  end

  @doc """
  Serialize a node to bytes
  """
  @spec node_to_bytes(nonempty_binary, pos_integer) :: <<_::320>>
  def node_to_bytes(hash, node_len) when is_binary(hash) and is_integer(node_len) do
    # 40 bytes
    <<hash::bits-size(256), node_len::size(64)-big-integer-unsigned>>
  end

  @doc """
  Deserialize a node from bytes
  """
  @spec node_from_bytes(pos_integer, <<_::320>>) ::
          {:treenode, pos_integer, pos_integer, pos_integer, <<>>, <<_::256>>}
  def node_from_bytes(index, raw) when byte_size(raw) == 40 do
    <<hash::bits-size(256), len::size(64)-big-integer-unsigned>> = raw

    {
      :treenode,
      index,
      Flattree.parent(index),
      len,
      <<>>,
      hash
    }
  end

  ### Private ###

  defp create_leaf(index, data) do
    treenode(
      index: index,
      parent: Flattree.parent(index),
      size: byte_size(data),
      data: data,
      hash: :crypto.hash(:sha256, data)
    )
  end

  defp create_internal(left, right) do
    left_parent = treenode(left, :parent)
    hasher0 = :crypto.hash_init(:sha256)
    hasher1 = :crypto.hash_update(hasher0, treenode(left, :data))
    hasher2 = :crypto.hash_update(hasher1, treenode(right, :data))
    hash = :crypto.hash_final(hasher2)

    treenode(
      index: left_parent,
      parent: Flattree.parent(left_parent),
      size: byte_size(treenode(left, :data)) + byte_size(treenode(right, :data)),
      data: @empty_data,
      hash: hash
    )
  end
end
