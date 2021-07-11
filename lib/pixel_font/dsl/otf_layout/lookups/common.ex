defmodule PixelFont.DSL.OTFLayout.Lookups.Common do
  @moduledoc false

  import PixelFont.DSL.MacroHelper
  alias PixelFont.Glyph
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

  @spec __make_chained_ctx_subtable__([sequence()], module(), atom()) :: struct()
  def __make_chained_ctx_subtable__(context, struct_module, apply_key) do
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

    struct_fields = [
      {apply_key, apply},
      backtrack: Enum.map(seq_group[:backtrack] || [], &elem(&1, 0)),
      input: Enum.map(input_seq, &elem(&1, 0)),
      lookahead: Enum.map(seq_group[:lookahead] || [], &elem(&1, 0))
    ]

    struct!(struct_module, struct_fields)
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
end
