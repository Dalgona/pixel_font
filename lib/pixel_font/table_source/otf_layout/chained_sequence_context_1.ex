defmodule PixelFont.TableSource.OTFLayout.ChainedSequenceContext1 do
  require PixelFont.Util, as: Util
  import Util, only: :macros
  alias PixelFont.Glyph
  alias PixelFont.TableSource.GPOSGSUB
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage
  alias PixelFont.TableSource.OTFLayout.Lookup

  @type rulesets :: %{optional(Glyph.id()) => ruleset()}
  @type ruleset :: [rule()]

  @type rule :: %{
          backtrack: [Glyph.id()],
          input: [Glyph.id()],
          lookahead: [Glyph.id()],
          lookup_records: [{integer(), Lookup.id()}]
        }

  @spec compile(rulesets(), GPOSGSUB.lookup_indices()) :: binary()
  def compile(ruleset, lookup_indices) do
    ruleset_count = map_size(ruleset)

    {glyphs, rulesets} =
      ruleset
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
      # chainedSeqRuleSetCount
      <<ruleset_count::16>>,
      # chainedSeqRuleSetOffsets[]
      offsets,
      # Coverage table
      coverage,
      # Chained sequence ruleset tables
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
      # chainedSeqRuleCount
      <<rule_count::16>>,
      # chainedSeqRuleOffsets[]
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
      # backtrackGlyphCount
      <<length(rule.backtrack)::16>>,
      # backtrackSequence[]
      Enum.map(rule.backtrack, &<<gid!(&1)::16>>),
      # inputGlyphCount
      <<length(rule.input) + 1::16>>,
      # inputSequence[]
      Enum.map(rule.input, &<<gid!(&1)::16>>),
      # lookaheadGlyphCount
      <<length(rule.lookahead)::16>>,
      # lookaheadSequence[]
      Enum.map(rule.lookahead, &<<gid!(&1)::16>>),
      # seqLookupCount
      <<length(compiled_lookup_records)>>,
      # seqLookupRecords[]
      compiled_lookup_records
    ]
  end
end
