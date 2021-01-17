defmodule PixelFont.DSL.OTFLayout.Lookups.GPOS do
  @moduledoc false

  import PixelFont.DSL.MacroHelper
  alias PixelFont.TableSource.GPOS
  alias PixelFont.TableSource.GPOS.SingleAdjustment1
  alias PixelFont.TableSource.GPOS.ValueRecord
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage
  alias PixelFont.TableSource.OTFLayout.Lookup

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

  @spec adjust_uniform(Macro.t(), keyword()) :: Macro.t()
  defmacro adjust_uniform(glyphs, adjustment) do
    quote do
      unquote(__MODULE__).__make_single_1_subtable__(unquote(glyphs), unquote(adjustment))
    end
  end

  @doc false
  @spec __make_single_1_subtable__(GlyphCoverage.source(), keyword()) :: SingleAdjustment1.t()
  def __make_single_1_subtable__(glyphs, adjustment) when is_list(adjustment) do
    %SingleAdjustment1{
      glyphs: GlyphCoverage.of(glyphs),
      value_format: Keyword.keys(adjustment),
      value: struct!(ValueRecord, adjustment)
    }
  end
end
