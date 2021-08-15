defmodule Hyperex.MemoryPager do
  @moduledoc """
  Create small memory buffers for an application without needing to allocate
  one big memory buffer. For example, maybe you need to reference data by bytes at random
  locations but you don't know which locations use. Or, you're processing
  chunks that may live at different byte positions. Rather than trying to create 1 large
  buffer to handle this, you can use memory_page to allocate only the buffers needed.

  Say you have data at bit positions: 10, 1048, and will have others at higher ranges. You
  could use this:
  ```text
  1 big buffer
  [ | | | | | | ... ]
  0                 4k
  ```
  Even though you may not need it all. Or you could do this: use Smaller buffers at
  different offsets on demand:

  ```text
  [0] -> [ | | ...]
         0       1023
  ```

  ```text
  [1] -> [ | | ...]
        1024     2048
  ```

  Memory Pager does the latter.

  MemoryPager knows how to locate a page and provide access to the buffer assigned
  to the page.  The format you use to write and read the buffer is up to the using
  application.
  """
  use Bitwise
  alias Hyperex.Storage.Buffer

  @type state() ::
          {pagesize :: pos_integer(), pager :: :array.array(Buffer), total_bytes :: pos_integer()}

  @doc """
  """
  @spec new(pos_integer()) :: {pos_integer(), :array.array(Buffer), 0}
  def new(pagesize \\ 1024) do
    {pagesize, :array.new(), 0}
  end

  @doc """
  """
  @spec write(state, pos_integer(), bitstring()) :: state
  def write({pagesize, pager, total}, index, data) do
    {pagenum, position} = get_page_and_offset(index, pagesize)

    batch =
      case byte_size(data) do
        1 -> [{pagenum, position, data}]
        _ -> maybe_split_pages(pagenum, pagesize, data, position, [])
      end

    pager1 =
      List.foldl(batch, pager, fn {pn, pos, bin}, pgr ->
        buffer = get_buffer(pn, pgr, pagesize)
        b1 = Buffer.write(buffer, pos, bin)
        :array.set(pn, b1, pgr)
      end)

    new_total = total + byte_size(data)
    {pagesize, pager1, new_total}
  end

  @spec read(state, pos_integer, pos_integer()) ::
          {:error, :not_found} | {:ok, bitstring}
  def read({pagesize, pager, _}, index, num_bytes_to_read) do
    {pagenum, position} = get_page_and_offset(index, pagesize)

    buf = get_buffer(pagenum, pager, pagesize)
    result = Buffer.read(buf, position, num_bytes_to_read)
    {:ok, result}
  end

  @spec info(state) :: {num_pages :: pos_integer(), total_bytes :: pos_integer()}
  def info({_, pager, total}) do
    num_pages = :array.size(pager)
    {num_pages, total}
  end

  ### Helpers ###

  defp get_buffer(num, pager, pagesize) do
    {:ok, buffer} =
      case :array.get(num, pager) do
        :undefined -> Buffer.new(pagesize)
        buf -> {:ok, buf}
      end

    buffer
  end

  defp get_page_and_offset(index, pagesize) do
    offset = Bitwise.band(index, pagesize - 1)
    pagenum = div(index, pagesize)
    {pagenum, offset}
  end

  defp maybe_split_pages(_pagenum, _pagesize, <<>>, _position, acc), do: acc

  defp maybe_split_pages(pagenum, pagesize, data, position, acc) do
    totalneeded = byte_size(data) + position

    case totalneeded > pagesize do
      true ->
        amount = pagesize - position
        <<a::bytes-size(amount), rest::binary>> = data

        maybe_split_pages(
          pagenum + 1,
          pagesize,
          rest,
          0,
          [{pagenum, position, a} | acc]
        )

      _ ->
        [{pagenum, position, data} | acc]
    end
  end
end
