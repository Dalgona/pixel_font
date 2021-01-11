defmodule PixelFont.DSL.MacroHelper do
  @moduledoc false

  @doc false
  @spec get_exprs(Macro.t()) :: [Macro.t()]
  def get_exprs(do_block)
  def get_exprs({:__block__, _, exprs}), do: exprs
  def get_exprs(expr), do: [expr]

  @doc false
  @spec handle_module(Macro.t(), Macro.Env.t()) :: {Macro.t(), [Macro.t()]}
  def handle_module(exprs, env) do
    {module_exprs, other_exprs} =
      Enum.reduce(exprs, {[], []}, fn
        {:module, _, [[do: module_do]]}, {modules, others} ->
          {[module_do | modules], others}

        expr, {modules, others} ->
          {modules, [expr | others]}
      end)

    module_block = {:__block__, [], handle_module_exprs(module_exprs, env)}

    {module_block, Enum.reverse(other_exprs)}
  end

  @spec handle_module_exprs([Macro.t()], Macro.Env.t()) :: Macro.t()
  defp handle_module_exprs(module_exprs, env) do
    module_exprs
    |> Enum.reverse()
    |> Enum.map(&get_exprs/1)
    |> List.flatten()
    |> Macro.prewalk(fn
      {fun, meta, [{:lookups, _, _} | _]} when fun in ~w(def defp)a ->
        raise CompileError,
          file: env.file,
          line: meta[:line],
          description: "the function name `lookups` is reserved"

      expr ->
        expr
    end)
  end
end
