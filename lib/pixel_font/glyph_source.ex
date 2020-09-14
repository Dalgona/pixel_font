defmodule PixelFont.GlyphSource do
  require PixelFont.RectilinearShape, as: RectilinearShape
  require PixelFont.RectilinearShape.Path, as: Path

  defmacro export_glyphs(options \\ [], do: do_block) do
    exprs = get_exprs(do_block)

    map_expr =
      quote do
        unquote(exprs)
        |> List.flatten()
        |> unquote(__MODULE__).__make_contours__()
        |> Map.new()
      end
      |> handle_based_on(options[:based_on])

    quote do
      @glyph_map unquote(map_expr)
      @glyph_list @glyph_map |> Map.values() |> Enum.sort(&(&1.id <= &2.id))

      def __glyph_map__, do: @glyph_map
      def glyphs, do: @glyph_list
    end
  end

  defp handle_based_on(map_expr, expr)
  defp handle_based_on(map_expr, nil), do: map_expr

  defp handle_based_on(map_expr, module) when is_atom(module) do
    quote(do: Map.merge(unquote(module).__glyph__map__(), unquote(map_expr)))
  end

  defp handle_based_on(map_expr, {:__aliases__, _, _} = alias_expr) do
    quote(do: Map.merge(unquote(alias_expr).__glyph_map__(), unquote(map_expr)))
  end

  defp handle_based_on(_map_expr, x) do
    raise "expected the value of :based_on keyword to be known " <>
            "as an atom or an alias in compilation time, got: #{inspect(x)}"
  end

  defmacro bmp_glyph([{type, id}], do: block) when type in ~w(unicode name)a do
    exprs = get_exprs(block)
    map_expr = {:%{}, [], [{:type, type}, {:id, id}, {:contours, nil} | exprs]}

    {{type, id}, map_expr}
  end

  Enum.each(~w(advance xmin xmax ymin ymax data)a, fn key ->
    @spec unquote(key)(Macro.t()) :: Macro.t()
    defmacro unquote(key)(expr), do: {unquote(key), expr}
  end)

  def __make_contours__(glyphs) do
    glyphs
    |> Task.async_stream(fn
      {id, %{data: data, xmin: xmin, ymax: ymax} = glyph} ->
        contours =
          data
          |> String.split(~r/\r?\n/, trim: true)
          |> Enum.map(&to_charlist/1)
          |> RectilinearShape.from_bmp()
          |> Path.transform({{1, 0}, {0, -1}}, {xmin, ymax})

        {id, %{glyph | contours: contours}}

      {id, %{} = glyph} ->
        {id, glyph}
    end)
    |> Enum.map(&elem(&1, 1))
  end

  defmacro composite_glyph([{type, id}], do: do_block) when type in ~w(unicode name)a do
    exprs = get_exprs(do_block)

    quote do
      {{unquote(type), unquote(id)},
       %{
         type: unquote(type),
         id: unquote(id),
         components: Enum.reject(unquote(exprs), &is_nil/1)
       }}
    end
  end

  defmacro component(glyph_id, x_off, y_off) do
    handle_component(glyph_id, x_off, y_off, [])
  end

  defmacro component(glyph_id, x_off, y_off, opts) do
    handle_component(glyph_id, x_off, y_off, opts)
  end

  defp handle_component(glyph_id, x_off, y_off, opts) do
    quote do
      %{
        glyph: unquote(glyph_id),
        x_offset: unquote(x_off),
        y_offset: unquote(y_off),
        flags: unquote(opts)[:flags] || []
      }
    end
  end

  defp get_exprs(do_block)
  defp get_exprs({:__block__, _, exprs}), do: exprs
  defp get_exprs(expr), do: [expr]
end
