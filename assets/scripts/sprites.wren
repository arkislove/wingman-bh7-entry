foreign class SpriteAtlas {
  construct fromGrid(tex, texWidth, texHeight, frameWidth, frameHeight) {}
}

foreign class Sprite2D {
  construct new(spriteAtlas, frame) {}
  foreign draw(x, y)
  foreign draw(x, y, s)
}