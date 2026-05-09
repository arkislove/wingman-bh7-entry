import "shapes" for Draw
import "sprites" for SpriteAtlas, Sprite2D, AnimatedSprite2D
import "gfx" for Texture2D
import "vector" for Vec2
import "collision" for Collision2D
import "input" for Mouse, MouseButton, Keyboard, Key
import "level" for Tile, LevelTemplates, Level
import "units" for UnitType, Unit 
import "projectiles" for Direction, ProjectileType, Projectile, ProjectileEffect

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
    var mainAtlas =     SpriteAtlas.fromGrid(Spritesheet, TILE_SIZE * 8, TILE_SIZE * 4, TILE_SIZE, TILE_SIZE)
    var bulletAtlas =   SpriteAtlas.fromGrid(Bullet, TILE_SIZE, TILE_SIZE, TILE_SIZE, TILE_SIZE)
    var bulletMSAtlas = SpriteAtlas.fromGrid(BulletMS, TILE_SIZE, TILE_SIZE, TILE_SIZE, TILE_SIZE)
    var mcSpriteAtlas = {
      "idleLeft":       SpriteAtlas.fromGrid(MCIdleLeft, TILE_SIZE * 4, TILE_SIZE, TILE_SIZE, TILE_SIZE),
      "idleRight":      SpriteAtlas.fromGrid(MCIdleRight, TILE_SIZE * 4, TILE_SIZE, TILE_SIZE, TILE_SIZE),
      "movingLeft":     SpriteAtlas.fromGrid(MCMovingLeft, TILE_SIZE * 4, TILE_SIZE, TILE_SIZE, TILE_SIZE),
      "movingRight":    SpriteAtlas.fromGrid(MCMovingRight, TILE_SIZE * 4, TILE_SIZE, TILE_SIZE, TILE_SIZE),
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
        "yellowBorder":     Sprite2D.new(mainAtlas, 19),
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

    var level0 = LevelTemplates.level0(_sprites, _animatedSprites)
    _level = Level.new(level0, _sprites, _animatedSprites)

    // grid tiles are the base
    var grid = level0["grid"]
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
    _phases = level0["phases"]
    _nextPhase = "start"
    _phaseChanging = false
    _p = null

    _turn = 0
    _turnEvents = []
    _turnsExecuted = []

    _goalTile = Vec2.new(0,0)
    
    _gridSize = Vec2.new(0,0)

    for (event in level0["init"]) {
      _level.executeEvent(event)
    }

    // player setup
    _player = Player.new(7) 

    _history = []
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

    // PHASE ENTRY
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
        System.print("Phase: %(_phase), Turn %(_turn)")
        System.print("History: %(_history)")

        if (_turn != 0) {
          _eventQueue.add(Fiber.new{
            _level.projectilesWaitTimeDown()
          })
        }
        
        for (i in _units.count-1..-1) {
          if (i == -1) break
          var unit = _units[i]
          if (unit.type == UnitType.LANTERN) {
            var mc = _units[0]
            var dist = (mc.vec2 - unit.vec2).magnitude 
            if (dist <= 1) {
              _player.addFuel(1)
            }
          }
        }
        _selectedUnit = null
        // END

        for (turnEvents in _p["turnEvents"]) {
          if (turnEvents.key == _turn) {
            var events = turnEvents.value
            if (events.count > 0) {
              for (i in 0..events.count-1) {
                var event = events[i]

                _level.executeEvent(event)
                System.print("Event: %(event["type"])")
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
        _history.add(_eventQueue)
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

      var v = Tile.getTopSurfaceVectors(Vec2.new(x,y))
      if (Vec2.pointInQuad(pointer.x, pointer.y, v[0], v[1], v[2], v[3])) {
        tile.sprite.draw(x, y+5)
        _sprites["main"]["yellowBorder"].draw(x,y-1)

        if (Mouse.isJustPressed(MouseButton.LEFT) || Keyboard.isJustPressed(Key.SPACE)) {
          System.print("Tile #%(tile.id): [%(tile.x),%(tile.y)]")
        }
      } else {
        tile.sprite.draw(x, y)
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
            }
            
            _selectedUnit = null
            _eventQueue.add(fiber)
            var mc = _units[0]
            for (i in _units.count-1..-1) {
              if (i == -1) break
              var unit = _units[i]
              if (unit.type == UnitType.LANTERN) {
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
          _sprites["main"]["greenTile"].draw(x,y+5)
          _sprites["main"]["yellowBorder"].draw(x,y)
        } else {
          _sprites["main"]["greenTile"].draw(x,y)
        }
      }
    }

    // draw red tiles
    if (_selectedUnit == null) {
      for (i in _projectiles.count-1..-1) {
        if (i == -1) break

        var skip = false
        
        var projectile = _projectiles[i]
        
        var pt = projectile.line
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

            if (!(tile.x == projectile.x && tile.y == projectile.y)) {
              _sprites["main"]["redTile"].draw(ptx,pty)
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

        // MC conditions
        if (unit.type == UnitType.MC) {
          if (unit.x == _goalTile.x && unit.y == _goalTile.y) {
            _phase = _nextPhase
            _turn = 0
            _turnExecuted = []
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
            if (_selectedUnit.type == UnitType.MC) {
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

        var pt = projectile.line
        if (pt.count == null) {
          _projectiles.removeAt(i)
          continue
        }

        var x = GRID_OFFSET_X + (projectile.x - projectile.y) * TILE_SIZE
        var y = GRID_OFFSET_Y + (projectile.x + projectile.y) * TILE_SIZE / 2 - TILE_SIZE
        
        projectile.sprite.draw(x,y)
        if (pt.count > 0) {

          if (projectile.waitTime > 0) {
            for (j in 1..projectile.waitTime) {
              var size = 16
              var totalWidth = projectile.waitTime * size
              var tx = x - totalWidth/2 + (j * size)
              var ty = y - size
              if (!_level.isOnATile(projectile)) {
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
                    if (projectile.effects.count > 0) {
                      for (i in 0..projectile.effects.count-1) {
                        var effect = projectile.effects[i]
                        
                        if (effect == ProjectileEffect.DEAL_DAMAGE) {
                          _eventQueue.add(Fiber.new {
                            _player.useFuel(1)
                          })
                        }
                        if (effect == ProjectileEffect.KNOCKBACK) {

                        }
                      }
                    }
                    _projectiles.removeAt(i)
                  }
                }
              }
              _eventQueue.add(fiber)
            }
            projectile.waitTime = 1
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