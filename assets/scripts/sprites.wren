// sprites.wren
// Sprite rendering classes backed by native Zig implementations.
// Depends on: Sprite2DRenderer foreign bindings via sprites module.

/// A sprite atlas backed by a Texture2D, sliced into uniform frames via fromGrid.
/// Lifetime is tied to the underlying texture â€” do not use after texture is freed.
foreign class SpriteAtlas {
  /// Slices `tex` into a grid of (frameWidth x frameHeight) frames.
  /// texWidth/texHeight are the full texture dimensions in pixels.
  construct fromGrid(tex, texWidth, texHeight, frameWidth, frameHeight) {}

  foreign texture2D   /// Handle to the underlying Texture2D.
  foreign frameCount  /// Total number of frames in the atlas.

  /// Frame rect components at `idx`. Prefer Sprite2D or AnimatedSprite2D
  /// over calling these directly in hot paths.
  foreign frameX(idx)
  foreign frameY(idx)
  foreign frameW(idx)
  foreign frameH(idx)
}

/// Thin wrapper around the native sprite renderer.
/// All draws must occur within the render pass.
class Sprite2DRenderer {
  /// Draws a region (src_x, src_y, src_w, src_h) of `tex` at (x, y).
  foreign static draw(x, y, src_x, src_y, src_w, src_h, tex)

  /// Draws a region (src_x, src_y, src_w, src_h) of `tex` at (x, y) scaled of size s in pixels.
  foreign static draw(x, y, s, src_x, src_y, src_w, src_h, tex)
}

/// A static sprite representing a single frame of an atlas.
/// Caches frame data at construction â€” safe and cheap to call draw() every frame.
class Sprite2D {
  /// `atlas` - source SpriteAtlas.
  /// `frame` - frame index to display.
  construct new(atlas, frame) {
    _tex   = atlas.texture2D
    _srcX = atlas.frameX(frame)
    _srcY = atlas.frameY(frame)
    _srcW = atlas.frameW(frame)
    _srcH = atlas.frameH(frame)
  }

  /// Draws the sprite at (x, y).
  draw(x, y) {
    Sprite2DRenderer.draw(x, y, _srcX, _srcY, _srcW, _srcH, _tex)
  }

  draw(x, y, s) {
    Sprite2DRenderer.draw(x, y, s, _srcX, _srcY, _srcW, _srcH, _tex)
  }
}

/// Plays back frames from an atlas at a fixed frame rate.
/// Call update(dt) once per frame before draw().
class AnimatedSprite2D {
  /// `atlas`      - source SpriteAtlas.
  /// `frameRate`  - playback speed in frames per second.
  construct new(atlas, frameRate) {
    _atlas      = atlas
    _frameRate  = frameRate
    _frameCount = atlas.frameCount
    _tex        = atlas.texture2D
    _elapsed    = 0
    _frame      = 0
  }

  /// Resets the animation to frame(0).
  reset() {
    _elapsed = 0
    _frame = 0
  }

  /// Advances the animation. `dt` is delta time in seconds.
  update(dt) {
    _elapsed = _elapsed + dt
    _frame   = (_elapsed * _frameRate).floor % _frameCount
  }

  /// Draws the current frame at (x, y). Call update() first.
  draw(x, y) {
    Sprite2DRenderer.draw(
      x, y,
      _atlas.frameX(_frame),
      _atlas.frameY(_frame),
      _atlas.frameW(_frame),
      _atlas.frameH(_frame),
      _tex
    )
  }
  
  draw(x, y, s) {
    Sprite2DRenderer.draw(
      x, y, s,
      _atlas.frameX(_frame),
      _atlas.frameY(_frame),
      _atlas.frameW(_frame),
      _atlas.frameH(_frame),
      _tex
    )
  }
}