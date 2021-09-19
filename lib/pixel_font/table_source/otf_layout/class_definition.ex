defmodule PixelFont.TableSource.OTFLayout.ClassDefinition do
  require PixelFont.Util, as: Util
  import Util, only: :macros

  defstruct assignments: %{}

  @type t :: %__MODULE__{
          assignments: %{optional(integer()) => [integer() | binary()]}
        }

  @typep assignment :: {integer(), integer()}

  @spec compile(t()) :: binary()
  def compile(class_def) do
    assignments =
      class_def.assignments
      |> Enum.map(fn {class, ids} -> Enum.map(ids, &{gid!(&1), class}) end)
      |> List.flatten()
      |> Enum.sort_by(&elem(&1, 0))

    assignments
    |> do_compile(detect_format(assignments, []))
    |> IO.iodata_to_binary()
  end

  @spec do_compile([assignment()], integer()) :: iodata()
  defp do_compile(assignments, format)

  defp do_compile(assignments, 1) do
    [
      # classFormat
      <<1::16>>,
      # startGlyphID
      <<assignments |> hd() |> elem(0)::16>>,
      # glyphCount
      <<length(assignments)::16>>,
      # classValueArray[]
      Enum.map(assignments, &<<elem(&1, 1)::16>>)
    ]
  end

  defp do_compile(assignments, 2) do
    class_ranges =
      assignments
      |> Enum.group_by(&elem(&1, 1), &elem(&1, 0))
      |> Enum.map(fn {class, indices} ->
        indices
        |> Enum.chunk_while(
          [],
          fn
            index, [] ->
              {:cont, [index]}

            index, [last_index | _] = chunk ->
              case index - last_index do
                1 -> {:cont, [index | chunk]}
                _ -> {:cont, Enum.reverse(chunk), [index]}
              end
          end,
          fn
            [] -> {:cont, []}
            chunk -> {:cont, Enum.reverse(chunk), []}
          end
        )
        |> Enum.map(&{hd(&1), List.last(&1), class})
      end)
      |> List.flatten()
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {first, last, class} -> <<first::16, last::16, class::16>> end)

    [
      # classFormat
      <<2::16>>,
      # classRangeCount
      <<length(class_ranges)::16>>,
      # classRangeRecords
      class_ranges
    ]
  end

  @spec detect_format([assignment()], [assignment()]) :: integer()
  defp detect_format(assignments, past_assignments)

  defp detect_format([assignment], past_assignments) do
    range_count =
      [assignment | past_assignments]
      |> Enum.reverse()
      |> Enum.chunk_by(&elem(&1, 1))
      |> length()

    glyph_count = length(past_assignments) + 1
    fmt1_size = 6 + 2 * glyph_count
    fmt2_size = 4 + 6 * range_count

    if(fmt1_size < fmt2_size, do: 1, else: 2)
  end

  defp detect_format([assignment1, assignment2 | assignments], past_assignments) do
    case elem(assignment2, 0) - elem(assignment1, 0) do
      1 -> detect_format([assignment2 | assignments], [assignment1 | past_assignments])
      _ -> 2
    end
  end
end
