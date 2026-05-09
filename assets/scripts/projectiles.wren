import "vector" for Vec2

class Direction {
  static NW { 0 }
  static NE { 1 }
  static SW { 2 }
  static SE { 3 }
}

class ProjectileType {
  static Bullet     { 0 }
  static Boulder    { 1 }
  static Avalanche  { 2 }  
}

class ProjectileEffect {
  static DEAL_DAMAGE { 0 }
  static KNOCKBACK   { 1 }


}

class Projectile {
  construct new(id, type, x, y, tx, ty, effects, speed, waitTime, sprite) {
    _id = id
    _type = type
    _x = x
    _y = y
    _effects = effects
    _tx = tx
    _ty = ty
    _speed = speed
    _waitTime = waitTime
    _sprite = sprite
  }

  id { _id }
  x { _x }
  y { _y }
  tx { _tx }
  ty { _ty }
  dmg { _dmg }
  speed { _speed }
  sprite { _sprite }

  effects { _effects }
  
  waitTime { _waitTime }
  waitTime=(value){
    _waitTime = value
  }

  vec2 {
    return Vec2.new(_x, _y)
  }

  targetVec2 {
    return Vec2.new(_tx, _ty)
  }

  targetVec2=(value) {
    _tx = value.x
    _ty = value.y
  }

  vec2=(value) {
    _x = value.x
    _y = value.y
  }

  line {
    var vi = Vec2.new(_x,_y)
    var vf = Vec2.new(_tx,_ty)

    return Vec2.line(vi, vf)
  }
}