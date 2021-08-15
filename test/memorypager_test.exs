defmodule Hyperex.MemorypagerTest do
  use ExUnit.Case, async: true
  alias Hyperex.MemoryPager

  test "memory pager basics" do
    # small page size of 8 bytes for testing
    r0 = MemoryPager.new(8)
    r1 = MemoryPager.write(r0, 0, <<"dave">>)
    r2 = MemoryPager.write(r1, 4, <<"carl">>)

    # 1 page, 8 bytes
    assert {1, 8} = MemoryPager.info(r2)

    # handle overlapping pages
    r3 = MemoryPager.write(r2, 8, <<"aaaaaaaabbb">>)

    # 3 pages, 19 bytes
    assert {3, 19} = MemoryPager.info(r3)

    assert {:ok, <<"aaaaaaaa">>} = MemoryPager.read(r3, 8, 8)
    assert {:ok, <<"bbb">>} = MemoryPager.read(r3, 16, 3)
    assert {:ok, <<"dave">>} = MemoryPager.read(r3, 0, 4)
    assert {:ok, <<"carl">>} = MemoryPager.read(r3, 4, 4)

    # random write
    r4 = MemoryPager.write(r3, 88, <<"zzzzzzzz">>)
    assert {:ok, <<"zzzzzzzz">>} = MemoryPager.read(r4, 88, 8)
  end

  test "memory pager byte" do
    r0 = MemoryPager.new(8)
    r1 = MemoryPager.write(r0, 0, <<1>>)
    r2 = MemoryPager.write(r1, 4, <<1>>)
    r3 = MemoryPager.write(r2, 6, <<1>>)

    assert {1, 3} = MemoryPager.info(r3)

    assert {:ok, <<1>>} = MemoryPager.read(r3, 0, 1)
    assert {:ok, <<1>>} = MemoryPager.read(r3, 4, 1)
    assert {:ok, <<1>>} = MemoryPager.read(r3, 6, 1)

    # Change offset 4
    r4 = MemoryPager.write(r3, 4, <<0>>)
    assert {:ok, <<0>>} = MemoryPager.read(r4, 4, 1)
  end
end
