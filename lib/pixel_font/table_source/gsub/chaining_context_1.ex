defmodule PixelFont.TableSource.GSUB.ChainingContext1 do
  alias PixelFont.Glyph

  defstruct [:subrulesets]

  @type t :: %__MODULE__{subrulesets: subruleset()}
  @type subruleset :: %{optional(Glyph.id()) => [subrule()]}

  @type subrule :: %{
          backtrack: [Glyph.id()],
          input: [Glyph.id()],
          lookahead: [Glyph.id()],
          substitutions: [{integer(), term()}]
        }

  defimpl PixelFont.TableSource.GSUB.Subtable do
    require PixelFont.Util, as: Util
    import Util, only: :macros
    alias PixelFont.TableSource.GPOSGSUB
    alias PixelFont.TableSource.GSUB.ChainingContext1
    alias PixelFont.TableSource.OTFLayout.GlyphCoverage

    @spec compile(ChainingContext1.t(), keyword()) :: binary()
    def compile(subtable, opts) do
      lookup_indices = opts[:lookup_indices]
      ruleset_count = map_size(subtable.subrulesets)

      {glyphs, subrulesets} =
        subtable.subrulesets
        |> Enum.map(fn {key, value} -> {gid!(key), value} end)
        |> Enum.sort(&(elem(&1, 0) <= elem(&2, 0)))
        |> Enum.unzip()

      compiled_coverage =
        glyphs
        |> GlyphCoverage.of()
        |> GlyphCoverage.compile(internal: true)

      coverage_offset = 6 + ruleset_count * 2
      offset_base = coverage_offset + byte_size(compiled_coverage)

      {_, offsets, compiled_subrulesets} =
        compile_subrulesets(subrulesets, offset_base, lookup_indices)

      IO.iodata_to_binary([
        <<1::16>>,
        <<coverage_offset::16>>,
        <<ruleset_count::16>>,
        offsets,
        compiled_coverage,
        compiled_subrulesets
      ])
    end

    @spec compile_subrulesets(
            [[ChainingContext1.subrule()]],
            integer(),
            GPOSGSUB.lookup_indices()
          ) :: {integer(), [binary()], [binary()]}
    defp compile_subrulesets(subrulesets, offset_base, lookup_indices) do
      Util.offsetted_binaries(subrulesets, offset_base, fn subrules ->
        subrule_offset_base = 2 + length(subrules) * 2

        {_, offsets, compiled_subrules} =
          compile_subrules(subrules, subrule_offset_base, lookup_indices)

        [<<length(subrules)::16>>, offsets, compiled_subrules]
      end)
    end

    @spec compile_subrules([ChainingContext1.subrule()], integer(), GPOSGSUB.lookup_indices()) ::
            {integer(), [binary()], [binary()]}
    defp compile_subrules(subrules, offset_base, lookup_indices) do
      Util.offsetted_binaries(subrules, offset_base, fn subrule ->
        sub_records =
          Enum.map(subrule.substitutions, fn {glyph_pos, lookup_name} ->
            <<glyph_pos::16, lookup_indices[lookup_name]::16>>
          end)

        [
          <<length(subrule.backtrack)::16>>,
          Enum.map(subrule.backtrack, &<<gid!(&1)::16>>),
          <<length(subrule.input) + 1::16>>,
          Enum.map(subrule.input, &<<gid!(&1)::16>>),
          <<length(subrule.lookahead)::16>>,
          Enum.map(subrule.lookahead, &<<gid!(&1)::16>>),
          <<length(sub_records)::16>>,
          sub_records
        ]
      end)
    end
  end
end
