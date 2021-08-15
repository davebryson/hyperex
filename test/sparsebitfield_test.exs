defmodule Hyperex.SparsebitfieldTest do
  use ExUnit.Case, async: true

  alias Hyperex.SparseBitfield

  test "bit functions work as expected" do
    assert {:ok, 0b10000000} = SparseBitfield.set_bit(0, <<0b00000000>>, true)
    assert {:ok, 0b01000000} = SparseBitfield.set_bit(17, <<0b00000000>>, true)
    assert {:ok, 0b00100000} = SparseBitfield.set_bit(18, <<0b00000000>>, true)
    assert {:ok, 0b00010000} = SparseBitfield.set_bit(19, <<0b00000000>>, true)
    assert {:ok, 0b00001000} = SparseBitfield.set_bit(20, <<0b00000000>>, true)
    assert {:ok, 0b00000100} = SparseBitfield.set_bit(21, <<0b00000000>>, true)
    assert {:ok, 0b00000010} = SparseBitfield.set_bit(22, <<0b00000000>>, true)
    assert {:ok, 0b00000001} = SparseBitfield.set_bit(23, <<0b00000000>>, true)
    assert {:ok, 0b10000000} = SparseBitfield.set_bit(1024, <<0b00000000>>, true)
    assert {:ok, 0b11111111} = SparseBitfield.set_bit(1029, <<0b11111011>>, true)

    # set false
    assert {:ok, 0b01111111} = SparseBitfield.set_bit(32, <<0b11111111>>, false)
    assert {:ok, 0b10111111} = SparseBitfield.set_bit(33, <<0b11111111>>, false)
    assert {:ok, 0b11011111} = SparseBitfield.set_bit(34, <<0b11111111>>, false)
    assert {:ok, 0b11101111} = SparseBitfield.set_bit(35, <<0b11111111>>, false)
    assert {:ok, 0b11110111} = SparseBitfield.set_bit(36, <<0b11111111>>, false)
    assert {:ok, 0b11111011} = SparseBitfield.set_bit(37, <<0b11111111>>, false)
    assert {:ok, 0b11111101} = SparseBitfield.set_bit(38, <<0b11111111>>, false)
    assert {:ok, 0b11111110} = SparseBitfield.set_bit(39, <<0b11111111>>, false)
    assert {:ok, 0b00000011} = SparseBitfield.set_bit(17, <<0b01000011>>, false)

    assert SparseBitfield.is_set?(2, <<0b00100000>>)
    assert SparseBitfield.is_set?(39, <<0b00100001>>)
    assert SparseBitfield.is_set?(1024, <<0b10100000>>)
  end

  test "can set and check bits at different locations" do
    sb = SparseBitfield.new()
    false = SparseBitfield.get(sb, 15)
    {sb1, true} = SparseBitfield.set(sb, 15, true)
    {sb2, false} = SparseBitfield.set(sb1, 15, true)

    {sb3, true} = SparseBitfield.set(sb2, 2056, true)
    {sb4, true} = SparseBitfield.set(sb3, 0, true)
    {sb5, true} = SparseBitfield.set(sb4, 10001, true)

    true = SparseBitfield.get(sb5, 0)
    true = SparseBitfield.get(sb5, 2056)
    true = SparseBitfield.get(sb5, 10001)

    # check is shows 'not changed'
    {sb6, false} = SparseBitfield.set(sb5, 10001, true)
    # change it
    {sb6, true} = SparseBitfield.set(sb6, 10001, false)
    # check it again
    false = SparseBitfield.get(sb6, 10001)
  end
end
