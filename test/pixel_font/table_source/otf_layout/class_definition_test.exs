defmodule PixelFont.TableSource.OTFLayout.ClassDefinitionTest do
  use ExUnit.Case
  import Mox
  alias PixelFont.Glyph
  alias PixelFont.TableSource.OTFLayout.ClassDefinition

  setup [:setup_mock, :verify_on_exit!]

  describe "compile/1, with consecutive glyph IDs" do
    @tag glyph_storage_get_count: 12
    test "compiles Class definition table in a format which emits less bytes" do
      # Format 1: 6 + 2 * 6 = 18 bytes (selected)
      # Format 2: 4 + 6 * 3 = 22 bytes
      classes1 = %ClassDefinition{assignments: %{1 => 'ab', 2 => 'cd', 3 => 'ef'}}
      compiled_classes1 = ClassDefinition.compile(classes1)

      expected1 =
        [
          [1, ?a, 6],
          # Class values
          [1, 1, 2, 2, 3, 3]
        ]
        |> List.flatten()
        |> Enum.map(&<<&1::16>>)
        |> IO.iodata_to_binary()

      assert compiled_classes1 === expected1

      # Format 1: 6 + 2 * 6 = 18 bytes
      # Format 2: 4 + 6 * 1 = 10 bytes (selected)
      classes2 = %ClassDefinition{assignments: %{1 => 'abcdef'}}
      compiled_classes2 = ClassDefinition.compile(classes2)

      expected2 =
        [
          [2, 1],
          # Class range records
          [[?a, ?f, 1]]
        ]
        |> List.flatten()
        |> Enum.map(&<<&1::16>>)
        |> IO.iodata_to_binary()

      assert compiled_classes2 === expected2
    end
  end

  describe "compile/1, with non-consecutive glyph IDs" do
    @tag glyph_storage_get_count: 4
    test "compiles Class definition table format 2" do
      classes = %ClassDefinition{assignments: %{1 => '09', 2 => 'az'}}
      compiled_classes = ClassDefinition.compile(classes)

      expected =
        [
          [2, 4],
          # Class range records
          [[?0, ?0, 1], [?9, ?9, 1], [?a, ?a, 2], [?z, ?z, 2]]
        ]
        |> List.flatten()
        |> Enum.map(&<<&1::16>>)
        |> IO.iodata_to_binary()

      assert compiled_classes === expected
    end
  end

  defp setup_mock(context) do
    PixelFont.GlyphStorage.Mock
    |> expect(:get, context[:glyph_storage_get_count], &%Glyph{gid: &1})

    :ok
  end
end
