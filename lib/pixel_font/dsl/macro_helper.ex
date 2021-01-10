defmodule PixelFont.DSL.MacroHelper do
  @moduledoc false

  @doc false
  @spec get_exprs(Macro.t()) :: [Macro.t()]
  def get_exprs(do_block)
  def get_exprs({:__block__, _, exprs}), do: exprs
  def get_exprs(expr), do: [expr]
end
