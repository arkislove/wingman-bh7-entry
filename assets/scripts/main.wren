import "shapes" for Draw
import "sprites" for SpriteAtlas, Sprite2D
import "gfx" for Texture2D
import "vector" for Vec2
import "collision" for Collision2D
import "input" for Mouse, MouseButton, Keyboard, Key
import "level" for Level

var TILE_SIZE = 64 

var CENTER_X = 1280 / 2
var CENTER_Y = 720 / 2

var GRID_OFFSET_X = 600
var GRID_OFFSET_Y = 200

var Spritesheet = Texture2D.fromUri("http://localhost:3000/textures/spritesheet.png")
var ArrowActive = Texture2D.fromUri("http://localhost:3000/textures/arrows/active.png")

var Bullet = Texture2D.fromUri("http://localhost:3000/textures/bullets/bullet.png")
var BulletMS = Texture2D.fromUri("http://localhost:3000/textures/bullets/bullet_ms.png")

class Tile {
  construct new(id, x, y, sprite) {
    _id = id
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

class Health {
  construct new(max) {
    _max = max
    _current = max 
  }

  current { _current }
  max { _max }

  current=(value) {
    _current = value
  }
}

class Unit {
  construct new(id, name, x, y, sprites, hp) {
    _name = name
    _id = id
    _x = x
    _y = y
    _sprites = sprites
    _hp = hp
  }

  id { _id }
  name { _name }
  x { _x }
  y { _y }
  sprites { _sprites }
  
  hp { _hp.current }
  hp=(value) {
    _hp.current = value
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
  construct new(x,y,dmg,direction,speed,timer, sprites) {
    _x = x
    _y = y
    _dmg = dmg
    _direction = direction
    _tx = targetTile.x
    _ty = targetTile.y
    _speed = speed
    _timer = timer
    _sprites = sprites
    _onHitEffects = []
  }

  x { _x }
  y { _y }
  tx { _tx }
  ty { _ty }
  dmg { _dmg }
  speed { _speed }
  timer { _timer }
  sprites { _sprites }
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

class Main {
  construct init() {
    // sprite
    var mainAtlas = SpriteAtlas.fromGrid(Spritesheet, TILE_SIZE * 8, TILE_SIZE * 4, TILE_SIZE, TILE_SIZE)
    var bulletAtlas = SpriteAtlas.fromGrid(Bullet, TILE_SIZE, TILE_SIZE, TILE_SIZE, TILE_SIZE)
    var bulletMSAtlas = SpriteAtlas.fromGrid(BulletMS, TILE_SIZE, TILE_SIZE, TILE_SIZE, TILE_SIZE)
    
    _sprites = {
      "main": {
        "snowTileE":        Sprite2D.new(mainAtlas, 0),
        "snowTileNE":       Sprite2D.new(mainAtlas, 1),
        "snowTileLand":     Sprite2D.new(mainAtlas, 2),
        "redIndicator":     Sprite2D.new(mainAtlas, 3),
        "tree":             Sprite2D.new(mainAtlas, 4),
        "lanternOn":        Sprite2D.new(mainAtlas, 5),
        "wisp":             Sprite2D.new(mainAtlas, 6),
        "arrowNE":          Sprite2D.new(mainAtlas, 7),
        "snowTileS":        Sprite2D.new(mainAtlas, 8),
        "snowTileSW":       Sprite2D.new(mainAtlas, 9),
        "snowTileBase":     Sprite2D.new(mainAtlas, 10),
        "greenIndicator":   Sprite2D.new(mainAtlas, 11),
        "slimeLeft":        Sprite2D.new(mainAtlas, 12),
        "lanternOff":       Sprite2D.new(mainAtlas, 13),
        "emptyHpBar":       Sprite2D.new(mainAtlas, 14),
        "arrowUp":          Sprite2D.new(mainAtlas, 15),
        "snowTileN":        Sprite2D.new(mainAtlas, 16),
        "snowTileSE":       Sprite2D.new(mainAtlas, 17),
        "snowTileCracked":  Sprite2D.new(mainAtlas, 18),
        "yellowIndicator":  Sprite2D.new(mainAtlas, 19),
        "slimeRight":       Sprite2D.new(mainAtlas, 20),
        "lanternGlow":      Sprite2D.new(mainAtlas, 21),
        "arrowSE":          Sprite2D.new(mainAtlas, 22),
        "activeIndicator":  Sprite2D.new(mainAtlas, 23),
        "snowTileW":        Sprite2D.new(mainAtlas, 24),
        "snowTileNW":       Sprite2D.new(mainAtlas, 25),
        "iceTile":          Sprite2D.new(mainAtlas, 26),
        "mountain":         Sprite2D.new(mainAtlas, 27),
        "slimeBack":        Sprite2D.new(mainAtlas, 28),
        "lanternBroken":    Sprite2D.new(mainAtlas, 29),
        "arrowNW":          Sprite2D.new(mainAtlas, 30),
        "arrowSW":          Sprite2D.new(mainAtlas, 31),
      },
      "bullet" : {
        "bullet": 0
      },
      "bulletMS" : {
        "bulletMS": 0
      }
    }

    _time = 0

    // grid tiles are the base
    _grid = []

    // units and projectiles are on top of the grid tiles
    _units = []
    _projectiles = []

    // green = unit possible tiles
    // red = enemy "threat" tiles
    _greenTiles = []
    _redTiles = []
    
    // event
    _eventQueue = []

    var level = Level.level0(_sprites)

    var grid = level["grid"]
    var units = level["units"]

    _gridSize = Vec2.new(0,0)

    for (i in 0..units.count-1) {
      var x = units[i][0]
      var y = units[i][1]
      var name = units[i][2]
      var sprites = { "base" : units[i][2] }

      var unit = Unit.new(_units.count, name, x, y, sprites, 3)
      _units.add(unit)
    }

    var addDefaultTile = Fn.new {|id, x, y|
      var tile = Tile.new(id, x, y, 0)
      _grid.add(tile)
    }

    for (i in 0..grid.count-1) {
      var x = grid[i][0]
      var y = grid[i][1]
      var sprite = grid[i][2]
      var id = x + x*y
      var tile = Tile.new(id,x,y,sprite)
      _grid.add(tile)
      if (_gridSize.x < x || _gridSize.y < y) {
        _gridSize = Vec2.new(x,y)
      }
    }
  }

  frame(dt) {
    _time = _time + dt * 0.5

    var pointer = Vec2.new(Mouse.x(), Mouse.y())

    // FOR ALL GRID OBJECTS: always add GRID_OFFSET_X and GRID_OFFSET_Y to x and y
    // draw grid
    for (i in 0.._grid.count-1) {
      var tile = _grid[i]

      var x = GRID_OFFSET_X + (tile.x - tile.y) * TILE_SIZE
      var y = GRID_OFFSET_Y + (tile.x + tile.y) * TILE_SIZE/2

      tile.sprite.draw(x, y)
      var v = Tile.getTopSurfaceVectors(Vec2.new(x,y))
      if (Vec2.pointInQuad(pointer.x, pointer.y, v[0], v[1], v[2], v[3])) {
        _sprites["main"]["yellowIndicator"].draw(x,y)

        if (Mouse.isJustPressed(MouseButton.LEFT)) {
          System.print("Tile #%(tile.id): [%(tile.x),%(tile.y)]")
        }
      }
    }

    if (_selectedUnit != null) {
      var unit = _selectedUnit

      unit.sprites["base"].draw(0,600,128)

      // draw green tiles
      for (i in 0.._greenTiles.count-1) {
        var tile = _greenTiles[i]
        var x = GRID_OFFSET_X + (tile.x - tile.y) * TILE_SIZE
        var y = GRID_OFFSET_Y + (tile.x + tile.y) * TILE_SIZE/2

        var v = Tile.getTopSurfaceVectors(Vec2.new(x,y))

        Draw.texturedQuad(v[0].x, v[0].y, 10, 10, Bullet)
        Draw.texturedQuad(v[1].x, v[1].y, 10, 10, Bullet)
        Draw.texturedQuad(v[2].x, v[2].y, 10, 10, Bullet)
        Draw.texturedQuad(v[3].x, v[3].y, 10, 10, Bullet)

        if (Vec2.pointInQuad(pointer.x, pointer.y, v[0], v[1], v[2], v[3])) {
          _sprites["main"]["redIndicator"].draw(x, y)
          if (Mouse.isJustPressed(MouseButton.LEFT)) {
            _selectedUnit = null
            unit.vec2 = Vec2.new(tile.x, tile.y)
          }
        } else {
          _sprites["main"]["greenIndicator"].draw(x, y)
        }
      }

      // draw active arrow
    }

    // draw red tiles
    if (_selectedUnit == null) {
      for (i in _projectiles.count-1..-1) {
        if (i == -1) break

        var skip = false
        
        var projectile = _projectiles[i]

        var pt = projectile.projectTiles
        if (pt.count == null) {
          _projectiles.removeAt(i)
          continue
        }

        if (pt.count > 0) {
          var skip = false
          for (j in 0..pt.count-1) {
            var tile = pt[j]

            for (i in 0.._units.count-1) {
              var unit = _units[i]
              if (tile == unit.vec2) {
                skip = true
                break
              }
            }

            if (Tile.isOutOfBounds(tile)) continue

            var ptx = GRID_OFFSET_X + (tile.x - tile.y) * TILE_SIZE
            var pty = GRID_OFFSET_Y + (tile.x + tile.y) * TILE_SIZE/2

            _redTileSprite.draw(ptx,pty)

            if (j > 0 && j < pt.count - 1) {
              tile = pt[j-1]
              ptx = GRID_OFFSET_X + (tile.x - tile.y) * TILE_SIZE
              pty = GRID_OFFSET_Y + (tile.x + tile.y) * TILE_SIZE/2 - TILE_SIZE

              var nextTile = pt[j]

              var tx = GRID_OFFSET_X + (nextTile.x - nextTile.y) * TILE_SIZE
              var ty = GRID_OFFSET_Y + (nextTile.x + nextTile.y) * TILE_SIZE/2 - TILE_SIZE

              var start = Vec2.new(ptx, pty)
              var end   = Vec2.new(tx, ty - TILE_SIZE)

              var dir = (end - start)
              var dist = dir.magnitude
              var norm = dir / dist

              var speed = 64
              var spacing = 64
              var offset = (_time * speed) % spacing

              for (k in 0..(dist / spacing)) {
                var t = k * spacing + offset
                if (t > dist) continue

                var pos = start + norm * t

                if (projectile.direction == "NW") {
                  _arrowNWSprite.draw(tx,ty)
                }
                if (projectile.direction == "NE") {
                  _arrowNESprite.draw(tx,ty)
                }
                if (projectile.direction == "SW") {
                  _arrowSWSprite.draw(tx,ty)
                }
                if (projectile.direction == "SE") {
                  _arrowSESprite.draw(tx,ty)
                }
              }
            }
            
            if (skip) break
          }
        }
      }
    }

    // draw units
    for (i in 0.._units.count-1) {
      var unit = _units[i]

      var x = GRID_OFFSET_X + (unit.x - unit.y) * TILE_SIZE
      var y = GRID_OFFSET_Y + (unit.x + unit.y) * TILE_SIZE/2 - TILE_SIZE

      var w = TILE_SIZE
      var v1 = Vec2.new(x, y)
      var v2 = Vec2.new(x - w, y)
      var v3 = Vec2.new(x + w, y + w)
      var v4 = Vec2.new(x, y + w)

      if (Vec2.pointInQuad(pointer.x, pointer.y, v1, v2, v3, v4)) {
        unit.sprites["base"].draw(x-3,y-3, TILE_SIZE+6)
        
        if (Mouse.isJustPressed(MouseButton.LEFT) && _selectedUnit == null) {
          _selectedUnit = unit
        
          // wisp
          if (_selectedUnit.name == "wisp") {
            _greenTiles = Tile.getReachable(unit.x, unit.y, unit.speed)
          } else {
            _selectedUnit = null
          }
        }
      } else {
        unit.sprites["base"].draw(x,y)
        if (Mouse.isJustPressed(MouseButton.LEFT)) {
          _selectedUnit = null
        }
      }

      // draw hp
      // if (unit.hp > 0) {
      //   for (j in 1..unit.hp) {
      //     var tx = x + j * 16
      //     var ty = y + 16
      //     unit.sprites["base"].draw(tx,ty,16)
      //   }
      // } else {
      //   _units.remove(unit)
      // }

      if (_selectedUnit != null) {
        System.print("_selectedUnit.id : %(_selectedUnit.id) , unit.id : %(unit.id)")
        if (_selectedUnit.id == unit.id) {
          Draw.texturedQuad(x, y, TILE_SIZE, TILE_SIZE - 16, ArrowActive)
        }
      }
    }

    // draw projectile
    for (i in _projectiles.count-1..-1) {
      if (i == -1) break      
      var projectile = _projectiles[i]
      
      if (projectile.vec2 == projectile.targetVec2) {
        _projectiles.removeAt(i)
        continue
      }

      var pt = projectile.projectTiles
      if (pt.count == null) {
        _projectiles.removeAt(i)
        continue
      }

      var x = GRID_OFFSET_X + (projectile.x - projectile.y) * TILE_SIZE
      var y = GRID_OFFSET_Y + (projectile.x + projectile.y) * TILE_SIZE / 2 - TILE_SIZE
      
      if (pt.count > 0) {
        if (Tile.isOutOfBounds(projectile)) {
          // projectile.sprites["bulletMS"].draw(x,y)
        } else {
          projectile.sprites["bullet"].draw(x,y)
        }

        if (projectile.timer > 0) {
          for (j in 1..projectile.timer) {
            var tx = x + j * 16
            var ty = y + 16
            if (Tile.isOutOfBounds(projectile)) {
              projectile.sprites["bulletMS"].draw(tx,ty,32)
            }
          }
        } else {
          var steps = (projectile.speed) % pt.count
          for (step in 1..steps) {
            var fiber = Fiber.new {
              var target = pt[step]
              if (projectile.vec2 != target) {
                projectile.vec2 = Vec2.moveTowards(projectile.vec2, target, projectile.speed)    
              }
              
              // unit collision checker
              for (u in _units.count-1..-1) {
                if (u == -1) break
                
                var unit = _units[u]
                if (projectile.vec2 == unit.vec2) {
                  System.print("%(projectile) %(i) hit unit %(u): %(unit.vec2)")
                  for (i in 0..projectile.onHitEffects.count-1) {
                    var effect = projectile.onHitEffects[i]

                    effect.play(unit,projectile)
                  }
                  unit.hp = unit.hp - 1 // TODO: move to onHitEffect
                  _projectiles.removeAt(i)
                  Fiber.yield()
                }
              }
              Fiber.yield()
            }
            _eventQueue.add(fiber)
          }
          projectile.timer = 1
        }
      }

      if (Keyboard.isJustPressed(Key.SPACE)) {
        projectile.timer = projectile.timer - 1
      }
    }

    if (_eventQueue.count > 0) {
      var current = _eventQueue[0]

      current.call()
      if (!current.isDone) {
      } else {
      _eventQueue.removeAt(0)
      }
    }    
  }
}