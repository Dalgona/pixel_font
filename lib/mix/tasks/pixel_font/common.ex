defmodule Mix.Tasks.PixelFont.Common do
  @moduledoc false

  alias PixelFont.Font

  @spec get_font([binary()]) :: Font.t()
  def get_font(args) do
    mix_project = Mix.Project.get!().project()
    pixel_font_opts = Keyword.fetch!(mix_project, :pixel_font)
    font_module = Keyword.fetch!(pixel_font_opts, :font_module)
    %Font{} = font_module.font(args)
  end
end
