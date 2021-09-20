defmodule PixelFont.UtilTest do
  use PixelFont.Case, async: true
  require PixelFont.Util, as: Util
  import Util, only: [sigil_i: 2, elem!: 2]

  describe "sigil_i/2 (macro)" do
    test "parses a list of decimal integers by default" do
      {term, _} = Code.eval_quoted(quote(do: ~i(1 23 456 7890)), [], __ENV__)

      assert term === [1, 23, 456, 7890]
    end

    test "parses a list of octal integers when the 'o' modifier exists" do
      {term, _} = Code.eval_quoted(quote(do: ~i(1 23 456 7012)o), [], __ENV__)

      assert term === [0o1, 0o23, 0o456, 0o7012]
    end

    test "parses a list of decimal integers when the 'd' modifier exists" do
      {term, _} = Code.eval_quoted(quote(do: ~i(1 23 456 7890)d), [], __ENV__)

      assert term === [1, 23, 456, 7890]
    end

    test "parses a list of hexadecimal integers when the 'x' modifier exists" do
      {term, _} = Code.eval_quoted(quote(do: ~i(1 23 4567 89Ab CdEf0)x), [], __ENV__)

      assert term === [0x1, 0x23, 0x4567, 0x89AB, 0xCDEF0]
    end

    test "raises an error if the input is invalid" do
      assert_raise RuntimeError, fn ->
        Code.eval_quoted(quote(do: ~i(3.14 2.71)), [], __ENV__)
      end

      assert_raise RuntimeError, fn ->
        Code.eval_quoted(quote(do: ~i(abcdef)), [], __ENV__)
      end
    end
  end

  describe "elem!/2 (macro)" do
    test "extracts an element from nested tuples" do
      {term, _} =
        quote(do: elem!({0, {1, 2, {3, 4, 5, {6, 7}}, 8}, 9, 10}, [1, 2, 3, 0]))
        |> Code.eval_quoted([], __ENV__)

      assert term === 6
    end
  end

  describe "offsetted_binaries/3" do
    test "generates data and offset binaries properly" do
      {next_pos, offset_bins, data_bins} =
        Util.offsetted_binaries([1, 2, 3, 4], 1000, fn item ->
          item |> List.wrap() |> List.duplicate(item)
        end)

      assert next_pos === 1010
      assert offset_bins === [<<1000::16>>, <<1001::16>>, <<1003::16>>, <<1006::16>>]
      assert data_bins === [<<1>>, <<2, 2>>, <<3, 3, 3>>, <<4, 4, 4, 4>>]
    end
  end
end
