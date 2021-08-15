defmodule Hyperex.BufferTest do
  use ExUnit.Case, async: true
  alias Hyperex.Storage.Buffer

  test "buffer test" do
    {:ok, buf} = Buffer.new()
    # 4
    b1 = Buffer.write(buf, 0, <<"dave">>)
    # 3
    b2 = Buffer.write(b1, 8, <<"bob">>)
    # 4
    b3 = Buffer.write(b2, 16, <<"carl">>)

    <<"bob">> = Buffer.read(b3, 8, 3)
    <<"carl">> = Buffer.read(b3, 16, 4)
    <<"dave">> = Buffer.read(b3, 0, 4)

    1024 = Buffer.size(b3)

    # delete bob
    b4 = Buffer.delete(b3, 8, 3)
    # check it
    <<0, 0, 0>> = Buffer.read(b4, 8, 3)
    <<"carl">> = Buffer.read(b4, 16, 4)
    <<"dave">> = Buffer.read(b4, 0, 4)
  end
end
