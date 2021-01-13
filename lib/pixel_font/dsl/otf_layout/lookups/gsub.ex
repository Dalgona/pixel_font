defmodule PixelFont.DSL.OTFLayout.Lookups.GSUB do
  @moduledoc false

  require PixelFont.Util
  import PixelFont.DSL.MacroHelper
  import PixelFont.Util
  alias PixelFont.Glyph
  alias PixelFont.TableSource.GSUB
  alias PixelFont.TableSource.GSUB.ChainingContext3
  alias PixelFont.TableSource.GSUB.Single1
  alias PixelFont.TableSource.GSUB.Single2
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage
  alias PixelFont.TableSource.OTFLayout.Lookup

  @doc false
  @spec __import_items__() :: [{atom(), arity()}]
  def __import_items__ do
    [
      single_substitution: 2,
      chained_context: 2
    ]
  end

  defmacro single_substitution(name, do: do_block) do
    quote do
      if true do
        import unquote(__MODULE__), only: [substitutions: 1]

        %Lookup{
          owner: GSUB,
          type: 1,
          name: unquote(name),
          subtables:
            unquote(get_exprs(do_block))
            |> List.flatten()
            |> Enum.reject(&is_nil/1)
        }
      end
    end
  end

  defmacro chained_context(name, do: do_block) do
    exprs = do_block |> get_exprs() |> replace_call(:context, 1, :context__6)

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

  defmacro context(_), do: block_direct_invocation!(__CALLER__)

  defmacro context__6(do: do_block) do
    quote do
      if true do
        import unquote(__MODULE__), only: [backtrack: 1, input: 1, input: 2, lookahead: 1]

        unquote(__MODULE__).__make_chained_ctx_subtable__(unquote(get_exprs(do_block)))
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
  @spec __make_single_subtable__([{Glyph.id(), Glyph.id()}]) :: Single1.t() | Single2.t()
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
  @spec __make_chained_ctx_subtable__([{atom(), Glyph.id(), term()}]) :: ChainingContext3.t()
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
end
