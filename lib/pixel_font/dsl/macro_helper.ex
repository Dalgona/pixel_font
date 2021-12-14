defmodule PixelFont.DSL.MacroHelper do
  @moduledoc false

  @doc false
  @spec block_direct_invocation!(Macro.Env.t()) :: no_return()
  def block_direct_invocation!(env) do
    raise CompileError,
      file: env.file,
      line: env.line,
      description: "this macro cannot be called directly"
  end

  @typep exprs :: [Macro.t()]

  @doc false
  @spec get_exprs(Macro.t(), keyword()) :: {exprs(), Macro.t()}
  def get_exprs(do_block, options \\ [])
  def get_exprs({:__block__, _, exprs}, options), do: do_get_exprs(exprs, options)
  def get_exprs(expr, options), do: do_get_exprs([expr], options)

  @spec do_get_exprs(exprs(), keyword(), {exprs(), exprs()}) :: {exprs(), Macro.t()}
  defp do_get_exprs(exprs, options, acc \\ {[], []})
  defp do_get_exprs(exprs, [], {[], []}), do: {exprs, {:__block__, [], [nil]}}
  defp do_get_exprs([], _, {exprs, []}), do: {Enum.reverse(exprs), {:__block__, [], [nil]}}

  defp do_get_exprs([], _, {exprs, other}) do
    {Enum.reverse(exprs), {:__block__, [], Enum.reverse(other)}}
  end

  defp do_get_exprs([expr | exprs], options, {filtered, other}) do
    expected = Keyword.fetch!(options, :expected)
    warn = options[:warn] || false

    new_acc =
      case expr do
        {fun_name, _, args} when is_list(args) ->
          if fun_name in expected do
            {[expr | filtered], other}
          else
            warn_unexpected_expr(expr, warn)

            {filtered, [expr | other]}
          end

        _ ->
          warn_unexpected_expr(expr, warn)

          {filtered, [expr | other]}
      end

    do_get_exprs(exprs, options, new_acc)
  end

  @spec warn_unexpected_expr(Macro.t(), boolean()) :: :ok
  defp warn_unexpected_expr(expr, warn)
  defp warn_unexpected_expr(_, false), do: :ok

  defp warn_unexpected_expr(expr, true) do
    [
      "unexpected expression in block: \n",
      :bright,
      :cyan,
      Macro.to_string(expr),
      :reset,
      "\nthis expression will be ignored"
    ]
    |> IO.ANSI.format()
    |> IO.warn()
  end

  @doc false
  @spec replace_call(Macro.t(), atom(), arity(), atom()) :: Macro.t()
  def replace_call(ast, from_name, arity, to_name) do
    Macro.prewalk(ast, fn
      {^from_name, meta, args} when length(args) === arity -> {to_name, meta, args}
      expr -> expr
    end)
  end

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
