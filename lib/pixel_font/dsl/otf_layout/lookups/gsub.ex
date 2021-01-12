defmodule PixelFont.DSL.OTFLayout.Lookups.GSUB do
  @moduledoc false

  require PixelFont.Util
  import PixelFont.DSL.MacroHelper
  import PixelFont.Util
  alias PixelFont.Glyph
  alias PixelFont.TableSource.GSUB
  alias PixelFont.TableSource.GSUB.Single1
  alias PixelFont.TableSource.GSUB.Single2
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage
  alias PixelFont.TableSource.OTFLayout.Lookup

  @doc false
  @spec __import_items__() :: [{atom(), arity()}]
  def __import_items__ do
    [
      single_substitution: 2
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
end
