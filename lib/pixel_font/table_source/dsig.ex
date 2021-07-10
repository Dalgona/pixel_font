defmodule PixelFont.TableSource.DSIG do
  alias PixelFont.CompiledTable

  def compile_dummy do
    data = [
      # version
      <<1::32>>,
      # numSignatures
      <<0::16>>,
      # flags
      <<0::16>>,
      # signatureRecords[]
      []
    ]

    CompiledTable.new("DSIG", IO.iodata_to_binary(data))
  end
end
