defmodule PixelFont.TableSource.OTFLayout.SequenceContext1 do
  require PixelFont.Util, as: Util
  import Util, only: :macros
  alias PixelFont.Glyph
  alias PixelFont.TableSource.GPOSGSUB
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage
  alias PixelFont.TableSource.OTFLayout.Lookup

  defstruct rulesets: %{}

  @type t :: %__MODULE__{rulesets: rulesets()}
  @type rulesets :: %{optional(Glyph.id()) => ruleset()}
  @type ruleset :: [rule()]

  @type rule :: %{
          input: [Glyph.id()],
          lookup_records: [{integer(), Lookup.id()}]
        }

  def compile(%__MODULE__{rulesets: rulesets}, opts) do
    lookup_indices = opts[:lookup_indices]
    ruleset_count = map_size(rulesets)

    {glyphs, rulesets} =
      rulesets
      |> Enum.map(fn {glyph_id, rules} -> {gid!(glyph_id), rules} end)
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.unzip()

    coverage = glyphs |> GlyphCoverage.of() |> GlyphCoverage.compile(internal: true)
    coverage_offset = 6 + ruleset_count * 2
    offset_base = coverage_offset + byte_size(coverage)

    {_, offsets, compiled_rulesets} =
      Util.offsetted_binaries(rulesets, offset_base, &compile_ruleset(&1, lookup_indices))

    IO.iodata_to_binary([
      # format
      <<1::16>>,
      # coverageOffset
      <<coverage_offset::16>>,
      # seqRuleSetCount
      <<ruleset_count::16>>,
      # seqRuleSetOffsets[]
      offsets,
      # Coverage table
      coverage,
      # Sequence ruleset tables
      compiled_rulesets
    ])
  end

  @spec compile_ruleset(ruleset(), GPOSGSUB.lookup_indices()) :: iodata()
  defp compile_ruleset(rules, lookup_indices) do
    rule_count = length(rules)
    rule_offset_base = 2 + rule_count * 2

    {_, offsets, compiled_rules} =
      Util.offsetted_binaries(rules, rule_offset_base, &compile_rule(&1, lookup_indices))

    [
      # seqRuleCount
      <<rule_count::16>>,
      # seqRuleOffsets,
      offsets,
      # Sequence rule tables
      compiled_rules
    ]
  end

  @spec compile_rule(rule(), GPOSGSUB.lookup_indices()) :: iodata()
  defp compile_rule(rule, lookup_indices) do
    compiled_lookup_records =
      Enum.map(rule.lookup_records, fn {glyph_pos, lookup_id} ->
        <<glyph_pos::16, lookup_indices[lookup_id]::16>>
      end)

    [
      # glyphCount
      <<length(rule.input) + 1::16>>,
      # seqLookupCount
      <<length(compiled_lookup_records)::16>>,
      # inputSequence[]
      Enum.map(rule.input, &<<gid!(&1)::16>>),
      # seqLookupRecords[]
      compiled_lookup_records
    ]
  end

  defimpl PixelFont.TableSource.GPOS.Subtable do
    alias PixelFont.TableSource.OTFLayout.SequenceContext1

    defdelegate compile(subtable, opts), to: SequenceContext1
  end

  defimpl PixelFont.TableSource.GSUB.Subtable do
    alias PixelFont.TableSource.OTFLayout.SequenceContext1

    defdelegate compile(subtable, opts), to: SequenceContext1
  end
end
