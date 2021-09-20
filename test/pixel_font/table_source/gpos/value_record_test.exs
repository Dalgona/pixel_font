defmodule PixelFont.TableSource.GPOS.ValueRecordTest do
  use PixelFont.Case, async: true
  alias PixelFont.TableSource.GPOS.ValueRecord

  describe "compile/2" do
    test "compiles value records property" do
      value_record = %ValueRecord{x_placement: 10, x_advance: 20}

      compiled_value_record =
        value_record
        |> ValueRecord.compile(~w(x_placement x_advance)a)
        |> IO.iodata_to_binary()

      expected = <<10::16, 20::16>>

      assert compiled_value_record === expected
    end

    test "discards values not specified in the value format" do
      value_record = %ValueRecord{
        x_placement: 10,
        y_placement: 20,
        x_advance: 30,
        y_advance: 40
      }

      compiled_value_record =
        value_record
        |> ValueRecord.compile(~w(x_placement x_advance)a)
        |> IO.iodata_to_binary()

      expected = <<10::16, 30::16>>

      assert compiled_value_record === expected
    end

    test "sorts values in a proper order even if the value format is scrambled" do
      value_record = %ValueRecord{
        x_placement: 10,
        y_placement: 20,
        x_advance: 30,
        y_advance: 40
      }

      compiled_value_record =
        value_record
        |> ValueRecord.compile(~w(y_advance y_placement x_advance x_placement)a)
        |> IO.iodata_to_binary()

      expected = <<10::16, 20::16, 30::16, 40::16>>

      assert compiled_value_record === expected
    end
  end

  describe "compile_value_format/1" do
    test "compiles arbitrary combinations of value formats into 16-bit binaries" do
      compile = &ValueRecord.compile_value_format/1

      assert compile.([]) === <<0b0000::16>>
      assert compile.([:x_placement]) === <<0b0001::16>>
      assert compile.([:y_placement]) === <<0b0010::16>>
      assert compile.([:x_advance]) === <<0b0100::16>>
      assert compile.([:y_advance]) === <<0b1000::16>>
      assert compile.(~w(x_placement y_placement x_advance y_advance)a) === <<0b1111::16>>
    end
  end
end
