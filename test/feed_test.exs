defmodule Hyperex.FeedTest do
  use ExUnit.Case, async: true
  alias Hyperex.Feed

  test "feed basics" do
    assert {:ok, _} = Feed.start()
    # 4
    assert :ok = Feed.append(<<"dave">>)
    # 3
    assert :ok = Feed.append(<<"bob">>)
    # 12
    assert :ok = Feed.append(<<"aaaaaaaaaabb">>)
    # 4
    assert :ok = Feed.append(<<"ccdd">>)

    assert {:ok, <<"aaaaaaaaaabb">>} = Feed.get(2)
    assert {:ok, <<"dave">>} = Feed.get(0)
    assert {:ok, <<"bob">>} = Feed.get(1)
    assert {:ok, <<"ccdd">>} = Feed.get(3)

    assert 23 = Feed.total_bytes()

    assert {:error, :not_found} = Feed.get(100)
  end
end
