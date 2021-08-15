defmodule Hyperex.MerkleStreamTest do
  use ExUnit.Case, async: true

  alias Hyperex.MerkleStream

  test "merkle" do
    tree = MerkleStream.new()
    t1 = MerkleStream.write(tree, <<"a">>)
    t2 = MerkleStream.write(t1, <<"b">>)
    t3 = MerkleStream.write(t2, <<"c">>)

    {:tree, roots, nodes, blocks} = t3
    2 = length(roots)
    4 = length(nodes)
    3 = blocks

    <<252, 142, 154, 130, 181, 60, 231, 49, 120, 55, 103, 144, 226, 79, 167, 160, 169, 166, 22,
      151, 45, 222, 243, 130, 138, 2, 148, 4, 0, 226, 14, 136>> = MerkleStream.root_hash(t3)

    tree1 = MerkleStream.new()
    tt1 = MerkleStream.write(tree1, <<"a">>)
    tt2 = MerkleStream.write(tt1, <<"b">>)
    tt3 = MerkleStream.write(tt2, <<"c">>)
    tt4 = MerkleStream.write(tt3, <<"d">>)

    {:tree, roots1, nodes1, blocks1} = tt4
    1 = length(roots1)
    7 = length(nodes1)
    # leafs
    4 = blocks1

    assert MerkleStream.root_hash(t3) != MerkleStream.root_hash(tt4)
  end

  test "node serde" do
    hash =
      <<252, 142, 154, 130, 181, 60, 231, 49, 120, 55, 103, 144, 226, 79, 167, 160, 169, 166, 22,
        151, 45, 222, 243, 130, 138, 2, 148, 4, 0, 226, 14, 136>>

    len = 54

    raw = MerkleStream.node_to_bytes(hash, len)
    assert byte_size(raw) == 40

    back = MerkleStream.node_from_bytes(2, raw)
    assert {:treenode, 2, 1, 54, <<>>, hash} == back
  end
end
