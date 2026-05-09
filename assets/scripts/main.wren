import "shapes" for Draw
import "sprites" for SpriteAtlas, Sprite2D, AnimatedSprite2D
import "gfx" for Texture2D
import "vector" for Vec2
import "collision" for Collision2D
import "input" for Mouse, MouseButton, Keyboard, Key
import "level" for Tile, Unit, OnHitEffect, Projectile, LevelTemplates, Level

var TILE_SIZE = 64 

var CENTER_X = 1280 / 2
var CENTER_Y = 720 / 2

var GRID_OFFSET_X = 600
var GRID_OFFSET_Y = 200

var Spritesheet = Texture2D.fromUri("http://localhost:3000/textures/spritesheet.png")
var ArrowActive = Texture2D.fromUri("http://localhost:3000/textures/arrows/active.png")

var MCIdleLeft = Texture2D.fromUri("http://localhost:3000/textures/units/mc/mc_idle_left.png")
var MCIdleRight = Texture2D.fromUri("http://localhost:3000/textures/units/mc/mc_idle_right.png")
var MCMovingLeft = Texture2D.fromUri("http://localhost:3000/textures/units/mc/mc_moving_left.png")
var MCMovingRight = Texture2D.fromUri("http://localhost:3000/textures/units/mc/mc_moving_right.png")

var Bullet = Texture2D.fromUri("http://localhost:3000/textures/bullets/bullet.png")
var BulletMS = Texture2D.fromUri("http://localhost:3000/textures/bullets/bullet_ms.png")

class Player {
  construct new(startingFuel) {
    _fuel = startingFuel
  }

  fuel { _fuel }
  addFuel(amount) {
    _fuel = _fuel + amount
  }
  useFuel(amount) {
    _fuel = _fuel - amount
  }
}

class Main {
  construct init() {
    // sprite
    var mainAtlas = SpriteAtlas.fromGrid(Spritesheet, TILE_SIZE * 8, TILE_SIZE * 4, TILE_SIZE, TILE_SIZE)
    var bulletAtlas = SpriteAtlas.fromGrid(Bullet, TILE_SIZE, TILE_SIZE, TILE_SIZE, TILE_SIZE)
    var bulletMSAtlas = SpriteAtlas.fromGrid(BulletMS, TILE_SIZE, TILE_SIZE, TILE_SIZE, TILE_SIZE)
    var mcSpriteAtlas = {
      "idleLeft": SpriteAtlas.fromGrid(MCIdleLeft, TILE_SIZE * 4, TILE_SIZE, TILE_SIZE, TILE_SIZE),
      "idleRight": SpriteAtlas.fromGrid(MCIdleRight, TILE_SIZE * 4, TILE_SIZE, TILE_SIZE, TILE_SIZE),
      "movingLeft": SpriteAtlas.fromGrid(MCMovingLeft, TILE_SIZE * 4, TILE_SIZE, TILE_SIZE, TILE_SIZE),
      "movingRight": SpriteAtlas.fromGrid(MCMovingRight, TILE_SIZE * 4, TILE_SIZE, TILE_SIZE, TILE_SIZE),
    }
    
    _sprites = {
      "main": {
        "snowTileE":        Sprite2D.new(mainAtlas, 0),
        "snowTileNE":       Sprite2D.new(mainAtlas, 1),
        "snowTileLand":     Sprite2D.new(mainAtlas, 2),
        "redTile":          Sprite2D.new(mainAtlas, 3),
        "tree":             Sprite2D.new(mainAtlas, 4),
        "lanternOn":        Sprite2D.new(mainAtlas, 5),
        "wisp":             Sprite2D.new(mainAtlas, 6),
        "arrowNE":          Sprite2D.new(mainAtlas, 7),
        "snowTileS":        Sprite2D.new(mainAtlas, 8),
        "snowTileSW":       Sprite2D.new(mainAtlas, 9),
        "snowTileBase":     Sprite2D.new(mainAtlas, 10),
        "greenTile":        Sprite2D.new(mainAtlas, 11),
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

    _animatedSprites = {
      "units" : {
        "mc" : {
          "idleLeft":     AnimatedSprite2D.new(mcSpriteAtlas["idleLeft"],8),
          "idleRight":    AnimatedSprite2D.new(mcSpriteAtlas["idleRight"],8),
          "movingLeft":   AnimatedSprite2D.new(mcSpriteAtlas["movingLeft"],8),
          "movingRight":  AnimatedSprite2D.new(mcSpriteAtlas["movingRight"],8),
        }
      }
    }

    _time = 0

    _level0 = LevelTemplates.level0(_sprites, _animatedSprites)
    _level = Level.new(_level0)

    // grid tiles are the base
    var grid = _level0["grid"]
    _grid = _level.grid

    // units and projectiles are on top of the grid tiles
    _units = _level.units
    _projectiles = _level.projectiles

    // green = unit possible tiles
    // red = enemy "threat" tiles
    _greenTiles = []
    _redTiles = []
    
    // event
    _eventQueue = []

    _phase = null
    _phasesCompleted = []
    _phases = _level0["phases"]
    _nextPhase = "start"
    _phaseChanging = false
    _p = null

    _turn = 0
    _turnEvents = []
    _turnsExecuted = []

    _goalTile = Vec2.new(0,0)
    
    _gridSize = Vec2.new(0,0)

    for (entry in _level0["init"]) {
      if (entry.key == "grid") {
        var grid = entry.value

        if (grid.count > 0) {
         for (i in 0..grid.count-1) {
          var x = grid[i][0]
          var y = grid[i][1]
          var sprite = grid[i][2]

          var id = x + x*y
          var tile = Tile.new(x, y, sprite)

          _grid.add(tile)

          if (_gridSize.x < x || _gridSize.y < y) {
            _gridSize = Vec2.new(x, y)
          }
        }
        _grid.sort {|a, b| a.id < b.id }
        }
      }
      if (entry.key == "units") {
        var units = entry.value

        if (units.count > 0 ) {
          for (i in 0..units.count-1) {
            var x = units[i][0]
            var y = units[i][1]
            var name = units[i][2]
            var sprites = units[i][3]
            var hp = units[i][4]
            var speed = units[i][5]

            var unit = Unit.new(0, name, x, y, sprites, hp, speed)
            _units.add(unit)
          }
        }
      }
    }

    // player setup
    _player = Player.new(7)
    
  }

  frame(dt) {
    _time = _time + dt * 0.5

    if (Keyboard.isJustPressed(Key.ESCAPE)) {
      _selectedUnit = null
    }

    if (_phase == null) {
      if (Keyboard.isJustPressed(Key.ENTER)) {
        _phase = _nextPhase
      }
    }

    // level phases
    if (!_phasesCompleted.contains(_phase)) {
      _turnsExecuted = []
      _turn = 0
      for (entry in _phases) {
        if (_phase == entry.key) {
          _p = entry.value
          _nextPhase = _p["nextPhase"]
          _goalTile = Vec2.new(_p["goal"][0],_p["goal"][1]) 
        }
      }
      _phasesCompleted.add(_phase)
      return
    }

    if (_p != null) {
      if (!_turnsExecuted.contains(_turn)) {
        // PUT TURNED BASED EVENTS HERE
        for (i in _projectiles.count-1..-1) {
          if (i == -1) break

          var projectile = _projectiles[i]
          projectile.timer = projectile.timer - 1
        }
        
        for (i in _units.count-1..-1) {
          if (i == -1) break
          var unit = _units[i]
          if (unit.name == "lantern") {
            var mc = _units[0]
            var dist = (mc.vec2 - unit.vec2).magnitude 
            if (dist <= 1) {
              _player.addFuel(1)
            }
          }
        }
        //
        for (event in _p["turnEvents"]) {
          if (event.key == _turn) {
            var object = event.value
            for (o in object) {
              if (o.key == "events") {
                var events = o.value
                if (events.count > 0) {
                  for (i in 0..events.count-1) {
                    var event = events[i]

                    _level.executeEvent(event)
                  }
                }
              }
              if (o.key == "units") {
                var units = o.value
                if (units.count > 0) {
                  for (i in 0..units.count-1) {
                    var unit = units[i]
                    System.print("unit %(unit.name) spawned at %(unit.vec2)")
                    _units.add(units[i])
                  }
                }
              }
              if (o.key == "projectiles") {
                var projectiles = o.value
                if (projectiles.count > 0) {
                  for (i in 0..projectiles.count-1) {
                    _projectiles.add(projectiles[i])
                  }
                }
              }
              if (o.key == "tiles") {
                var tiles = o.value
                System.print(tiles)
                if (tiles.count > 0) {
                  for (i in 0..tiles.count-1) {
                    _grid.add(tiles[i])
                  }
                  _grid.sort {|a, b| a.id < b.id }
                }
              }
            }
          }
        }
        _turnsExecuted.add(_turn)
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

    var pointer = Vec2.new(Mouse.x(), Mouse.y())

    // FOR ALL GRID OBJECTS: always add GRID_OFFSET_X and GRID_OFFSET_Y to x and y
    // draw grid
    for (i in 0.._grid.count-1) {
      var tile = _grid[i]

      // FOG-OF-WAR
      // if (_units.count > 0) {
      //   var mc = _units[0]
      //   var fuel = _player.fuel
      //   var mag = (mc.vec2-tile.vec2).magnitude
      //   if (mag >= fuel/1.5) {
      //     continue
      //   }
      // }

      var x = GRID_OFFSET_X + (tile.x - tile.y) * TILE_SIZE
      var y = GRID_OFFSET_Y + (tile.x + tile.y) * TILE_SIZE/2

      tile.sprite.draw(x, y)
      var v = Tile.getTopSurfaceVectors(Vec2.new(x,y))
      if (Vec2.pointInQuad(pointer.x, pointer.y, v[0], v[1], v[2], v[3])) {
        _sprites["main"]["greenTile"].draw(x,y)
        _sprites["main"]["yellowIndicator"].draw(x,y)

        if (Mouse.isJustPressed(MouseButton.LEFT) || Keyboard.isJustPressed(Key.SPACE)) {
          System.print("Tile #%(tile.id): [%(tile.x),%(tile.y)]")
        }
      }
    }

    if (_selectedUnit != null) {
      var unit = _selectedUnit

      unit.drawScaled(128,600,128,dt)

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
          // MC movement logic
          if (Mouse.isJustPressed(MouseButton.LEFT)) {
            var fiber = Fiber.new {
              var target = Vec2.new(tile.x,tile.y)
              if (unit.vec2 != target) {
                unit.vec2 = Vec2.moveTowards(unit.vec2, target, unit.speed)    
              }
              Fiber.yield()
            }
            
            _selectedUnit = null
            _eventQueue.add(fiber)
            var mc = _units[0]
            for (i in _units.count-1..-1) {
              if (i == -1) break
              var unit = _units[i]
              if (unit.name == "lantern") {
                var mc = _units[0]
                var dist = (mc.vec2 - unit.vec2).magnitude 
                if (dist <= 1) {
                  _player.addFuel(1)
                }
              } else {
                _player.useFuel(1)
              }
            }
            _turn = _turn + 1
          }
        } else {
          _sprites["main"]["greenTile"].draw(x, y)
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

            var ptx = GRID_OFFSET_X + (tile.x - tile.y) * TILE_SIZE
            var pty = GRID_OFFSET_Y + (tile.x + tile.y) * TILE_SIZE/2

            if (!(tile.x == projectile.x && tile.y == projectile.y)) _sprites["main"]["redTile"].draw(ptx,pty)

            if (j > 0 && j < pt.count - 1) {
              tile = pt[j]
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
      for (i in _units.count-1..-1) {
        if (i == -1) break
        var unit = _units[i]

        // mc conditions
        if (unit.name == "mc") {
          if (unit.x == _goalTile.x && unit.y == _goalTile.y) {
            _phase = _nextPhase
            _turn = 0
            _turnExecuted = []
          }
          
          for (j in _units.count-1..-1) {
            if (j == -1) break
            var u = _units[j]
            
            if (unit.vec2 == u.vec2) {
              if (u.name == "wisp") {
                _units.removeAt(j)
                break
              }
            }
          }
        }

        var x = GRID_OFFSET_X + (unit.x - unit.y) * TILE_SIZE
        var y = GRID_OFFSET_Y + (unit.x + unit.y) * TILE_SIZE/2 - TILE_SIZE

        var w = TILE_SIZE
        var v1 = Vec2.new(x, y)
        var v2 = Vec2.new(x - w, y)
        var v3 = Vec2.new(x + w, y + w)
        var v4 = Vec2.new(x, y + w)

        if (Vec2.pointInQuad(pointer.x, pointer.y, v1, v2, v3, v4)) {
          unit.drawScaled(x-3,y-3, TILE_SIZE+6,dt)
          
          if (Mouse.isJustPressed(MouseButton.LEFT)) {
            _selectedUnit = unit            
            // mc
            if (_selectedUnit.name == "mc") {
              _greenTiles = Tile.getReachable(unit.x, unit.y, unit.speed)
            } else {
              _selectedUnit = null
            }
          }
        } else {
          unit.draw(x,y,dt)
        
        }

        // hp
        if (unit.hp > 0) {
          for (j in 1..unit.hp) {
            var size = 16
            var totalWidth = unit.hp * size
            var tx = x - totalWidth/2 + (j * size)
            var ty = y - size
            if (!unit.sprite.type == Map) unit.sprite.draw(tx,ty,size)
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
                  projectile.vec2 = Vec2.moveTowards(projectile.vec2, target, projectile.speed * 2)    
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

    // ALWAYS RESERVE FOR MC's Unit id to be 0
    if (_player.fuel > 0) {
      for (i in 0.._player.fuel) {
        var x = 100 + i * 50
        var y = 800
        _sprites["main"]["wisp"].draw(x,y)
      }
    }

    var x = GRID_OFFSET_X + (_goalTile.x - _goalTile.y) * TILE_SIZE
    var y = GRID_OFFSET_Y + (_goalTile.x + _goalTile.y) * TILE_SIZE/2 - TILE_SIZE
    _sprites["main"]["activeIndicator"].draw(x,y)

    if (_turn > 0) {
      for (i in 0.._turn-1) {
        _sprites["bullet"]["bullet"].draw(100 + i * 50, 1000)
        _sprites["bullet"]["bullet"].draw(100 + i * 50, 1000)
      }
    }
  }
}