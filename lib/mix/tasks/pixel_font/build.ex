defmodule Mix.Tasks.PixelFont.Build do
  use Mix.Task
  alias Mix.Tasks.PixelFont.Common
  alias PixelFont.Builder
  alias PixelFont.Font
  alias PixelFont.TableSource.Name.Definitions, as: Defs

  @impl true
  def run(args) do
    Mix.Task.run("compile")

    font = Common.get_font(args)
    ttf = Builder.build_ttf(font)

    "#{output_filename(font)}.ttf"
    |> Path.expand(File.cwd!())
    |> File.open([:write, :binary], &IO.binwrite(&1, ttf))
  end

  defp output_filename(%Font{} = font) do
    font.name_table
    |> hd()
    |> Map.get(:records)
    |> Enum.find(&(elem(&1, 0) === Defs.name_id(:postscript_name)))
    |> case do
      nil -> "font"
      {_name_id, font_name} when is_binary(font_name) -> font_name
    end
  end
end
