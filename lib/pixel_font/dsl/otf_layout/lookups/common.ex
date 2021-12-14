defmodule PixelFont.DSL.OTFLayout.Lookups.Common do
  @moduledoc false

  import PixelFont.DSL.MacroHelper
  alias PixelFont.Glyph
  alias PixelFont.TableSource.OTFLayout.ChainedSequenceContext1
  alias PixelFont.TableSource.OTFLayout.ChainedSequenceContext3
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage
  alias PixelFont.TableSource.OTFLayout.Lookup

  @type lookup_attrs :: %{
          imports: [{atom(), arity()}],
          type: integer(),
          ast_transform: (Macro.t() -> Macro.t()),
          runtime_transform: (Macro.t() -> Macro.t())
        }

  @type sequence :: {seq_type(), [Glyph.id()], term()}
  @type seq_type :: :backtrack | :input | :lookahead

  @spec __lookup__(module(), module(), atom(), Macro.t(), Macro.t()) :: Macro.t()
  def __lookup__(dsl_module, owner, type, name, do_block) do
    expr_groups =
      do_block
      |> get_exprs()
      |> elem(0)
      |> Enum.group_by(fn
        {:feature, _, [_, _]} -> :features
        _ -> :others
      end)

    features =
      expr_groups[:features]
      |> List.wrap()
      |> Enum.map(fn {:feature, _, [tag, scripts]} -> {tag, scripts} end)

    lookup_attrs = dsl_module.__handle_lookup__(type)
    exprs = lookup_attrs.ast_transform.(expr_groups[:others] || [])
    features_expr = {:%{}, [], features}

    subtables_expr =
      quote do
        unquote(exprs)
        |> List.flatten()
        |> Enum.reject(&is_nil/1)
      end

    quote do
      (fn ->
         import unquote(__MODULE__), only: [feature: 2]
         import unquote(dsl_module), only: unquote(lookup_attrs.imports)

         %Lookup{
           owner: unquote(owner),
           type: unquote(lookup_attrs.type),
           name: unquote(name),
           subtables: unquote(lookup_attrs.runtime_transform.(subtables_expr)),
           features: unquote(features_expr)
         }
       end).()
    end
  end

  @spec __make_chained_ctx_subtable__([sequence()]) :: struct()
  def __make_chained_ctx_subtable__(context) do
    seq_group =
      context
      |> Enum.map(fn {type, glyphs, lookup} ->
        {type, GlyphCoverage.of(glyphs), lookup}
      end)
      |> Enum.group_by(&elem(&1, 0), &Tuple.delete_at(&1, 0))

    input_seq = seq_group[:input] || []

    apply =
      input_seq
      |> Enum.with_index()
      |> Enum.reject(fn {{_cov, lookup}, _idx} -> is_nil(lookup) end)
      |> Enum.map(fn {{_cov, lookup}, index} -> {index, lookup} end)

    %ChainedSequenceContext3{
      backtrack: Enum.map(seq_group[:backtrack] || [], &elem(&1, 0)),
      input: Enum.map(input_seq, &elem(&1, 0)),
      lookahead: Enum.map(seq_group[:lookahead] || [], &elem(&1, 0)),
      lookup_records: apply
    }
  end

  @spec feature(Macro.t(), Macro.t()) :: no_return()
  defmacro feature(_tag, _scripts), do: block_direct_invocation!(__CALLER__)

  @spec backtrack(Macro.t()) :: Macro.t()
  defmacro backtrack(glyphs), do: quote(do: {:backtrack, unquote(glyphs), nil})

  @spec input(Macro.t()) :: Macro.t()
  @spec input(Macro.t(), keyword()) :: Macro.t()
  defmacro input(glyphs, options \\ []) do
    quote do: {:input, unquote(glyphs), unquote(options)[:apply]}
  end

  @spec lookahead(Macro.t()) :: Macro.t()
  defmacro lookahead(glyphs), do: quote(do: {:lookahead, unquote(glyphs), nil})

  @doc false
  @spec __try_convert_chain_format__([ChainedSequenceContext3.t()]) ::
          [ChainedSequenceContext1.t() | ChainedSequenceContext3.t()]
  def __try_convert_chain_format__(subtables) do
    if Enum.all?(subtables, &simple_context?/1) do
      [convert_to_format_1(subtables)]
    else
      subtables
    end
  end

  @spec simple_context?(ChainedSequenceContext3.t()) :: boolean()
  defp simple_context?(subtable) do
    ~w(backtrack input lookahead)a
    |> Enum.map(&Map.get(subtable, &1))
    |> Enum.all?(&singleton_sequence?/1)
  end

  @spec singleton_sequence?([GlyphCoverage.t()]) :: boolean()
  defp singleton_sequence?(seq), do: Enum.all?(seq, &singleton_coverage?/1)

  @spec singleton_coverage?(GlyphCoverage.t()) :: boolean()
  defp singleton_coverage?(coverage), do: length(coverage.glyphs) === 1

  @spec convert_to_format_1([ChainedSequenceContext3.t()]) :: ChainedSequenceContext1.t()
  defp convert_to_format_1(subtables) do
    rulesets =
      subtables
      |> Enum.group_by(&hd(hd(&1.input).glyphs), fn subtable ->
        %{
          backtrack: flatten_sequence(subtable.backtrack),
          input: flatten_sequence(tl(subtable.input)),
          lookahead: flatten_sequence(subtable.lookahead),
          lookup_records: subtable.lookup_records
        }
      end)

    %ChainedSequenceContext1{rulesets: rulesets}
  end

  @spec flatten_sequence([GlyphCoverage.t()]) :: [Glyph.id()]
  defp flatten_sequence(sequence), do: Enum.map(sequence, &hd(&1.glyphs))
end
