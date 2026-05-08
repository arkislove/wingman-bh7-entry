import "vector" for Vec2

var TILE_SIZE = 64 

class Tile {
  construct new(x, y, sprite) {
    _id = x * x + y
    _x = x
    _y = y
    _sprite = sprite
  }

  id { _id }
  x { _x }
  y { _y }
  sprite { _sprite }
  
  effect { _effect }
  addEffect (value) {
    _effect.add(value)
  }

  static getTopSurfaceVectors(tile) {
    var v1 = Vec2.new(tile.x, tile.y - TILE_SIZE) // top
    var v2 = Vec2.new(tile.x + TILE_SIZE, tile.y - TILE_SIZE/2) // right
    var v3 = Vec2.new(tile.x, tile.y) // bottom
    var v4 = Vec2.new(tile.x - TILE_SIZE, tile.y - TILE_SIZE/2) // left 
    
    return [v1,v2,v3,v4]
  }

  static isOutOfBounds(tile) {
    return tile.x < 0 || tile.y < 0
  }

  static getReachable(startX, startY, speed) {
    var queue = [[startX, startY, 0]]
    var visited = {}
    var reachable = []

    while (queue.count > 0) {
        var node = queue.removeAt(0)
        var x = node[0]
        var y = node[1]
        var cost = node[2]

        var key = "%(x),%(y)"

        if (isOutOfBounds(Vec2.new(x,y))) continue
        if (visited.containsKey(key)) continue
        visited[key] = true

        if (cost > speed) continue

        reachable.add(Vec2.new(x, y))

        var dirs = [[1,0], [-1,0], [0,1], [0,-1]]

        for (d in dirs) {
          var nx = x + d[0]
          var ny = y + d[1]

          queue.add([nx, ny, cost + 1])
        }
    }

    return reachable
  }
}

class Unit {
  construct new(id, name, x, y, sprite, hp) {
    _id = id
    _name = name
    _x = x
    _y = y
    _sprite = sprite
    _hp = hp
  }

  id { _id }
  name { _name }
  x { _x }
  y { _y }
  sprite { _sprite }
  
  hp { _hp }
  hp=(value) {
    _hp = value
  } 
  speed { 5 } // temporarily set for testing

  vec2 {
    return Vec2.new(_x, _y)
  }

  vec2=(value) {
    _x = value.x
    _y = value.y
  }
}

class OnHitEffect {
  construct new() {}
  
  dealDamage(target, dmg) {
    target.hp = target.hp - dmg
  }

  knockback(target, direction) {
    var tv = target.vec2
    if (direction == "NW") {
      tv = tv + Vec2.new(-1, 0)
    }
    if (direction == "NE") {
      tv = tv + Vec2.new(0, -1)
    }
    if (direction == "SW") {
      tv = tv + Vec2.new(0, 1)
    }
    if (direction == "SE") {
      tv = tv + Vec2.new(1, 0)
    }
    target.vec2 = Vec2.moveTowards(target.vec2, tv, 1)
  }
  
  play(target, projectile) {
    knockback(target, projectile.direction)
    dealDamage(target, projectile.dmg)
  }
}

// direction must be "NW", "NE", "SW", "SE" 
class Projectile {
  construct new(id, x, y, tx, ty, dmg, direction, speed, timer, sprite) {
    _x = x
    _y = y
    _dmg = dmg
    _direction = direction
    _tx = tx
    _ty = ty
    _speed = speed
    _timer = timer
    _sprite = sprite
    _onHitEffects = []
  }

  x { _x }
  y { _y }
  tx { _tx }
  ty { _ty }
  dmg { _dmg }
  speed { _speed }
  timer { _timer }
  sprite { _sprite }
  direction { _direction }

  onHitEffects { _onHitEffects }
  addOnHitEffect (value) { 
    _onHitEffects.add(value)
  }
  
  timer=(value){
    _timer = value
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

  projectTiles {
    var vi = Vec2.new(_x,_y)
    var vf = Vec2.new(_tx,_ty)

    return Vec2.line(vi, vf)
  }
}

class Level {
  construct new() {
    _sprites = {}
  }

  sprites { _sprites }
  sprites=(value){
    _sprites = value
  }

  /* LEVEL TEMPLATE
  static levelX (sprites) {
    return {
      "init" : {
        "grid" : [
          [x1,y1, sprites["atlasKey"]["spriteKey"]],
          ...
          [xn,yn, sprites["atlasKey"]["spriteKey"]]
        ],
        "units" : [
          [x,y, sprites["atlasKey"]["spriteKey"]]
        ],
      },
      "goalTile" : [x,y],
      "turnEvents" : {
        "1" : {
          "tiles" : [
            Tiles.new(x,y)
          ]
          "units"
        }      
      }
  }
  */
  static level0 (sprites) {
    return {
      "init" : {
        "grid" : [
          [3,0, sprites["main"]["snowTileBase"]],
          [3,1, sprites["main"]["snowTileLand"]],
          [3,2, sprites["main"]["snowTileBase"]],
          [4,0, sprites["main"]["snowTileBase"]],
          [4,1, sprites["main"]["snowTileBase"]],
          [4,2, sprites["main"]["snowTileBase"]],
          [5,0, sprites["main"]["snowTileBase"]],
          [5,1, sprites["main"]["snowTileBase"]],
          [5,2, sprites["main"]["snowTileBase"]],
          [6,0, sprites["main"]["snowTileBase"]],
          [6,1, sprites["main"]["snowTileBase"]],
          [6,2, sprites["main"]["snowTileBase"]],
          [7,0, sprites["main"]["snowTileBase"]],
          [7,1, sprites["main"]["snowTileBase"]],
          [7,2, sprites["main"]["snowTileBase"]],
        ],
        "units" : [],
      },
      "phases": {
        "1" : {
          "goal": [3,1],
        },
        "2" : {
          "goal": [4,0],
          "tiles" : [
            Tile.new(0,4, sprites["main"]["snowTileLand"]),
            Tile.new(1,4, sprites["main"]["snowTileBase"]),
            Tile.new(2,4, sprites["main"]["snowTileBase"]),
            Tile.new(3,4, sprites["main"]["snowTileBase"]),
            Tile.new(4,4, sprites["main"]["snowTileBase"]),
            Tile.new(4,3, sprites["main"]["snowTileBase"]),
            Tile.new(4,3, sprites["main"]["snowTileBase"]),
          ]
        },
      },
      "turnEvents": {
        "1" : {
          "tiles" : [
          ],
          "units" : [
            Unit.new(1, "wisp", 7,1, sprites["main"]["wisp"], 5)
          ],
          "projectiles" : [
            Projectile.new(1, 7,3,7,-1,1,"NE",1,1,sprites["bullet"]["bullet"]),
            Projectile.new(2,6,-1,6,3,1,"SW",1,2,sprites["bullet"]["bullet"]),
            Projectile.new(3,5,3,5,-1,1,"NE",1,4,sprites["bullet"]["bullet"])
          ]
        }
      }
    }
  }
}