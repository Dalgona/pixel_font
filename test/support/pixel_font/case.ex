defmodule PixelFont.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Mox
      import PixelFont.TestHelpers
    end
  end
end
