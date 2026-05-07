import "shapes" for Draw
import "sprites" for SpriteAtlas, Sprite2D
import "gfx" for Texture2D
import "vector" for Vec2
import "collision" for Collision2D
import "input" for Mouse, MouseButton, Keyboard, Key

var GRID_SIZE = 8
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
    return tile.x < 0 || tile.y < 0 || tile.x > GRID_SIZE-1 || tile.y > GRID_SIZE-1
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
  construct new(id, x, y, sprites, hp) {
    _id = id
    _x = x
    _y = y
    _sprites = sprites
    _hp = hp
  }

  id { _id }
  x { _x }
  y { _y }
  sprites { _sprites }
  
  hp { _hp.current }
  hp=(value) {
    _hp.current = value
  } 
  speed { 2 } // temporarily set for testing

  vec2 {
    return Vec2.new(_x, _y)
  }

  vec2=(value) {
    _x = value.x
    _y = value.y
  }
}

// direction must be "NW", "NE", "SW", "SE" 
class Projectile {
  construct new(x,y,direction,speed,timer, sprites) {
    _x = x
    _y = y
    _direction = direction
    var targetTile = targetTile()
    _tx = targetTile.x
    _ty = targetTile.y
    _speed = speed
    _timer = timer
    _sprites = sprites
  }

  x { _x }
  y { _y }
  tx { _tx }
  ty { _ty }
  speed { _speed }
  timer { _timer }
  sprites { _sprites }
  direction { _direction }
  
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

  targetTile (){
    if (_direction == "NW") {
      return Vec2.new(-1, _y)
    }
    if (_direction == "NE") {
      return Vec2.new(_x, -1)
    }
    if (_direction == "SW") {
      return Vec2.new(x, GRID_SIZE+1)
    }
    if (_direction == "SE") {
      return Vec2.new(GRID_SIZE+1, _y)
    }
    return Vec2.new(0,0)
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
    _atlas = SpriteAtlas.fromGrid(Spritesheet, TILE_SIZE * 8, TILE_SIZE * 4, TILE_SIZE, TILE_SIZE)
    _bulletAtlas = SpriteAtlas.fromGrid(Bullet, TILE_SIZE, TILE_SIZE, TILE_SIZE, TILE_SIZE)
    _bulletMSAtlas = SpriteAtlas.fromGrid(BulletMS, TILE_SIZE, TILE_SIZE, TILE_SIZE, TILE_SIZE)

    // snow tiles
    _snowTileBaseSprite = Sprite2D.new(_atlas, 10)
    _snowTileLandSprite = Sprite2D.new(_atlas, 2)

    _snowTileNSprite = Sprite2D.new(_atlas, 16)
    _snowTileESprite = Sprite2D.new(_atlas, 0)
    _snowTileWSprite = Sprite2D.new(_atlas, 24)
    _snowTileSSprite = Sprite2D.new(_atlas, 8)

    _snowTileNWSprite = Sprite2D.new(_atlas, 25)
    _snowTileNESprite = Sprite2D.new(_atlas, 1)
    _snowTileSWSprite = Sprite2D.new(_atlas, 9)
    _snowTileSESprite = Sprite2D.new(_atlas, 17)

    // indicators
    _greenTileSprite = Sprite2D.new(_atlas, 11)
    _redTileSprite = Sprite2D.new(_atlas, 3) 
    _yellowBorderSprite = Sprite2D.new(_atlas, 19) 
    _arrowNWSprite = Sprite2D.new(_atlas, 30)
    _arrowNESprite = Sprite2D.new(_atlas, 7)
    _arrowSWSprite = Sprite2D.new(_atlas, 31)
    _arrowSESprite = Sprite2D.new(_atlas, 22)

    // units
    _wispSprite = Sprite2D.new(_atlas, 6)

    // projectiles
    _bulletSprite = Sprite2D.new(_bulletAtlas, 0)
    _bulletMSSprite = Sprite2D.new(_bulletMSAtlas, 0)

    _time = 0

    _demoLevel = []
    
    // grid tiles are the base
    _grid = []

    // units
    _units = []
    _projectiles = []

    // movement
    // green = unit possible tiles
    // red = enemy "threat" tiles
    _greenTiles = []
    _redTiles = []
    _movementQueue = []

    var addDefaultTile = Fn.new {|id, x, y|
      var tile = Tile.new(id, x, y, _snowTileLandSprite)
      _grid.add(tile)
    }

    for (i in 0..GRID_SIZE-1) {
      for (j in 0..GRID_SIZE-1) {
        var id = (i * GRID_SIZE) + j

        var x = i
        var y = j

        var tile = null

        if (id < _demoLevel.count){
          tile = Tile.new(id, x, y, _demoLevel[id])
          _grid.add(tile)
        } else {
          addDefaultTile.call(id,x,y)
        }
      }
    }

    var unitSprites = { "base": _wispSprite }
    var hp = Health.new(5)
    _wisp = Unit.new(1, 3, 3, unitSprites, hp)
    _units.add(_wisp)

    _selectedUnit = null

    var bulletSprites = { "bullet" : _bulletSprite, "bulletMS" : _bulletMSSprite }
    _bullet1 = Projectile.new(8, 2,"NW",2,1, bulletSprites)
    _bullet2 = Projectile.new(6, 8,"NE",2,2, bulletSprites)
    _bullet3 = Projectile.new(3,-1,"SW",2,3, bulletSprites)
    _bullet4 = Projectile.new(-1,5,"SE",2,4, bulletSprites)
    _projectiles.add(_bullet1)
    _projectiles.add(_bullet2)
    _projectiles.add(_bullet3)
    _projectiles.add(_bullet4)
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
        _yellowBorderSprite.draw(x,y)

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
          _redTileSprite.draw(x, y)
          if (Mouse.isJustPressed(MouseButton.LEFT)) {
            _selectedUnit = null
            unit.vec2 = Vec2.new(tile.x, tile.y)
          }
        } else {
          _greenTileSprite.draw(x, y)
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
          if (_selectedUnit.id == 1) {
            _greenTiles = Tile.getReachable(unit.x, unit.y, unit.speed)
          }
        }
      } else {
        unit.sprites["base"].draw(x,y)
        if (Mouse.isJustPressed(MouseButton.LEFT)) {
          _selectedUnit = null
        }
      }

      // draw hp
      if (unit.hp > 0) {
        for (j in 1..unit.hp) {
          var tx = x + j * 16
          var ty = y + 16
          unit.sprites["base"].draw(tx,ty,16)
        }
      } else {
        _units.remove(unit)
      }

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
          projectile.sprites["bulletMS"].draw(x,y)
        } else {
          projectile.sprites["bullet"].draw(x,y)
        }

        if (projectile.timer > 0) {
            for (j in 1..projectile.timer) {
            var tx = x + j * 16
            var ty = y + 16
            Draw.texturedQuad(tx, ty, 16, 16, Bullet)
          }
        } else {
          var steps = (projectile.speed) % pt.count
          for (step in 1..steps) {
            var fiber = Fiber.new {
              var target = pt[step]
              if (projectile.vec2 != target) {
                projectile.vec2 = Vec2.moveTowards(projectile.vec2, target, projectile.speed)    
              }
              
              for (u in _units.count-1..-1) {
                if (u == -1) break
                
                var unit = _units[u]
                if (projectile.vec2 == unit.vec2) {
                  System.print("%(projectile) %(i) hit unit %(u): %(unit.vec2)")
                  unit.hp = unit.hp - 1
                  _projectiles.removeAt(i)
                  Fiber.yield()
                }
              }
              Fiber.yield()
            }
            _movementQueue.add(fiber)
          }
          projectile.timer = 1
        }
      }

      if (Keyboard.isJustPressed(Key.SPACE)) {
        projectile.timer = projectile.timer - 1
      }
    }

    if (_movementQueue.count > 0) {
      var current = _movementQueue[0]

      current.call()
      if (!current.isDone) {
      } else {
      _movementQueue.removeAt(0)
      }
    }    
  }
}