import Config

if config_env() === :test do
  config :pixel_font, :glyph_storage, PixelFont.GlyphStorage.Mock
end
