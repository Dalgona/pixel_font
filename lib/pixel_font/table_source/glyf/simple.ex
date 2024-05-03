defmodule PixelFont.TableSource.Glyf.Simple do
  alias PixelFont.Font.Metrics
  alias PixelFont.RectilinearShape.Path, as: RSPath

  defstruct ~w(last_points inst_size inst flags x_coords y_coords)a

  @type t :: %__MODULE__{
          last_points: [integer()],
          inst_size: 0x0000..0xFFFF,
          inst: binary(),
          flags: [0x00..0xFF],
          x_coords: [0x0000..0xFFFF],
          y_coords: [0x0000..0xFFFF]
        }

  @spec new(RSPath.t(), Metrics.t()) :: t()
  def new(path, %Metrics{} = metrics) do
    {_, last_points, contours} =
      path
      |> scale(metrics)
      |> make_relative()
      |> Enum.reduce({0, [], []}, fn contour, {pos, last_points, coords} ->
        len = length(contour)

        {pos + len, [pos + len - 1 | last_points], [contour | coords]}
      end)

    {flags, coords} =
      contours
      |> Enum.reverse()
      |> List.flatten()
      |> Enum.map(fn {x, y} ->
        x_short_vector = short_vector?(x)
        y_short_vector = short_vector?(y)
        flag_bit_4 = same_or_positive_short?(x, x_short_vector)
        flag_bit_5 = same_or_positive_short?(y, y_short_vector)
        encoded_x = encode_coord(x, x_short_vector, flag_bit_4)
        encoded_y = encode_coord(y, y_short_vector, flag_bit_5)

        flag =
          <<
            # Bit 7 (MSB): (Reserved)
            0::1,
            # Bit 6: OVERLAP_SIMPLE
            0::1,
            # Bit 5:
            #   when bit 2 is 0: Y_IS_SAME
            #   when bit 2 is 1: POSITIVE_Y_SHORT_VECTOR
            flag_bit_5::1,
            # Bit 4:
            #   when bit 1 is 0: X_IS_SAME
            #   when bit 1 is 1: POSITIVE_X_SHORT_VECTOR
            flag_bit_4::1,
            # Bit 3: REPEAT_FLAG
            0::1,
            # Bit 2: Y_SHORT_VECTOR
            y_short_vector::1,
            # Bit 1: X_SHORT_VECTOR
            x_short_vector::1,
            # Bit 0 (LSB): ON_CURVE_POINT
            1::1
          >>

        {flag, {encoded_x, encoded_y}}
      end)
      |> Enum.unzip()

    {x_coords, y_coords} = Enum.unzip(coords)
    x_coords = Enum.reject(x_coords, &is_nil/1)
    y_coords = Enum.reject(y_coords, &is_nil/1)

    %__MODULE__{
      last_points: Enum.reverse(last_points),
      inst_size: 0,
      inst: "",
      flags: compress_flags(flags),
      x_coords: x_coords,
      y_coords: y_coords
    }
  end

  defp scale(path, %Metrics{} = metrics) do
    Enum.map(path, fn points ->
      Enum.map(points, fn {x, y} ->
        {Metrics.scale(metrics, x), Metrics.scale(metrics, y)}
      end)
    end)
  end

  defp make_relative(path) do
    path
    |> Enum.reduce({{0, 0}, []}, fn contour, {last_pt, contours} ->
      contour2 =
        contour
        |> Enum.zip([last_pt | contour])
        |> Enum.map(fn {{cx, cy}, {px, py}} -> {cx - px, cy - py} end)

      {List.last(contour), [contour2 | contours]}
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  @spec short_vector?(integer()) :: 0 | 1
  defp short_vector?(coord) do
    cond do
      coord === 0 -> 0
      coord >= -255 and coord <= 255 -> 1
      true -> 0
    end
  end

  @spec same_or_positive_short?(integer(), 0 | 1) :: 0 | 1
  defp same_or_positive_short?(coord, short?) do
    case short? do
      0 -> if(coord === 0, do: 1, else: 0)
      1 -> if(coord >= 0, do: 1, else: 0)
    end
  end

  @spec encode_coord(integer(), 0 | 1, 0 | 1) :: nil | <<_::8>> | <<_::16>>
  defp encode_coord(coord, short?, same_or_pos?) do
    case short? do
      0 -> if(same_or_pos? === 1, do: nil, else: <<coord::signed-16>>)
      1 -> <<abs(coord)::8>>
    end
  end

  defp compress_flags(flags) do
    flags
    |> Enum.chunk_by(& &1)
    |> Enum.map(fn chunk ->
      chunk_length = length(chunk)

      if chunk_length > 2 do
        <<flag1::4, _rpt::1, flag2::3>> = hd(chunk)

        [<<flag1::4, 1::1, flag2::3>>, <<chunk_length - 1::8>>]
      else
        chunk
      end
    end)
  end
end
