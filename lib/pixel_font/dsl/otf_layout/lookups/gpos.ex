defmodule PixelFont.DSL.OTFLayout.Lookups.GPOS do
  @moduledoc false

  import PixelFont.DSL.MacroHelper
  alias PixelFont.TableSource.GPOS
  alias PixelFont.TableSource.GPOS.ChainingContext3
  alias PixelFont.TableSource.GPOS.SingleAdjustment1
  alias PixelFont.TableSource.GPOS.ValueRecord
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage
  alias PixelFont.TableSource.OTFLayout.Lookup

  @typep sequence :: {seq_type(), [Glyph.id()], term()}
  @typep seq_type :: :backtrack | :input | :lookahead

  # TODO: remove duplicate codes
  @spec lookup(atom(), Macro.t(), do: Macro.t()) :: Macro.t()
  defmacro lookup(type, name, do: do_block) do
    expr_groups =
      do_block
      |> get_exprs()
      |> Enum.group_by(fn
        {:feature, _, [_, _]} -> :features
        _ -> :others
      end)

    features =
      expr_groups[:features]
      |> List.wrap()
      |> Enum.map(fn {:feature, _, [tag, scripts]} -> {tag, scripts} end)

    feature_expr = {:%{}, [], features}

    handle_lookup(type, name, feature_expr, expr_groups[:others] || [])
  end

  # TODO: remove duplicate codes
  @spec feature(Macro.t(), Macro.t()) :: no_return()
  defmacro feature(_tag, _scripts), do: block_direct_invocation!(__CALLER__)

  @spec handle_lookup(atom(), Macro.t(), Macro.t(), [Macro.t()]) :: Macro.t()
  defp handle_lookup(type, name, features_expr, exprs)

  defp handle_lookup(:single_adjustment, name, features_expr, exprs) do
    quote do
      if true do
        import unquote(__MODULE__), only: [adjust_uniform: 2]

        %Lookup{
          owner: GPOS,
          type: 1,
          name: unquote(name),
          subtables:
            unquote(exprs)
            |> List.flatten()
            |> Enum.reject(&is_nil/1),
          features: unquote(features_expr)
        }
      end
    end
  end

  defp handle_lookup(:chained_context, name, features_expr, exprs) do
    exprs = replace_call(exprs, :context, 1, :context__8)

    quote do
      if true do
        import unquote(__MODULE__), only: [context__8: 1]

        %Lookup{
          owner: GPOS,
          type: 8,
          name: unquote(name),
          subtables:
            unquote(exprs)
            |> List.flatten()
            |> Enum.reject(&is_nil/1),
          features: unquote(features_expr)
        }
      end
    end
  end

  @spec adjust_uniform(Macro.t(), keyword()) :: Macro.t()
  defmacro adjust_uniform(glyphs, adjustment) do
    quote do
      unquote(__MODULE__).__make_single_1_subtable__(unquote(glyphs), unquote(adjustment))
    end
  end

  @spec context(Macro.t()) :: no_return()
  defmacro context(_), do: block_direct_invocation!(__CALLER__)

  defmacro context__8(do: do_block) do
    quote do
      if true do
        import unquote(__MODULE__), only: [backtrack: 1, input: 1, input: 2, lookahead: 1]

        unquote(__MODULE__).__make_chained_ctx_subtable__(unquote(get_exprs(do_block)))
      end
    end
  end

  # TODO: remove duplicate codes
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
  @spec __make_single_1_subtable__(GlyphCoverage.source(), keyword()) :: SingleAdjustment1.t()
  def __make_single_1_subtable__(glyphs, adjustment) when is_list(adjustment) do
    %SingleAdjustment1{
      glyphs: GlyphCoverage.of(glyphs),
      value_format: Keyword.keys(adjustment),
      value: struct!(ValueRecord, adjustment)
    }
  end

  # TODO: remove duplicate codes
  @doc false
  @spec __make_chained_ctx_subtable__([sequence()]) :: ChainingContext3.t()
  def __make_chained_ctx_subtable__(context) do
    seq_group =
      context
      |> Enum.map(fn {type, glyphs, lookup} ->
        {type, GlyphCoverage.of(glyphs), lookup}
      end)
      |> Enum.group_by(&elem(&1, 0), &Tuple.delete_at(&1, 0))

    input_seq = seq_group[:input] || []

    %ChainingContext3{
      backtrack: Enum.map(seq_group[:backtrack] || [], &elem(&1, 0)),
      input: Enum.map(input_seq, &elem(&1, 0)),
      lookahead: Enum.map(seq_group[:lookahead] || [], &elem(&1, 0)),
      positions:
        input_seq
        |> Enum.with_index()
        |> Enum.reject(fn {{_cov, lookup}, _idx} -> is_nil(lookup) end)
        |> Enum.map(fn {{_cov, lookup}, index} -> {index, lookup} end)
    }
  end
end