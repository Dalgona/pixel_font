defmodule PixelFont.DSL.OTFLayout.Lookups.GPOS do
  @moduledoc false

  import PixelFont.DSL.MacroHelper
  alias PixelFont.DSL.OTFLayout.Lookups.Common
  alias PixelFont.TableSource.GPOS
  alias PixelFont.TableSource.GPOS.ChainingContext3
  alias PixelFont.TableSource.GPOS.SingleAdjustment1
  alias PixelFont.TableSource.GPOS.ValueRecord
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage

  @spec lookup(atom(), Macro.t(), do: Macro.t()) :: Macro.t()
  defmacro lookup(type, name, do: do_block) do
    Common.__lookup__(__MODULE__, GPOS, type, name, do_block)
  end

  @spec __handle_lookup__(atom()) :: Common.lookup_attrs()
  def __handle_lookup__(type)

  def __handle_lookup__(:single_adjustment) do
    %{
      imports: [adjust_uniform: 2],
      type: 1,
      ast_transform: & &1,
      runtime_transform: & &1
    }
  end

  def __handle_lookup__(:chained_context) do
    %{
      imports: [context__8: 1],
      type: 8,
      ast_transform: &replace_call(&1, :context, 1, :context__8),
      runtime_transform: & &1
    }
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
        import Common, only: [backtrack: 1, input: 1, input: 2, lookahead: 1]

        Common.__make_chained_ctx_subtable__(
          unquote(get_exprs(do_block)),
          ChainingContext3,
          :positions
        )
      end
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
