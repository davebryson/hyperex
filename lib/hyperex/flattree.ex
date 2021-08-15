defmodule Hyperex.Flattree do
  @moduledoc """
  A Flat Tree is a deterministic way of using a list as an index
  for nodes in a tree. Essentially a simpler way of representing the
  position of nodes.

  A Flat Tree is also refered to as 'bin numbers' described here
  in RFC 7574: https://datatracker.ietf.org/doc/html/rfc7574#section-4.2

  As an example (from the RFC), here's a tree with a width of 8 leafs
  and a depth of 3:
  ```text
            3                      7
                           |-------|--------|
            2              3               11
                      |----|----|      |----|----|
            1         1         5      9        13
                    |-|-|     |-|-|  |-|-|     |-|-|
      Depth 0       0   2     4   6  8   10   12   14
                   C0  C1     C2  C3 C4  C5   C6   C7

      The flat tree is the list [0..14].  The content/leafs are C0..C7
  ```
    Using the flat tree, we can see that index:
      - 7 represents all the content (C0..C7)
      - 1 represents C0 and C1
      - 3 represent C0..C3
      ... etc ...

    Even numbers are always leafs at depth 0

    Odd numbers are parents at depths > 0
  """
  use Bitwise, only_operators: true

  @doc """
  Calculate the index given the depth and offset in the tree
  """
  @spec index(depth :: pos_integer, offset :: pos_integer) :: pos_integer
  def index(depth, offset) do
    offset <<< (depth + 1) ||| (1 <<< depth) - 1
  end

  @doc """
  Find the depth of the tree for a given index in the array.
  Zero-based index
  ```
    Ex:
    depth(1) == 1
    depth(5) == 1
    depth(3) == 2
  ```
  """
  @spec depth(index :: non_neg_integer) :: non_neg_integer
  def depth(index) do
    walk_depth(index + 1, 0)
  end

  defp walk_depth(index, depth) do
    case index &&& 1 do
      0 ->
        i = index >>> 1
        walk_depth(i, depth + 1)

      _ ->
        depth
    end
  end

  @doc """
  Return the offset for an index from the left side of the tree.

  ```text
  For example: (0, 1, 3, 7) have an offset of 0
  (Tree is rotated to right in diagram)

    (0)┐
      (1)┐
     2─┘ │
       (3)┐
    4─┐ │ │
      5─┘ │
    6─┘   │
         (7)

  While (2, 5, 11) have an offset of 1:

    0──┐
       1──┐
   (2)─┘  │
          3──┐
    4──┐  │  │
      (5)─┘  │
    6──┘     │
             7
    8──┐     │
       9──┐  │
   10──┘  │  │
        (11)─┘
   12──┐  │
      13──┘
   14──┘
  ```
  """
  @spec offset(index :: non_neg_integer) :: non_neg_integer
  def offset(index) when (index &&& 1) == 0 do
    index >>> 1
  end

  def offset(index) do
    d = depth(index)
    v = div(index + 1, 1 <<< d)
    v >>> 1
  end

  @doc """
  Return the parent of the given index
  ```text
    Given:
        1
       / \\
      0   2

    1 = parent(2)
  ```
  """
  @spec parent(index :: non_neg_integer) :: non_neg_integer
  def parent(index) do
    d = depth(index)
    index(d + 1, offset(index) >>> 1)
  end

  @doc """
  Return the index of node that shares a parent

  ```text
    Given:
        1
       / \\
      0   2

    0 = sibling(2)
  ```
  """
  @spec sibling(index :: non_neg_integer) :: non_neg_integer
  def sibling(index) do
    d = depth(index)
    index(d, :erlang.bxor(offset(index), 1))
  end

  @doc """
  Return the uncle of the index. The uncle is the parent's sibling

  ```text
             3
          /     \\
         1        5
        / \\     / \\
       0   2    4   6

     5 = uncle(0)
     1 = uncle(4)
  ```
  """
  @spec uncle(index :: non_neg_integer) :: non_neg_integer
  def uncle(index) do
    d = depth(index)
    index(d + 1, :erlang.bxor(offset(parent(index)), 1))
  end

  @doc """
  Return the children of a given index

  If the given index is a leaf or depth == 0 (still a leaf) return: `:none`
  """
  @spec children(non_neg_integer) :: {non_neg_integer, non_neg_integer}
  def children(index) do
    get_children(index, depth(index))
  end

  # No children of a leaf
  defp get_children(index, _) when (index &&& 1) == 0, do: :none
  # No children at depth 0
  defp get_children(_, 0), do: :none

  defp get_children(index, depth) do
    off = offset(index) * 2
    {index(depth - 1, off), index(depth - 1, off + 1)}
  end

  @doc """
  Get the child to the left of the given index

  If the index is a leaf, or depth == 0, return :none
  """
  @spec left_child(index :: non_neg_integer) :: :none | pos_integer
  def left_child(index) do
    d = depth(index)
    get_left_child(index, d)
  end

  defp get_left_child(index, _) when (index &&& 1) == 0, do: :none
  defp get_left_child(_, 0), do: :none

  defp get_left_child(index, depth) do
    index(depth - 1, offset(index) <<< 1)
  end

  @doc """
  Get the right child for the given index

  If the index is a leaf, or depth == 0, return :none
  """
  @spec right_child(index :: pos_integer) :: :none | pos_integer
  def right_child(index) do
    d = depth(index)
    get_right_child(index, d)
  end

  defp get_right_child(index, _) when (index &&& 1) == 0, do: :none
  defp get_right_child(_, 0), do: :none

  defp get_right_child(index, depth) do
    index(depth - 1, (offset(index) <<< 1) + 1)
  end

  @doc """
  Return the whole span for the given index, from left to right
  """
  @spec spans(index :: pos_integer) :: {:none | pos_integer, :none | pos_integer}
  def spans(index) do
    {left_span(index), right_span(index)}
  end

  @doc """
  Get the left most child from the index. Note, this could be
  a 'grandchild'.

  If depth is 0, return :none
  """
  @spec left_span(index :: pos_integer) :: :none | pos_integer
  def left_span(index) do
    d = depth(index)

    case d do
      0 ->
        :none

      _ ->
        offset(index) * (2 <<< d)
    end
  end

  @doc """
  Get the right most child from the index.  Note, this could be
  a grandchild

  If depth = 0, return :none
  """
  @spec right_span(index :: integer) :: :none | integer
  def right_span(index) do
    d = depth(index)

    case d do
      0 ->
        :none

      _ ->
        (offset(index) + 1) * (2 <<< d) - 2
    end
  end

  @doc """
  Return the count of all nodes in the subtree at the given index.
  Note, the count *includes* the node at the index.

  For example

   3 = count(1)

  includes the node 1,2,3
  """
  @spec count(index :: pos_integer) :: pos_integer
  def count(index) do
    (2 <<< depth(index)) - 1
  end

  @doc """
  Return a list of indices that represent the full nodes (and subtrees)
  to the left of the given index. Note, the given index must be a leaf (even) index.

  For example, given:
  ```text
            3
       |----|----|
       1         5
   |---|---| |---|---|
   0       2 4       6

   [1,4] = full_roots(6)
   [1]   = full_roots(4)
   []    = full_roots(0)
  ```
  """
  @spec full_roots(index :: pos_integer) :: list | {:error, :only_leaf_indices_allowed}
  def full_roots(index) when (index &&& 1) == 1, do: {:error, :only_leaf_indices_allowed}
  def full_roots(index), do: walk_roots(index >>> 1, 0, 1, [])

  defp walk_roots(0, _, _, nodes), do: Enum.reverse(nodes)

  defp walk_roots(index, offset, factor, nodes) do
    next_factor = determine_factor(factor, index)

    walk_roots(
      index - next_factor,
      offset + 2 * next_factor,
      1,
      [
        offset + next_factor - 1 | nodes
      ]
    )
  end

  defp determine_factor(factor, index) when factor * 2 <= index do
    determine_factor(factor * 2, index)
  end

  defp determine_factor(factor, _), do: factor
end
