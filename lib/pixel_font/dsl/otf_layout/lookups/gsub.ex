defmodule PixelFont.DSL.OTFLayout.Lookups.GSUB do
  @moduledoc false

  require PixelFont.Util
  import PixelFont.DSL.MacroHelper
  import PixelFont.Util
  alias PixelFont.Glyph
  alias PixelFont.TableSource.GSUB
  alias PixelFont.TableSource.GSUB.ChainingContext1
  alias PixelFont.TableSource.GSUB.ChainingContext3
  alias PixelFont.TableSource.GSUB.ReverseChainingContext1
  alias PixelFont.TableSource.GSUB.Single1
  alias PixelFont.TableSource.GSUB.Single2
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage
  alias PixelFont.TableSource.OTFLayout.Lookup

  @typep sub_record :: {Glyph.id(), Glyph.id()}
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

  defp handle_lookup(:single_substitution, name, features_expr, exprs) do
    quote do
      if true do
        import unquote(__MODULE__), only: [substitutions: 1]

        %Lookup{
          owner: GSUB,
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
    exprs = replace_call(exprs, :context, 1, :context__6)

    quote do
      if true do
        import unquote(__MODULE__), only: [context__6: 1]

        %Lookup{
          owner: GSUB,
          type: 6,
          name: unquote(name),
          subtables:
            unquote(exprs)
            |> List.flatten()
            |> Enum.reject(&is_nil/1)
            |> unquote(__MODULE__).__try_convert_chain_format__(),
          features: unquote(features_expr)
        }
      end
    end
  end

  defp handle_lookup(:reverse_chaining_context, name, features_expr, exprs) do
    exprs = replace_call(exprs, :context, 1, :context__8)

    quote do
      if true do
        import unquote(__MODULE__), only: [context__8: 1]

        %Lookup{
          owner: GSUB,
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

  defmacro substitutions(do: do_block) do
    quote do
      if true do
        import unquote(__MODULE__), only: [substitute: 2]

        unquote(__MODULE__).__make_single_subtable__(unquote(get_exprs(do_block)))
      end
    end
  end

  @spec substitute(Macro.t(), Macro.t()) :: Macro.t()
  defmacro substitute(from_id, to_id), do: {from_id, to_id}

  @spec context(Macro.t()) :: no_return()
  defmacro context(_), do: block_direct_invocation!(__CALLER__)

  defmacro context__6(do: do_block) do
    quote do
      if true do
        import unquote(__MODULE__), only: [backtrack: 1, input: 1, input: 2, lookahead: 1]

        unquote(__MODULE__).__make_chained_ctx_subtable__(unquote(get_exprs(do_block)))
      end
    end
  end

  defmacro context__8(do: do_block) do
    quote do
      if true do
        import unquote(__MODULE__), only: [backtrack: 1, lookahead: 1, substitute: 2]

        unquote(__MODULE__).__make_reverse_chaining_ctx_subtable__(unquote(get_exprs(do_block)))
      end
    end
  end

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
  @spec __make_single_subtable__([sub_record()]) :: Single1.t() | Single2.t()
  def __make_single_subtable__(substitutions) do
    subst_gids =
      substitutions
      |> List.flatten()
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn {from, to} -> {gid!(from), gid!(to)} end)

    subst_gids
    |> Enum.map(fn {from_gid, to_gid} -> to_gid - from_gid end)
    |> Enum.uniq()
    |> case do
      [diff] ->
        %Single1{
          gids: subst_gids |> Enum.map(&elem(&1, 0)) |> GlyphCoverage.of(),
          gid_diff: diff
        }

      [_ | _] ->
        %Single2{substitutions: subst_gids}
    end
  end

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
      substitutions:
        input_seq
        |> Enum.with_index()
        |> Enum.reject(fn {{_cov, lookup}, _idx} -> is_nil(lookup) end)
        |> Enum.map(fn {{_cov, lookup}, index} -> {index, lookup} end)
    }
  end

  @doc false
  @spec __try_convert_chain_format__([ChainingContext3.t()]) ::
          [ChainingContext1.t() | ChainingContext3.t()]
  def __try_convert_chain_format__(subtables) do
    if Enum.all?(subtables, &simple_context?/1) do
      [convert_to_format_1(subtables)]
    else
      subtables
    end
  end

  @spec simple_context?(ChainingContext3.t()) :: boolean()
  defp simple_context?(subtable) do
    ~w(backtrack input lookahead)a
    |> Enum.map(&Map.get(subtable, &1))
    |> Enum.all?(&singleton_sequence?/1)
  end

  @spec singleton_sequence?([GlyphCoverage.t()]) :: boolean()
  defp singleton_sequence?(seq), do: Enum.all?(seq, &singleton_coverage?/1)

  @spec singleton_coverage?(GlyphCoverage.t()) :: boolean()
  defp singleton_coverage?(coverage), do: length(coverage.glyphs) === 1

  @spec convert_to_format_1([ChainingContext3.t()]) :: ChainingContext1.t()
  defp convert_to_format_1(subtables) do
    subrulesets =
      subtables
      |> Enum.group_by(&hd(hd(&1.input).glyphs), fn subtable ->
        %{
          backtrack: flatten_sequence(subtable.backtrack),
          input: flatten_sequence(tl(subtable.input)),
          lookahead: flatten_sequence(subtable.lookahead),
          substitutions: subtable.substitutions
        }
      end)

    %ChainingContext1{subrulesets: subrulesets}
  end

  @spec flatten_sequence([GlyphCoverage.t()]) :: [Glyph.id()]
  defp flatten_sequence(sequence), do: Enum.map(sequence, &hd(&1.glyphs))

  @spec __make_reverse_chaining_ctx_subtable__([sequence() | sub_record()]) ::
          ReverseChainingContext1.t()
  def __make_reverse_chaining_ctx_subtable__(context) do
    {context, substitutions} =
      Enum.reduce(context, {[], []}, fn
        {_, _} = sub, {context, subs} -> {context, [sub | subs]}
        {_, _, _} = seq, {context, subs} -> {[seq | context], subs}
      end)

    seq_group =
      context
      |> Enum.reverse()
      |> Enum.map(fn {type, glyphs, lookup} ->
        {type, GlyphCoverage.of(glyphs), lookup}
      end)
      |> Enum.group_by(&elem(&1, 0), &Tuple.delete_at(&1, 0))

    %ReverseChainingContext1{
      backtrack: Enum.map(seq_group[:backtrack] || [], &elem(&1, 0)),
      lookahead: Enum.map(seq_group[:lookahead] || [], &elem(&1, 0)),
      substitutions: Enum.reverse(substitutions)
    }
  end
end
