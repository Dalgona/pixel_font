defmodule PixelFont.GlyphSource do
  require PixelFont.RectilinearShape, as: RectilinearShape
  require PixelFont.RectilinearShape.Path, as: Path
  import PixelFont.DSL.MacroHelper
  alias PixelFont.Glyph
  alias PixelFont.Glyph.{BitmapData, CompositeData, VariationSequence}

  @type source_options :: [based_on: module()]

  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__), only: [glyph_source: 2, glyph_source: 3]
    end
  end

  @spec glyph_source(module(), do: Macro.t()) :: Macro.t()
  @spec glyph_source(module(), source_options(), do: Macro.t()) :: Macro.t()
  defmacro glyph_source(name, options \\ [], do: do_block) do
    {exprs, _block} = get_exprs(do_block)

    map_expr =
      quote do
        unquote(exprs)
        |> List.flatten()
        |> unquote(__MODULE__).__make_contours__()
      end
      |> handle_based_on(options[:based_on])

    quote do
      defmodule unquote(name) do
        import unquote(__MODULE__), only: [bmp_glyph: 2, composite_glyph: 2]

        @glyph_map unquote(map_expr)
        @glyph_list @glyph_map |> Map.values() |> Enum.sort(&(&1.id <= &2.id))

        def __glyph_map__, do: @glyph_map
        def glyphs, do: @glyph_list

        IO.puts("#{inspect(__MODULE__)}: Exported #{length(@glyph_list)} glyphs.")
      end
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

  defmacro bmp_glyph(id, do: block) do
    {glyph_exprs, block} = get_exprs(block, expected: ~w(variations)a)
    {bmp_data_exprs, _block} = get_exprs(block, expected: ~w(advance bounds data)a, warn: true)

    data_expr =
      quote do
        struct!(
          BitmapData,
          [{:contours, []} | List.flatten(unquote(bmp_data_exprs))]
        )
      end

    quote do
      if true do
        import unquote(__MODULE__), only: [advance: 1, bounds: 2, data: 1, variations: 2]

        {unquote(id), unquote(glyph_expr(id, glyph_exprs, data_expr))}
      end
    end
  end

  Enum.each(~w(advance data)a, fn key ->
    @spec unquote(key)(Macro.t()) :: Macro.t()
    defmacro unquote(key)(expr), do: {unquote(key), expr}
  end)

  @spec bounds(Macro.t(), Macro.t()) :: Macro.t()
  defmacro bounds(x_bounds, y_bounds) do
    {:.., _, [xmin, xmax]} = x_bounds
    {:.., _, [ymin, ymax]} = y_bounds

    [xmin: xmin, xmax: xmax, ymin: ymin, ymax: ymax]
  end

  def __make_contours__(glyphs) do
    glyphs
    |> Task.async_stream(fn
      {id, %Glyph{data: %BitmapData{} = data} = glyph} ->
        contours =
          data.data
          |> String.split(~r/\r?\n/, trim: true)
          |> Enum.map(&to_charlist/1)
          |> RectilinearShape.from_bmp()
          |> Path.transform({{1, 0}, {0, -1}}, {data.xmin, data.ymax})

        {id, %Glyph{glyph | data: %BitmapData{data | contours: contours}}}

      {id, %Glyph{} = glyph} ->
        {id, glyph}
    end)
    |> Map.new(&elem(&1, 1))
  end

  defmacro composite_glyph(id, do: block) do
    {glyph_exprs, block} = get_exprs(block, expected: ~w(variations)a)
    {composite_data_exprs, _block} = get_exprs(block)

    data_expr =
      quote do
        %CompositeData{
          components: Enum.reject(unquote(composite_data_exprs), &is_nil/1)
        }
      end

    quote do
      if true do
        import unquote(__MODULE__), only: [component: 3, component: 4, variations: 2]

        {unquote(id), unquote(glyph_expr(id, glyph_exprs, data_expr))}
      end
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
        glyph_id: unquote(glyph_id),
        glyph: nil,
        x_offset: unquote(x_off),
        y_offset: unquote(y_off),
        flags: unquote(opts)[:flags] || []
      }
    end
  end

  defp glyph_expr(id, glyph_exprs, data_expr) do
    quote do
      struct!(
        Glyph,
        [{:id, unquote(id)}, {:data, unquote(data_expr)} | unquote(glyph_exprs)]
      )
    end
  end

  defmacro variations([default: default_vs], do: block) when default_vs in 1..256 do
    non_default_map_expr =
      block
      |> Map.new(fn
        {:->, _, [[vs], target_glyph_id]} when vs in 1..256 ->
          {vs, target_glyph_id}
      end)
      |> Macro.escape()

    quote do
      {:variations,
       %VariationSequence{
         default: unquote(default_vs),
         non_default: unquote(non_default_map_expr)
       }}
    end
  end
end
