defmodule PixelFont.DSL.OTFLayout.Lookups.Common do
  @moduledoc false

  import PixelFont.DSL.MacroHelper
  alias PixelFont.TableSource.OTFLayout.Lookup

  @type lookup_attrs :: %{
          imports: [{atom(), arity()}],
          type: integer(),
          ast_transform: (Macro.t() -> Macro.t()),
          runtime_transform: (Macro.t() -> Macro.t())
        }

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
      if true do
        import unquote(__MODULE__), only: [feature: 2]
        import unquote(dsl_module), only: unquote(lookup_attrs.imports)

        %Lookup{
          owner: unquote(owner),
          type: unquote(lookup_attrs.type),
          name: unquote(name),
          subtables: unquote(lookup_attrs.runtime_transform.(subtables_expr)),
          features: unquote(features_expr)
        }
      end
    end
  end

  @spec feature(Macro.t(), Macro.t()) :: no_return()
  defmacro feature(_tag, _scripts), do: block_direct_invocation!(__CALLER__)
end
