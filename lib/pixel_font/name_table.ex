defmodule PixelFont.NameTable do
  require PixelFont.TableSource.Name.Definitions, as: Defs
  import PixelFont.DSL.MacroHelper

  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__), only: [name_table: 2]
    end
  end

  @spec name_table(module(), do: Macro.t()) :: Macro.t()
  defmacro name_table(name, do: do_block) do
    quote do
      defmodule unquote(name) do
        unquote(import_exit())

        @name_records []
        unquote(do_block)
        @name_records Enum.reverse(@name_records)

        def name_table do
          @name_records
        end
      end
    end
  end

  @spec name_records([language: binary()], do: Macro.t()) :: Macro.t()
  defmacro name_records([language: lang], do: do_block) when is_binary(lang) do
    records_expr =
      quote do
        %{
          platform: 3,
          encoding: 1,
          language: Defs.windows_lang_id(unquote(lang)),
          records: unquote(do_block |> get_exprs() |> elem(0))
        }
      end

    quote do
      unquote(import_enter())
      @name_records [unquote(records_expr) | @name_records]
      unquote(import_exit())
    end
  end

  name_ids = Defs.name_ids()
  last_id = name_ids |> Map.values() |> Enum.max()
  macro_arities = [{:font_specific_name, 2} | Enum.map(name_ids, &{elem(&1, 0), 1})]

  Enum.each(name_ids, fn {name, name_id} ->
    @spec unquote(name)(term()) :: Macro.t()
    defmacro unquote(name)(value), do: {unquote(name_id), value}
  end)

  @spec font_specific_name(integer(), term()) :: Macro.t()
  defmacro font_specific_name(id, value)

  defmacro font_specific_name(id, _value) when id in 0..unquote(last_id) do
    raise "name IDs between 0 and #{unquote(last_id)} " <>
            "should be accessed through predefined macros"
  end

  defmacro font_specific_name(id, _value) when id in (unquote(last_id) + 1)..255 do
    raise "name IDs between #{unquote(last_id) + 1} and 255 " <>
            "are reserved for future uses, and must not be used"
  end

  defmacro font_specific_name(id, value), do: {id, value}

  @spec import_enter() :: Macro.t()
  defp import_enter do
    {:import, [], [__MODULE__, [only: unquote(macro_arities)]]}
  end

  @spec import_exit() :: Macro.t()
  defp import_exit do
    quote do
      import unquote(__MODULE__), only: [name_records: 2]
    end
  end
end
