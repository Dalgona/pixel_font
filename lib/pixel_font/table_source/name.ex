defmodule PixelFont.TableSource.Name do
  alias PixelFont.CompiledTable

  @spec compile(map(), integer()) :: CompiledTable.t()
  def compile(map, format)

  def compile(map, 0) do
    records = prepare_records(map)
    data_offset = 6 + 12 * length(records)

    {_, name_records, name_data} =
      Enum.reduce(records, {0, [], []}, fn record, state ->
        {pos, records, data} = state
        {platform, enc, lang, name, value} = record
        size = byte_size(value)

        record = [
          <<platform::16, enc::16, lang::16, name::16>>,
          <<size::16>>,
          <<pos::16>>
        ]

        {pos + size, [record | records], [value | data]}
      end)

    data = [
      <<0::16>>,
      <<length(name_records)::16>>,
      <<data_offset::16>>,
      Enum.reverse(name_records),
      Enum.reverse(name_data)
    ]

    CompiledTable.new("name", IO.iodata_to_binary(data))
  end

  @spec prepare_records(map()) :: list()
  defp prepare_records(maps) do
    maps
    |> Enum.map(fn map ->
      platform = map.platform

      Enum.map(map.records, fn {name_id, data} ->
        {platform, map.encoding, map.language, name_id, get_encoded_data(data, platform)}
      end)
    end)
    |> List.flatten()
    |> Enum.sort()
  end

  @spec get_encoded_data(binary(), integer()) :: binary()
  defp get_encoded_data(data, platform)

  # Return the input data as-is on macintosh platform.
  defp get_encoded_data(data, 1), do: data

  defp get_encoded_data(data, _) do
    :unicode.characters_to_binary(data, :utf8, {:utf16, :big})
  end
end
