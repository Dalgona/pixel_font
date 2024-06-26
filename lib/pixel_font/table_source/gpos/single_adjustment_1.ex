defmodule PixelFont.TableSource.GPOS.SingleAdjustment1 do
  alias PixelFont.TableSource.GPOS.ValueRecord
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage

  defstruct glyphs: %GlyphCoverage{},
            value_format: [],
            value: %ValueRecord{}

  @type t :: %__MODULE__{
          glyphs: GlyphCoverage.t(),
          value_format: [atom()],
          value: ValueRecord.t()
        }

  defimpl PixelFont.TableSource.GPOS.Subtable do
    alias PixelFont.Font.Metrics
    alias PixelFont.TableSource.GPOS.SingleAdjustment1
    alias PixelFont.TableSource.GPOS.ValueRecord
    alias PixelFont.TableSource.OTFLayout.GlyphCoverage

    @spec compile(SingleAdjustment1.t(), keyword()) :: binary()
    def compile(subtable, opts) do
      %Metrics{} = metrics = Keyword.fetch!(opts, :metrics)
      compiled_coverage = GlyphCoverage.compile(subtable.glyphs)

      compiled_value =
        subtable.value
        |> ValueRecord.compile(subtable.value_format, metrics)
        |> IO.iodata_to_binary()

      IO.iodata_to_binary([
        # posFormat
        <<1::16>>,
        # coverageOffset
        <<byte_size(compiled_value) + 6::16>>,
        # valueFormat
        ValueRecord.compile_value_format(subtable.value_format),
        # valueRecord
        compiled_value,
        # Glyph coverage
        compiled_coverage
      ])
    end
  end
end
