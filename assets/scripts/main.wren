import "shapes" for Draw
import "sprites" for SpriteAtlas, Sprite2D, AnimatedSprite2D
import "gfx" for Texture2D
import "vector" for Vec2, Direction
import "collision" for Collision2D
import "input" for Mouse, MouseButton, Keyboard, Key
import "level" for Tile, LevelTemplates, Level
import "units" for UnitType, Unit 
import "projectiles" for  ProjectileType, Projectile, ProjectileEffect
import "text" for TextMesh

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

var BulletNE = Texture2D.fromUri("http://localhost:3000/textures/projectiles/bullet/bullet_spritesheet_NE.png")
var BulletNW = Texture2D.fromUri("http://localhost:3000/textures/projectiles/bullet/bullet_spritesheet_NW.png")
var BulletSE = Texture2D.fromUri("http://localhost:3000/textures/projectiles/bullet/bullet_spritesheet_SE.png")
var BulletSW = Texture2D.fromUri("http://localhost:3000/textures/projectiles/bullet/bullet_spritesheet_SW.png")

var DangerIcon = Texture2D.fromUri("http://localhost:3000/textures/icons/danger_extreme.png") 

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
    var w = TILE_SIZE
    // sprite
    var mainAtlas =     SpriteAtlas.fromGrid(Spritesheet, w * 8, w * 4, w, w)

    var mcSpriteAtlas = {
      "idleLeft":     SpriteAtlas.fromGrid(MCIdleLeft, w * 4, w, w, w),
      "idleRight":    SpriteAtlas.fromGrid(MCIdleRight, w * 4, w, w, w),
      "movingLeft":   SpriteAtlas.fromGrid(MCMovingLeft, w * 4, w, w, w),
      "movingRight":  SpriteAtlas.fromGrid(MCMovingRight, w * 4, w, w, w),
    }

    var bulletAtlas = {
      "NE": SpriteAtlas.fromGrid(BulletNE, w * 4, w, w, w),
      "NW": SpriteAtlas.fromGrid(BulletNW, w * 4, w, w, w),
      "SE": SpriteAtlas.fromGrid(BulletSE, w * 4, w, w, w),
      "SW": SpriteAtlas.fromGrid(BulletSW, w * 4, w, w, w),
    }

    var dangerAtlas = {
      "default": SpriteAtlas.fromGrid(DangerIcon, w * 4, w, w, w)
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
      },
      "projectiles": {
        "bullet": {
          "NE": AnimatedSprite2D.new(bulletAtlas["NE"],8),
          "NW": AnimatedSprite2D.new(bulletAtlas["NW"],8),
          "SE": AnimatedSprite2D.new(bulletAtlas["SE"],8),
          "SW": AnimatedSprite2D.new(bulletAtlas["SW"],8),
        }
      },
      "icons": {
        "danger": AnimatedSprite2D.new(dangerAtlas["default"],1)
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
    _warnings = _level.warnings

    // green = unit possible tiles
    // red = enemy "threat" tiles
    _greenTiles = []
    _redTiles = []
    
    // event
    _eventQueue = []

    _phase = null
    _phasesInitialized = []
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
        _phaseChanging = true
      }
    }

 // PHASE ENTRY
    if (_p != null && !_phaseChanging) {
      if (!_turnsExecuted.contains(_turn)) {
        // PUT PER-TURN EVENTS HERE
        System.print("Phase: %(_phase), Turn %(_turn)")

        if (_turn != 0) {
          _eventQueue.add(Fiber.new{
            _level.projectilesWaitTimeDown()
          })

          for (i in _warnings.count-1..-1) {
            if (i == -1) break

            var warning = _warnings[i]
            warning.duration = warning.duration - 1
            if (warning.duration <= 0) {
              _warnings.removeAt(i)
            }
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
              }
            }
          }
        }
        _turnsExecuted.add(_turn)
      }
    }

    if (!_phasesInitialized.contains(_phase)) {
      _turnsExecuted = []
      _turn = 0
      for (entry in _phases) {
        if (_phase == entry.key) {
          _p = entry.value
          _nextPhase = _p["nextPhase"]
          _goalTile = Vec2.new(_p["goal"][0],_p["goal"][1]) 
        }
      }
      _phaseChanging = false
      _phasesInitialized.add(_phase)
    }

    // phase completion check
    if (_units.count > 0) {
      var mc = _units[0]

      if (mc.vec2 == _goalTile) {
        _phase = _nextPhase
        _phaseChanging = true
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
      for (i in _greenTiles.count-1..-1) {
        if (i == -1) break
        
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
            var targetVec = Vec2.new(tile.x,tile.y)
            var fiber = Fiber.new {
              if (unit.vec2 != targetVec) {
                unit.vec2 = Vec2.moveTowards(unit.vec2, targetVec, unit.speed)    
              }

              if (unit.type == UnitType.MC) {
                unit.setDirection(Vec2.getDirection(unit.vec2,targetVec))
                if (unit.direction == Direction.NW || unit.direction == Direction.SW) {
                  unit.setSprite(unit.sprite["movingLeft"])
                }
                if (unit.direction == Direction.NE || unit.direction == Direction.SE) {
                  unit.setSprite(unit.sprite["movingRight"])
                }
              }
            }
            
            _eventQueue.add(fiber)
            _selectedUnit = null
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

        var x = GRID_OFFSET_X + (unit.x - unit.y) * TILE_SIZE
        var y = GRID_OFFSET_Y + (unit.x + unit.y) * TILE_SIZE/2 - TILE_SIZE

        var w = TILE_SIZE
        var v1 = Vec2.new(x, y)
        var v2 = Vec2.new(x - w, y)
        var v3 = Vec2.new(x + w, y + w)
        var v4 = Vec2.new(x, y + w)

        if (Vec2.pointInQuad(pointer.x, pointer.y, v1, v2, v3, v4)) {
          if (unit.currentSprite.type == Sprite2D) {
            unit.sprite.draw(x-3,y-3,TILE_SIZE+3)
          }
          if (unit.currentSprite.type == AnimatedSprite2D) {
            unit.currentSprite.draw(x-3,y-3,TILE_SIZE+3)
            unit.currentSprite.update(dt)
          }

          if (Mouse.isJustPressed(MouseButton.LEFT)) {
            _selectedUnit = unit            
            // mc
            if (_selectedUnit.type == UnitType.MC) {
              _greenTiles = _level.getReachable(unit.x, unit.y, unit.speed)
            } else {
              _selectedUnit = null
            }
          }
        } else {
          if (unit.type == UnitType.MC) {
            if (unit.direction == Direction.NW || unit.direction == Direction.SW) {
              unit.setSprite(unit.sprite["idleLeft"])
            }
            if (unit.direction == Direction.NE || unit.direction == Direction.SE) {
              unit.setSprite(unit.sprite["idleRight"])
            }
          }
          if (unit.currentSprite.type == Sprite2D) {
            unit.currentSprite.draw(x,y)
          } 
          if (unit.currentSprite.type == AnimatedSprite2D) {
            unit.currentSprite.draw(x,y)
            unit.currentSprite.update(dt)
          }
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
        
        if (projectile.currentSprite.type == AnimatedSprite2D) {
          var dir = Vec2.getDirection(projectile.vec2,projectile.targetVec2)
          if (dir == Direction.NW) projectile.setSprite(projectile.sprite["NW"])
          if (dir == Direction.NE) projectile.setSprite(projectile.sprite["NE"])
          if (dir == Direction.SW) projectile.setSprite(projectile.sprite["SW"])
          if (dir == Direction.SE) projectile.setSprite(projectile.sprite["SE"])

          var sprite = projectile.currentSprite
          sprite.draw(x,y)
          sprite.update(dt)
        } else {
          projectile.sprite.draw(x,y)
        }
        TextMesh.draw(x-4,y, "%(projectile.id)", 16, 0xFFFFFFFF)

        
        if (pt.count > 0) {
          if (projectile.waitTime > 0) {
            for (j in 1..projectile.waitTime) {
              if (!_level.isOnATile(projectile)) {
                TextMesh.draw(x-4,y - 32, "%(projectile.waitTime)", 16, 0xFFFFFFFF)
              }
            }
          } else {
            var target = pt[1]
            _eventQueue.add(Fiber.new {
              while ((projectile.vec2 - target).magnitude > 0){
                if (projectile.vec2 == target) break
                var speed = projectile.speed * dt
                projectile.vec2 = Vec2.moveTowards(projectile.vec2, target, speed)
                
              }
              
              // unit collision checkers
              for (u in _units.count-1..-1) {
                if (u == -1) break
                
                var unit = _units[u]
                if (projectile.vec2 == unit.vec2) {
                  System.print("%(projectile) %(i) hit unit %(u): %(unit.vec2)")
                  if (unit.type == UnitType.MC) {
                    if (projectile.effects.count > 0) {
                      for (e in 0..projectile.effects.count-1) {
                        var effect = projectile.effects[e]
                        
                        if (effect == ProjectileEffect.DEAL_DAMAGE) {
                          _eventQueue.add(Fiber.new {
                            _player.useFuel(1)
                          })
                        }
                        if (effect == ProjectileEffect.KNOCKBACK) {
                          var dir = Vec2.getDirection(projectile.vec2, projectile.targetVec2)
                          var uv = unit.vec2
                          var tv = null
                          if (dir == Direction.NW) tv = uv + Vec2.new(-1,0)
                          if (dir == Direction.NE) tv = uv + Vec2.new(0,-1)
                          if (dir == Direction.SW) tv = uv + Vec2.new(0,1)
                          if (dir == Direction.SE) tv = uv + Vec2.new(1,0)
                          _eventQueue.add(Fiber.new{
                            unit.vec2 = Vec2.moveTowards(uv, tv, 1)
                            Fiber.yield()
                          })
                        }
                      }
                    }
                  }
                  _projectiles.removeAt(i)
                }
              }
            })
          }
        }
      }
    }

    // draw warning
    for (i in _warnings.count-1..-1) {
      if (i == -1) break

      var x = GRID_OFFSET_X + (_warnings[i].x - _warnings[i].y) * TILE_SIZE
      var y = GRID_OFFSET_Y + (_warnings[i].x + _warnings[i].y) * TILE_SIZE/2 - TILE_SIZE
      _animatedSprites["icons"]["danger"].draw(x,y)
      _animatedSprites["icons"]["danger"].update(dt)
    }

    // draw fuel count
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
  }
}