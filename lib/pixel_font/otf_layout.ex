defmodule PixelFont.OTFLayout do
  @moduledoc false

  import PixelFont.DSL.MacroHelper

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__), only: [lookups: 3]
    end
  end

  @spec lookups(module(), [for: <<_::32>>], do: Macro.t()) :: Macro.t()
  defmacro lookups(name, [for: type], do: do_block) when type in ~w(GPOS GSUB) do
    import_module = Module.concat(PixelFont.DSL.OTFLayout.Lookups, type)
    exprs = get_exprs(do_block)
    {module_block, exprs} = handle_module(exprs, __CALLER__)

    quote do
      defmodule unquote(name) do
        require unquote(import_module)
        import unquote(__MODULE__), only: []
        import unquote(import_module), only: unquote(import_module.__import_items__())
        alias PixelFont.TableSource.OTFLayout.Lookup
        alias PixelFont.TableSource.OTFLayout.LookupList

        unquote(module_block)

        @spec lookups() :: [LookupList.t()]
        def lookups do
          %LookupList{
            lookups:
              unquote(exprs)
              |> List.flatten()
              |> Enum.reject(&is_nil/1)
          }
        end
      end
    end
  end
end
