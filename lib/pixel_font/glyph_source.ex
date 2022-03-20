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
  defmacro glyph_source(name, _options \\ [], do: do_block) do
    {based_on_exprs, block} = get_exprs(do_block, expected: [:based_on])
    {exprs, _block} = get_exprs(block)
    {module_block, exprs} = handle_module(exprs, __CALLER__)

    map_expr =
      quote do
        unquote(exprs)
        |> List.flatten()
        |> unquote(__MODULE__).__make_contours__()
      end
      |> handle_based_on(based_on_exprs)

    quote do
      defmodule unquote(name) do
        import unquote(__MODULE__), only: [bmp_glyph: 2, composite_glyph: 2]

        unquote(module_block)

        @glyph_map unquote(map_expr)
        @glyph_list @glyph_map |> Map.values() |> Enum.sort(&(&1.id <= &2.id))

        def __glyph_map__, do: @glyph_map
        def glyphs, do: @glyph_list

        IO.puts("#{inspect(__MODULE__)}: Exported #{length(@glyph_list)} glyphs.")
      end
    end
  end

  defmacro based_on(_module, _options \\ []), do: block_direct_invocation!(__CALLER__)

  defp handle_based_on(map_expr, based_on_exprs)
  defp handle_based_on(map_expr, []), do: map_expr

  defp handle_based_on(map_expr, [{:based_on, meta, [module]}]) do
    handle_based_on(map_expr, [{:based_on, meta, [module, []]}])
  end

  defp handle_based_on(map_expr, [{:based_on, _meta, [module, options]}]) do
    ensure_module!(module)

    quote do
      unquote(module).__glyph_map__()
      |> Enum.filter(unquote(filter_fun_expr(options)))
      |> Map.new()
      |> Map.merge(unquote(map_expr))
    end
  end

  defp handle_based_on(_map_expr, [_ | _] = exprs) do
    raise "`based_on` directive must be used at most once, " <>
            "found #{length(exprs)} occurrences"
  end

  @spec ensure_module!(Macro.t()) :: :ok | no_return()
  defp ensure_module!(expr)
  defp ensure_module!(expr) when is_atom(expr), do: :ok
  defp ensure_module!({:__aliases__, _meta, [_ | _]}), do: :ok

  defp ensure_module!(expr) do
    raise "expected the value of `module` to be known as a module " <>
            "during compilation time, got: #{inspect(expr)}"
  end

  @spec filter_fun_expr(keyword()) :: Macro.t()
  defp filter_fun_expr(options) do
    case Keyword.get(options, :only) do
      nil -> quote(do: fn _ -> true end)
      :unicode -> quote(do: fn {_, %Glyph{id: id}} -> is_integer(id) end)
      :named -> quote(do: fn {_, %Glyph{id: id}} -> is_binary(id) end)
    end
  end

  defmacro bmp_glyph(id, do: block) do
    {glyph_exprs, block} = get_exprs(block, expected: ~w(variations)a)

    quote do
      if true do
        import unquote(__MODULE__), only: [advance: 1, bounds: 2, data: 1, variations: 2]

        var!(bmp_data) = %BitmapData{}

        unquote(block)

        {unquote(id), unquote(glyph_expr(id, glyph_exprs, quote(do: var!(bmp_data))))}
      end
    end
  end

  Enum.each(~w(advance data)a, fn key ->
    @spec unquote(key)(Macro.t()) :: Macro.t()
    defmacro unquote(key)(expr) do
      quote(bind_quoted: [key: unquote(key), expr: expr]) do
        var!(bmp_data) = struct!(var!(bmp_data), [{key, expr}])
      end
    end
  end)

  @spec bounds(Macro.t(), Macro.t()) :: Macro.t()
  defmacro bounds(x_bounds, y_bounds) do
    {:.., _, [xmin, xmax]} = x_bounds
    {:.., _, [ymin, ymax]} = y_bounds

    fields_expr = [xmin: xmin, xmax: xmax, ymin: ymin, ymax: ymax]

    quote do
      var!(bmp_data) = struct!(var!(bmp_data), unquote(fields_expr))
    end
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

    data_expr =
      quote do
        %CompositeData{components: Enum.reject(var!(components), &is_nil/1)}
      end

    quote do
      if true do
        import unquote(__MODULE__), only: [component: 3, component: 4, variations: 2]

        {:ok, var!(agent)} = Agent.start_link(fn -> [] end)

        unquote(block)

        var!(components) = Agent.get(var!(agent), &Enum.reverse(&1))
        :ok = Agent.stop(var!(agent))

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
      Agent.update(
        var!(agent),
        &[
          %{
            glyph_id: unquote(glyph_id),
            glyph: nil,
            x_offset: unquote(x_off),
            y_offset: unquote(y_off),
            flags: unquote(opts)[:flags] || []
          }
          | &1
        ]
      )
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
