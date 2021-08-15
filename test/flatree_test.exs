defmodule Hyperex.FlattreeTest do
  use ExUnit.Case, async: true

  alias Hyperex.Flattree

  test "depth" do
    # {index, expected}
    data = [
      {0, 0},
      {1, 1},
      {3, 2},
      {7, 3},
      {4, 0},
      {5, 1}
    ]

    assert Enum.all?(
             data,
             fn {i, e} -> e == Flattree.depth(i) end
           )
  end

  test "offset" do
    # {index, expected}
    data = [
      {0, 0},
      {2, 1},
      {1, 0},
      {3, 0},
      {5, 1},
      {6, 3},
      {7, 0},
      {9, 2},
      {6, 3},
      {8, 4},
      {11, 1},
      {14, 7},
      {13, 3}
    ]

    assert Enum.all?(
             data,
             fn {i, e} -> e == Flattree.offset(i) end
           )
  end

  test "index" do
    # {expected, {depth, offset}}
    data = [
      {0, {0, 0}},
      {2, {0, 1}},
      {4, {0, 2}},
      {9, {1, 2}},
      {13, {1, 3}},
      {11, {2, 1}},
      {19, {2, 2}},
      {7, {3, 0}},
      {23, {3, 1}}
    ]

    assert Enum.all?(
             data,
             fn {e, {d, o}} -> e == Flattree.index(d, o) end
           )
  end

  test "parent" do
    # {index, expected}
    data = [{2, 1}, {4, 5}, {11, 7}, {12, 13}]

    assert Enum.all?(
             data,
             fn {i, e} -> e == Flattree.parent(i) end
           )
  end

  test "sibling" do
    # {index, expected}
    data = [
      {0, 2},
      {2, 0},
      {1, 5},
      {5, 1},
      {13, 9},
      {12, 14},
      {3, 11}
    ]

    assert Enum.all?(
             data,
             fn {i, e} -> e == Flattree.sibling(i) end
           )
  end

  test "uncle" do
    # {index, expected}
    data = [
      {0, 5},
      {4, 1},
      {5, 11},
      {9, 3},
      {10, 13}
    ]

    assert Enum.all?(
             data,
             fn {i, e} -> e == Flattree.uncle(i) end
           )
  end

  test "children" do
    :none = Flattree.children(0)
    {3, 11} = Flattree.children(7)
    {9, 13} = Flattree.children(11)
    {0, 2} = Flattree.children(1)
  end

  test "left child" do
    0 = Flattree.left_child(1)
    4 = Flattree.left_child(5)
    3 = Flattree.left_child(7)
    8 = Flattree.left_child(9)
  end

  test "right child" do
    2 = Flattree.right_child(1)
    6 = Flattree.right_child(5)
    11 = Flattree.right_child(7)
    10 = Flattree.right_child(9)
  end

  test "left spans" do
    :none = Flattree.left_span(0)
    0 = Flattree.left_span(3)
    4 = Flattree.left_span(5)
    8 = Flattree.left_span(11)
    0 = Flattree.left_span(7)
  end

  test "right spans" do
    6 = Flattree.right_span(3)
    6 = Flattree.right_span(5)
    14 = Flattree.right_span(11)
    14 = Flattree.right_span(7)
  end

  test "spans" do
    {0, 14} = Flattree.spans(7)
    {0, 6} = Flattree.spans(3)
    {8, 14} = Flattree.spans(11)
  end

  test "count" do
    7 = Flattree.count(3)
    3 = Flattree.count(1)
    15 = Flattree.count(7)
  end

  test "full roots" do
    {:error, :only_leaf_indices_allowed} = Flattree.full_roots(3)
    [1, 4] = Flattree.full_roots(6)
    [1] = Flattree.full_roots(4)
    [3] = Flattree.full_roots(8)
    [3, 8] = Flattree.full_roots(10)
    [3, 9] = Flattree.full_roots(12)
    [3, 9, 12] = Flattree.full_roots(14)
  end
end
