import "vector" for Vec2, Direction
import "sprites" for Sprite2D, AnimatedSprite2D

class UnitType {
  static MC       { 0 }
  static WISP     { 1 }
  static LANTERN  { 2 }
  static MOUNTAIN { 3 }
}

class Unit {
  construct new(id, type, x, y, sprite, hp, speed) {
    _id = id
    _type = type
    _x = x
    _y = y
    _sprite = sprite
    if (sprite.type == Map) {
      _currentSprite = sprite.toList[0].value
    } else {
      _currentSprite = sprite
    }
    _hp = hp
    _speed = speed
    _direction = Direction.NW
  }

  id { _id }
  type { _type }
  x { _x }
  y { _y }
  sprite { _sprite }
  currentSprite { _currentSprite}
  setSprite(value) {
    _currentSprite = value
  } 
  direction { _direction }
  setDirection(value) {
    _direction = value
  }

  hp { _hp }
  hp=(value) {
    _hp = value
  } 
  speed { _speed }

  vec2 {
    return Vec2.new(_x, _y)
  }

  vec2=(value) {
    _x = value.x
    _y = value.y
  }

  // only return first frame if _sprite is an AnimatedSprite2D
  draw(x,y) {
    if (_currentSprite.type == Map) {
      var defaultAtlas = _currentSprite.values.toList[0]
      var fiber = Fiber.new {
        defaultAtlas.draw(x,y)
        defaultAtlas.update(dt)
      }
      return fiber.call()
    } else {
      return _currentSprite.draw(x,y)
    }
  }

  // draw and animate
  draw(x,y, atlas) {
    if (_currentSprite.type == Map) {
      var fiber = Fiber.new {
        atlas.draw(x,y)
        atlas.update(dt)
      }
      return fiber.call()
    } else {
      return _currentSprite.draw(x,y)
    }
  }

  drawScaled(x,y,s, dt) {
    if (_currentSprite.type == Map) {
      var defaultAtlas = _currentSprite.values.toList[0]
      var fiber = Fiber.new {
        defaultAtlas.draw(x,y,s)
        defaultAtlas.update(dt)
      }
      return fiber.call()
    } else {
      return _currentSprite.draw(x,y,s)
    }
  }

  drawScaled(x,y, s, atlas, dt) {
    if (_currentSprite.type == Map) {
      var fiber = Fiber.new {
        atlas.draw(x,y,s)
        atlas.update(dt)
      }
      return fiber.call()
    } else {
      return _currentSprite.draw(x,y,s)
    }
  }
}