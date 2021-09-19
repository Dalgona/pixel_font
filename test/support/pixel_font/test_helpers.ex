defmodule PixelFont.TestHelpers do
  @spec to_wordstring(iodata()) :: binary()
  def to_wordstring(iodata) do
    iodata
    |> List.flatten()
    |> Enum.map(fn
      word when word in -32768..65535 -> <<word::16>>
      binary when is_binary(binary) -> binary
    end)
    |> IO.iodata_to_binary()
  end
end
