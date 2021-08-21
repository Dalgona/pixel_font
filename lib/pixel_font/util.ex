defmodule PixelFont.Util do
  @spec sigil_i(Macro.t(), keyword()) :: Macro.t()
  defmacro sigil_i(str_expr, mods)
  defmacro sigil_i(str_expr, ''), do: do_sigil_i(str_expr, 10)
  defmacro sigil_i(str_expr, 'o'), do: do_sigil_i(str_expr, 8)
  defmacro sigil_i(str_expr, 'd'), do: do_sigil_i(str_expr, 10)
  defmacro sigil_i(str_expr, 'x'), do: do_sigil_i(str_expr, 16)

  @spec sigil_i(Macro.t(), integer()) :: Macro.t()
  defp do_sigil_i(str_expr, base) do
    quote(do: unquote(__MODULE__).__sigil_i__(unquote(str_expr), unquote(base)))
  end

  @spec __sigil_i__(binary(), integer()) :: [integer()]
  def __sigil_i__(str, base) do
    str
    |> String.split(~r/\s+/, trim: true)
    |> Enum.map(&try_parse_integer(&1, base))
  end

  @spec try_parse_integer(binary(), integer()) :: integer() | no_return()
  defp try_parse_integer(str, base) do
    str
    |> Integer.parse(base)
    |> case do
      {integer, ""} -> integer
      {_, _} -> raise "#{inspect(str)} is not a valid integer in base #{base}"
      :error -> raise "#{inspect(str)} is not a valid integer in base #{base}"
    end
  end

  @spec elem!(Macro.t(), [Macro.t()]) :: Macro.t()
  defmacro elem!(tuple, indices) when is_list(indices) do
    Enum.reduce(indices, tuple, &quote(do: elem(unquote(&2), unquote(&1))))
  end

  @spec gid!(Macro.t()) :: Macro.t()
  defmacro gid!(id) do
    quote bind_quoted: [id: id] do
      id
      |> PixelFont.GlyphStorage.GenServer.get()
      |> case do
        nil -> raise "GID for #{inspect(id)} not found"
        glyph -> glyph.gid
      end
    end
  end

  @spec offsetted_binaries(list(), integer(), (term() -> iodata())) ::
          {integer(), [binary()], [binary()]}
  def offsetted_binaries(sources, offset_base, fun) do
    {pos, offsets, data} =
      sources
      |> Enum.reduce({offset_base, [], []}, fn source, {pos, offsets, data} ->
        binary = IO.iodata_to_binary(fun.(source))

        {pos + byte_size(binary), [pos | offsets], [binary | data]}
      end)

    {pos, offsets |> Enum.reverse() |> Enum.map(&<<&1::16>>), Enum.reverse(data)}
  end
end
