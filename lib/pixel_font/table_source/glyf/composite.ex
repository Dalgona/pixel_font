defmodule PixelFont.TableSource.Glyf.Composite do
  alias PixelFont.Font.Metrics
  alias PixelFont.Glyph
  alias PixelFont.Glyph.CompositeData

  defstruct ~w(components)a

  @type t :: %__MODULE__{components: [[binary]]}

  @spec new([CompositeData.glyph_component()], Metrics.t()) :: t()
  def new(components, %Metrics{} = metrics) do
    %__MODULE__{components: make_data(components, metrics, [])}
  end

  defp make_data(component, metrics, acc)

  defp make_data([component], %Metrics{} = metrics, acc) do
    Enum.reverse([do_make_data(component, metrics, 0) | acc])
  end

  defp make_data([component | components], %Metrics{} = metrics, acc) do
    make_data(components, metrics, [do_make_data(component, metrics, 1) | acc])
  end

  defp do_make_data(component, %Metrics{} = metrics, more) do
    %{glyph: %Glyph{gid: gid}, x_offset: xoff, y_offset: yoff, flags: flags} = component
    xoff = Metrics.scale(metrics, xoff)
    yoff = Metrics.scale(metrics, yoff)
    args_are_words = xoff > 127 or xoff < -128 or yoff > 127 or yoff < -128

    [
      # flags
      <<
        # 0xE000 - (reserved)
        0::3,
        # 0x1000 - UNSCALED_COMPONENT_OFFSET
        1::1,
        # 0x0800 - SCALED_COMPONENT_OFFSET
        0::1,
        # 0x0400 - OVERLAP_COMPOUND
        1::1,
        # 0x0200 - USE_MY_METRICS
        if(:use_my_metrics in flags, do: 1, else: 0)::1,
        # 0x0100 - WE_HAVE_INSTRUCTIONS
        0::1,
        # 0x0080 - WE_HAVE_A_TWO_BY_TWO
        0::1,
        # 0x0040 - WE_HAVE_AN_X_AND_Y_SCALE
        0::1,
        # 0x0020 - MORE_COMPONENTS
        more::1,
        # 0x0010 - (reserved)
        0::1,
        # 0x0008 - WE_HAVE_A_SCALE
        0::1,
        # 0x0004 - ROUND_XY_TO_GRID
        1::1,
        # 0x0002 - ARGS_ARE_XY_VALUES
        1::1,
        # 0x0001 - ARG_1_AND_2_ARE_WORDS
        (args_are_words && 1 || 0)::1
      >>,
      # glyph index
      <<gid::big-16>>,
      # args
      if(
        args_are_words,
        do: <<xoff::signed-16, yoff::signed-16>>,
        else: <<xoff::signed-8, yoff::signed-8>>
      )
    ]
  end
end
