defmodule PixelFont.DSL.OTFLayout.Lookups.GSUB do
  @moduledoc false

  require PixelFont.Util
  import PixelFont.DSL.MacroHelper
  import PixelFont.Util
  alias PixelFont.DSL.OTFLayout.Lookups.Common
  alias PixelFont.Glyph
  alias PixelFont.TableSource.GSUB
  alias PixelFont.TableSource.GSUB.Ligature1
  alias PixelFont.TableSource.GSUB.ReverseChainingContext1
  alias PixelFont.TableSource.GSUB.Single1
  alias PixelFont.TableSource.GSUB.Single2
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage

  @typep sub_record :: {Glyph.id(), Glyph.id()}

  @spec lookup(atom(), Macro.t(), do: Macro.t()) :: Macro.t()
  defmacro lookup(type, name, do: do_block) do
    Common.__lookup__(__MODULE__, GSUB, type, name, do_block)
  end

  @spec __handle_lookup__(atom()) :: Common.lookup_attrs()
  def __handle_lookup__(type)

  def __handle_lookup__(:single_substitution) do
    %{
      imports: [substitutions__1: 1],
      type: 1,
      ast_transform: &replace_call(&1, :substitutions, 1, :substitutions__1),
      runtime_transform: & &1
    }
  end

  def __handle_lookup__(:ligature) do
    %{
      imports: [substitutions__4: 1],
      type: 4,
      ast_transform: &replace_call(&1, :substitutions, 1, :substitutions__4),
      runtime_transform: & &1
    }
  end

  def __handle_lookup__(:chained_context) do
    %{
      imports: [context__6: 1],
      type: 6,
      ast_transform: &replace_call(&1, :context, 1, :context__6),
      runtime_transform: fn expr ->
        quote do
          Common.__try_convert_chain_format__(unquote(expr))
        end
      end
    }
  end

  def __handle_lookup__(:reverse_chaining_context) do
    %{
      imports: [context__8: 1],
      type: 8,
      ast_transform: &replace_call(&1, :context, 1, :context__8),
      runtime_transform: & &1
    }
  end

  @spec substitutions(Macro.t()) :: no_return()
  defmacro substitutions(_), do: block_direct_invocation!(__CALLER__)

  defmacro substitutions__1(do: do_block) do
    quote do
      (fn ->
         import unquote(__MODULE__), only: [substitute: 2]

         unquote(__MODULE__).__make_single_subtable__(unquote(get_exprs(do_block)))
       end).()
    end
  end

  defmacro substitutions__4(do: do_block) do
    quote do
      (fn ->
         import unquote(__MODULE__), only: [substitute: 2]

         %Ligature1{substitutions: unquote(get_exprs(do_block))}
       end).()
    end
  end

  @spec substitute(Macro.t(), Macro.t()) :: Macro.t()
  defmacro substitute(from_id, to_id), do: {from_id, to_id}

  @spec context(Macro.t()) :: no_return()
  defmacro context(_), do: block_direct_invocation!(__CALLER__)

  defmacro context__6(do: do_block) do
    quote do
      (fn ->
         import Common, only: [backtrack: 1, input: 1, input: 2, lookahead: 1]

         Common.__make_chained_ctx_subtable__(unquote(get_exprs(do_block)))
       end).()
    end
  end

  defmacro context__8(do: do_block) do
    quote do
      (fn ->
         import Common, only: [backtrack: 1, lookahead: 1]
         import unquote(__MODULE__), only: [substitute: 2]

         unquote(__MODULE__).__make_reverse_chaining_ctx_subtable__(unquote(get_exprs(do_block)))
       end).()
    end
  end

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

  @spec __make_reverse_chaining_ctx_subtable__([Common.sequence() | sub_record()]) ::
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
