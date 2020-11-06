defmodule PixelFont.GlyphStorage do
  use GenServer
  alias PixelFont.Glyph
  alias PixelFont.Glyph.{BitmapData, CompositeData}

  def start_link(glyph_sources, notdef_source) do
    GenServer.start_link(__MODULE__, {glyph_sources, notdef_source}, name: __MODULE__)
  end

  def all do
    GenServer.call(__MODULE__, :all, :infinity)
  end

  def get(id) do
    GenServer.call(__MODULE__, {:get, id}, :infinity)
  end

  @impl GenServer
  def init({glyph_sources, notdef_source}) do
    glyphs =
      glyph_sources
      |> Enum.map(& &1.glyphs)
      |> List.flatten()

    notdef =
      notdef_source.glyphs
      |> Enum.filter(&(&1.id === ".notdef"))
      |> Enum.take(1)

    groups = Enum.group_by(glyphs, &is_integer(&1.id))
    unicode_glyphs = groups[true] || []
    named_glyphs = groups[false] || []

    sorted_glyphs =
      [
        notdef,
        Enum.sort(unicode_glyphs, &(&1.id <= &2.id)),
        named_glyphs
      ]
      |> List.flatten()
      |> set_glyph_index([], 0)

    tmp_lookup = make_lookup(sorted_glyphs)
    linked = Enum.map(sorted_glyphs, &link_composite(&1, tmp_lookup))
    lookup = make_lookup(linked)

    {:ok, {linked, lookup}}
  end

  @impl GenServer
  def handle_call(msg, from, state)

  def handle_call(:all, _, {glyphs, _} = state) do
    {:reply, glyphs, state}
  end

  def handle_call({:get, id}, _, {_, map} = state) do
    {:reply, map[id], state}
  end

  defp make_lookup(glyphs), do: Map.new(glyphs, &{&1.id, &1})

  defp set_glyph_index(glyphs, acc, index)
  defp set_glyph_index([], acc, _), do: Enum.reverse(acc)

  defp set_glyph_index([g | gs], acc, index) do
    set_glyph_index(gs, [%Glyph{g | gid: index} | acc], index + 1)
  end

  defp link_composite(glyph, lookup)
  defp link_composite(%Glyph{data: %BitmapData{}} = simple, _lookup), do: simple

  defp link_composite(%Glyph{data: %CompositeData{components: components}} = composite, lookup) do
    linked_components =
      Enum.map(components, fn %{glyph_id: glyph_id} = component ->
        %{component | glyph: lookup[glyph_id]}
      end)

    %Glyph{composite | data: %CompositeData{components: linked_components}}
  end
end
