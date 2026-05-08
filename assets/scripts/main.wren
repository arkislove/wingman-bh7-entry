import "shapes" for Draw
import "sprites" for SpriteAtlas, Sprite2D
import "gfx" for Texture2D
import "vector" for Vec2
import "collision" for Collision2D
import "input" for Mouse, MouseButton, Keyboard, Key
import "level" for Tile, Unit, OnHitEffect, Projectile, Level

var TILE_SIZE = 64 

var CENTER_X = 1280 / 2
var CENTER_Y = 720 / 2

var GRID_OFFSET_X = 600
var GRID_OFFSET_Y = 200

var Spritesheet = Texture2D.fromUri("http://localhost:3000/textures/spritesheet.png")
var ArrowActive = Texture2D.fromUri("http://localhost:3000/textures/arrows/active.png")

var Bullet = Texture2D.fromUri("http://localhost:3000/textures/bullets/bullet.png")
var BulletMS = Texture2D.fromUri("http://localhost:3000/textures/bullets/bullet_ms.png")

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
        "bullet": Sprite2D.new(bulletAtlas, 0)
      },
      "bulletMS" : {
        "bulletMS": Sprite2D.new(bulletMSAtlas, 0)
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

    _level = Level.level0(_sprites)

    var grid = _level["grid"]
    _turnEvents = _level["turnEvents"]

    _gridSize = Vec2.new(0,0)

    for (entry in _level) {
      if (entry.key == "grid") {
        var grid = entry.value

        if (grid.count > 0) {
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
      }
      if (entry.key == "units") {
        var units = entry.value

        if (units.count > 0 ) {
          for (i in 0..units.count-1) {
            var x = units[i][0]
            var y = units[i][1]
            var name = units[i][2]
            var sprites = units[i][2]

            var unit = Unit.new(name, x, y, sprites, 3)
            _units.add(unit)
          }
        }
      }
    }

    _turn = 0
    _turnExecuted = []
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

      unit.sprite.draw(0,600,128)

      // draw green tiles
      for (i in 0.._greenTiles.count-1) {
        var tile = _greenTiles[i]

        var skip = false
        // check grid tile presence 
        for (j in 0.._grid.count-1) {
          var gridTile = _grid[j]
          if (gridTile.x == tile.x && gridTile.y == tile.y) {
            skip = true
          }
        }
        if (!skip) continue

        var x = GRID_OFFSET_X + (tile.x - tile.y) * TILE_SIZE
        var y = GRID_OFFSET_Y + (tile.x + tile.y) * TILE_SIZE/2

        var v = Tile.getTopSurfaceVectors(Vec2.new(x,y))       

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

            _sprites["main"]["redIndicator"].draw(ptx,pty)

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
                  _sprites["main"]["arrowNW"].draw(tx,ty)
                }
                if (projectile.direction == "NE") {
                  _sprites["main"]["arrowNE"].draw(tx,ty)
                }
                if (projectile.direction == "SW") {
                  _sprites["main"]["arrowSW"].draw(tx,ty)
                }
                if (projectile.direction == "SE") {
                  _sprites["main"]["arrowSE"].draw(tx,ty)
                }
              }
            }
            
            if (skip) break
          }
        }
      }
    }

    // draw units
    if (_units.count > 0) {
      for (i in 0.._units.count-1) {
        var unit = _units[i]

        //winning condition TODO: move somwhere else
        var goal = Vec2.new(_level["goalTile"][0],_level["goalTile"][1])
        if (unit.x == goal.x && unit.y == goal.y) {
          System.print("win")
        }


        var x = GRID_OFFSET_X + (unit.x - unit.y) * TILE_SIZE
        var y = GRID_OFFSET_Y + (unit.x + unit.y) * TILE_SIZE/2 - TILE_SIZE

        var w = TILE_SIZE
        var v1 = Vec2.new(x, y)
        var v2 = Vec2.new(x - w, y)
        var v3 = Vec2.new(x + w, y + w)
        var v4 = Vec2.new(x, y + w)

        if (Vec2.pointInQuad(pointer.x, pointer.y, v1, v2, v3, v4)) {
          unit.sprite.draw(x-3,y-3, TILE_SIZE+6)
          
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
          unit.sprite.draw(x,y)
          if (Mouse.isJustPressed(MouseButton.LEFT)) {
            _selectedUnit = null
          }
        }

        // hp
        if (unit.hp > 0) {
          for (j in 1..unit.hp) {
            var size = 16
            var totalWidth = unit.hp * size
            var tx = x - totalWidth/2 + (j * size)
            var ty = y - size
            unit.sprite.draw(tx,ty,16)
          }
        } else {
          _units.remove(unit)
        }
      }
    }
    
    // draw projectile
    if (_projectiles.count > 0) {
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
        
        projectile.sprite.draw(x,y)
        if (pt.count > 0) {

          if (projectile.timer > 0) {
            for (j in 1..projectile.timer) {
              var size = 16
              var totalWidth = projectile.timer * size
              var tx = x - totalWidth/2 + (j * size)
              var ty = y - size
              if (Tile.isOutOfBounds(projectile)) {
                projectile.sprite.draw(tx,ty,32)
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
                
                // unit collision checkers
                for (u in _units.count-1..-1) {
                  if (u == -1) break
                  
                  var unit = _units[u]
                  if (projectile.vec2 == unit.vec2) {
                    System.print("%(projectile) %(i) hit unit %(u): %(unit.vec2)")
                    if (projectile.onHitEffects.count > 0) {
                      for (i in 0..projectile.onHitEffects.count-1) {
                        var effect = projectile.onHitEffects[i]

                        effect.play(unit,projectile)
                      }
                    }
                    
                    unit.hp = unit.hp - projectile.dmg
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
      }
    }
    
    var turn = "%(_turn)"

    // end turner
    if (Keyboard.isJustPressed(Key.SPACE)) {
      _turn = _turn + 1

      for (i in _projectiles.count-1..-1) {
        if (i == -1) break

        var projectile = _projectiles[i]

        projectile.timer = projectile.timer - 1
      }
    }

    if (!_turnExecuted.contains(turn)) {
      for (entry in _turnEvents) {
        if (turn == entry.key) {
          for (value in entry.value) {
            if (value.key == "units") {
              var units = value.value
              for (i in 0..units.count-1) {
                _units.add(units[i])
              }
            }
            if (value.key == "projectiles") {
              var projectiles = value.value
              for (i in 0..projectiles.count-1) {
                _projectiles.add(projectiles[i])
              }
            }
          }
          _turnExecuted.add(turn)
          break
        }
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

    if (_turn > 0) {
      for (i in 0.._turn-1) {
        _sprites["bullet"]["bullet"].draw(100 + i * 50, 1000)    
      }
    }
  }
}