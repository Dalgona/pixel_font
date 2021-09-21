defmodule PixelFont.TableSource.OTFLayout.SequenceContext2 do
  alias PixelFont.TableSource.GPOSGSUB
  alias PixelFont.TableSource.OTFLayout.ClassDefinition
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage
  alias PixelFont.TableSource.OTFLayout.Lookup
  alias PixelFont.Util

  defstruct input_classes: %ClassDefinition{},
            rulesets: %{}

  @type t :: %__MODULE__{
          input_classes: ClassDefinition.t(),
          rulesets: rulesets()
        }

  @type rulesets :: %{optional(integer()) => ruleset()}
  @type ruleset :: [rule()]

  @type rule :: %{
          input: [integer()],
          lookup_records: [{integer(), Lookup.id()}]
        }

  @spec compile(t(), keyword()) :: binary()
  def compile(subtable, opts) do
    lookup_indices = opts[:lookup_indices]
    input_classes = subtable.input_classes

    coverage =
      input_classes.assignments
      |> Map.values()
      |> GlyphCoverage.of()
      |> GlyphCoverage.compile()

    max_input_class = input_classes.assignments |> Map.keys() |> Enum.max()
    coverage_offset = 10 + max_input_class * 2
    class_def_offset = coverage_offset + byte_size(coverage)
    compiled_class_def = ClassDefinition.compile(subtable.input_classes)
    ruleset_offset_base = class_def_offset + byte_size(compiled_class_def)

    {ruleset_offsets, compiled_rulesets} =
      compile_class_rulesets(
        subtable.rulesets,
        ruleset_offset_base,
        max_input_class,
        lookup_indices
      )

    IO.iodata_to_binary([
      # format
      <<2::16>>,
      # coverageOffset
      <<coverage_offset::16>>,
      # classDefOffset
      <<class_def_offset::16>>,
      # classSeqRuleSetCount
      <<max_input_class + 1::16>>,
      # classSeqRuleSetOffsets[]
      ruleset_offsets,
      # Coverage table
      coverage,
      # Input class definition table
      compiled_class_def,
      # Class sequence ruleset tables
      compiled_rulesets
    ])
  end

  @spec compile_class_rulesets(
          rulesets(),
          non_neg_integer(),
          non_neg_integer(),
          GPOSGSUB.lookup_indices()
        ) :: {iodata(), iodata()}
  defp compile_class_rulesets(rulesets, offset_base, max_input_class, lookup_indices) do
    compiled_rulesets =
      0..max_input_class
      |> Enum.map(&rulesets[&1])
      |> Enum.map(&compile_class_ruleset(&1, lookup_indices))

    ruleset_offsets =
      compiled_rulesets
      |> Enum.reduce({offset_base, []}, fn
        "", {pos, offsets} -> {pos, [<<0::16>> | offsets]}
        ruleset, {pos, offsets} -> {pos + byte_size(ruleset), [<<pos::16>> | offsets]}
      end)
      |> elem(1)
      |> Enum.reverse()

    {ruleset_offsets, compiled_rulesets}
  end

  @spec compile_class_ruleset(ruleset() | nil, GPOSGSUB.lookup_indices()) :: iodata()
  defp compile_class_ruleset(rules, lookup_indices)
  defp compile_class_ruleset(nil, _lookup_indices), do: ""

  defp compile_class_ruleset(rules, lookup_indices) do
    rule_count = length(rules)
    rule_offset_base = 2 + rule_count * 2

    {_, offsets, compiled_rules} =
      Util.offsetted_binaries(rules, rule_offset_base, &compile_class_rule(&1, lookup_indices))

    IO.iodata_to_binary([
      # chainedClassSeqRuleCount
      <<rule_count::16>>,
      # chainedClassSeqRuleOffsets[]
      offsets,
      #  class sequence rule tables
      compiled_rules
    ])
  end

  @spec compile_class_rule(rule(), GPOSGSUB.lookup_indices()) :: iodata()
  defp compile_class_rule(rule, lookup_indices) do
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
      Enum.map(rule.input, &<<&1::16>>),
      # seqLookupRecords[]
      compiled_lookup_records
    ]
  end

  defimpl PixelFont.TableSource.GPOS.Subtable do
    alias PixelFont.TableSource.OTFLayout.SequenceContext2

    defdelegate compile(subtable, opts), to: SequenceContext2
  end

  defimpl PixelFont.TableSource.GSUB.Subtable do
    alias PixelFont.TableSource.OTFLayout.SequenceContext2

    defdelegate compile(subtable, opts), to: SequenceContext2
  end
end
