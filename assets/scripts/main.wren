import "shapes" for Draw
import "gfx" for Texture2D
import "vector" for Vec2
import "collision" for Collision2D
import "input" for Mouse, MouseButton, Keyboard, Key

var GRID_SIZE = 8
var TILE_SIZE = 64 

var CENTER_X = 1280 / 2
var CENTER_Y = 720 / 2

var GRID_OFFSET_X = 500
var GRID_OFFSET_Y = 200

var ArrowBL = Texture2D.fromUri("http://localhost:3000/textures/arrows/arrowBL.png")
var ArrowBR = Texture2D.fromUri("http://localhost:3000/textures/arrows/arrowBR.png")
var ArrowTL = Texture2D.fromUri("http://localhost:3000/textures/arrows/arrowTL.png")
var ArrowTR = Texture2D.fromUri("http://localhost:3000/textures/arrows/arrowTR.png")
var ArrowUP = Texture2D.fromUri("http://localhost:3000/textures/arrows/arrowUP.png")

var SnowTileBase = Texture2D.fromUri("http://localhost:3000/textures/tiles/snow_tile_base.png")
var SnowTileLand = Texture2D.fromUri("http://localhost:3000/textures/tiles/snow_tile_land.png")
var SnowTileBottomLeft = Texture2D.fromUri("http://localhost:3000/textures/tiles/snow_tile_bottom_left.png")
var SnowTileBottomSide = Texture2D.fromUri("http://localhost:3000/textures/tiles/snow_tile_bottom_side.png")
var SnowTileLeftSide = Texture2D.fromUri("http://localhost:3000/textures/tiles/snow_tile_left_side.png")
var SnowTileRightBottomCorner = Texture2D.fromUri("http://localhost:3000/textures/tiles/snow_tile_right_bottom_corner.png")
var SnowTileRightSide = Texture2D.fromUri("http://localhost:3000/textures/tiles/snow_tile_right_side.png")
var SnowTileUpperLeftCorner = Texture2D.fromUri("http://localhost:3000/textures/tiles/snow_tile_upper_left_corner.png")
var SnowTileUpperSide = Texture2D.fromUri("http://localhost:3000/textures/tiles/snow_tile_upper_side.png")
var SnowTileRightCorner = Texture2D.fromUri("http://localhost:3000/textures/tiles/snow_top_right_corner.png")

var GreenTile = Texture2D.fromUri("http://localhost:3000/textures/tiles/green_tile.png")
var RedTile = Texture2D.fromUri("http://localhost:3000/textures/tiles/red_tile.png")

var Bullet = Texture2D.fromUri("http://localhost:3000/textures/bullets/bullet.png")
var BulletMS = Texture2D.fromUri("http://localhost:3000/textures/bullets/bullet_ms.png")

var Mountain = Texture2D.fromUri("http://localhost:3000/textures/environment/mountain.png")
var OakTree = Texture2D.fromUri("http://localhost:3000/textures/environment/oaktree.png")
var WispSprite = Texture2D.fromUri("http://localhost:3000/textures/units/wisp.png")

var LoremPicsum = Texture2D.fromUri("https://picsum.photos/64")

class Tile {
  construct new(id, x, y, texture) {
    _id = id
    _x = x
    _y = y
    _texture = texture
  }

  id { _id }
  x { _x }
  y { _y }
  texture { _texture }

  onClick(value) { _onClick = value }
  onHover(value) { _onHover = value }

  triggerClick( ){
    if (_onClick != null) {
      _onClick.call(this)
    }
  }

  triggerHover() {
    if (_onHover != null) {
      _onHover.call(this)
    }
  }

  static isCorner(x,y) {  
    return (x < 0) || (y < 0) || (x > GRID_SIZE - 1) || (y > GRID_SIZE - 1)
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

        if (isCorner(x-1,y-1)) continue
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

class Player {
  x { _x }
  y { _y }
  color { 0xFF0000FF }
  maxHP { _maxHP }
  hp { _hp }

  construct new(x, y, maxHP) {
    _x = x
    _y = y
    _maxHP = maxHP
    _hp = maxHP
  }

  takeDamage(points) {
    _hp = _hp - points
  }
}

class Enemy {
  vec2 { _vec2 }
  speed { _speed }
  color { 0xFF0000FF }

  construct new(vec2, speed) {
    _vec2 = vec2
    _speed = speed
  }
}

class Unit {
  construct new(id, x,y, w, h, texture) {
    _id = id
    _x = x
    _y = y
    _width = w
    _height = h
    _texture = texture
  }

  id { _id }
  x { _x }
  y { _y }
  width { _width }
  height { _height }
  texture { _texture }
  speed { 3 } // temporarily set for testing

  vec2 {
    return Vec2.new(_x, _y)
  }

  vec2=(value) {
    _x = value.x
    _y = value.y
  }
}

// direction must be "TOP_LEFT", "TOP_RIGHT", "BOTTOM_LEFT", "BOTTOM_RIGHT" 
class Projectile {
  construct new(x,y,direction,speed,timer, texture, texture2) {
    _x = x
    _y = y
    _direction = direction
    var targetTile = targetTile()
    _tx = targetTile.x
    _ty = targetTile.y
    _speed = speed
    _timer = timer
    _texture = texture
    _texture2 = texture2
  }

  x { _x }
  y { _y }
  tx { _tx }
  ty { _ty }
  speed { _speed }
  timer { _timer }
  texture { _texture }
  texture2 { _texture2 }
  
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
    if (_direction == "TOP_LEFT") {
      return Vec2.new(-1, _y)
    }
    if (_direction == "TOP_RIGHT") {
      return Vec2.new(_x, -1)
    }
    if (_direction == "BOTTOM_LEFT") {
      return Vec2.new(x, GRID_SIZE+1)
    }
    if (_direction == "BOTTOM_RIGHT") {
      return Vec2.new(GRID_SIZE+1, _y)
    }
    return Vec2.new(0,0)
  }

  projectTiles {
    var vi = Vec2.new(_x,_y)
    var vf = Vec2.new(_tx,_ty)

    return Vec2.line(vi, vf)
  }

  drawArrow {  
    if (_direction == "TOP_LEFT") {
      return ArrowTL
    }
    if (_direction == "TOP_RIGHT") {
      return ArrowTR
    }
    if (_direction == "BOTTOM_LEFT") {
      return ArrowBL
    }
    if (_direction == "BOTTOM_RIGHT") {
      return ArrowBR
    }
  }
}

class Main {
  construct init() {
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
      var tile = Tile.new(id, x, y, SnowTileLand)
      var onClick = Fn.new {
        System.print("Tile #%(id): [%(x),%(y)]")
      }
      tile.onClick(onClick)
      var onHover = Fn.new {
        Draw.texturedQuad(x, y - 10, TILE_SIZE, TILE_SIZE, tile.texture)
      }
      tile.onHover(onHover)
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

          var onClick = Fn.new {
            System.print("Tile #%(id): [%(x),%(y)]")
          }
          tile.onClick(onClick)
          var onHover = Fn.new {
            Draw.texturedQuad(x, y - 5  , TILE_SIZE, TILE_SIZE, tile.texture)
          }
          tile.onHover(onHover)
          _grid.add(tile)
        } else {
          addDefaultTile.call(id,x,y)
        }
      }
    }

    _wisp = Unit.new(1, 3, 3, TILE_SIZE, TILE_SIZE, WispSprite)
    _units.add(_wisp)

    _selectedUnit = null

    _bullet1 = Projectile.new(8, 2,"TOP_LEFT",2,1, Bullet, BulletMS)
    _bullet2 = Projectile.new(6, 8,"TOP_RIGHT",2,2, Bullet, BulletMS)
    _bullet3 = Projectile.new(3,-1,"BOTTOM_LEFT",2,3, Bullet, BulletMS)
    _bullet4 = Projectile.new(-1,5,"BOTTOM_RIGHT",2,4, Bullet, BulletMS)
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
      var y = GRID_OFFSET_Y + (tile.x + tile.y) * TILE_SIZE/2 + TILE_SIZE

      Draw.texturedQuad(x, y, TILE_SIZE, TILE_SIZE, tile.texture)

      var v1 = Vec2.new(x + (TILE_SIZE), y) // top vertex
      var v2 = Vec2.new(x + (TILE_SIZE), y + (TILE_SIZE)) // center vertex
      var v3 = Vec2.new(x, y + (TILE_SIZE/2)) // left vertex
      var v4 = Vec2.new(x + (TILE_SIZE * 2), y + (TILE_SIZE/2)) // right vertex

      if (Vec2.pointInQuad(pointer.x, pointer.y, v1, v2, v3, v4)) {
        if (Mouse.isJustPressed(MouseButton.LEFT)) {
          tile.triggerClick()
        }
      }
    }

    if (_selectedUnit != null) {
      var unit = _selectedUnit

      Draw.texturedQuad(0,600, 128,128, unit.texture)

      // draw green tiles
      for (i in 0.._greenTiles.count-1) {
        var tile = _greenTiles[i]
        var x = GRID_OFFSET_X + (tile.x - tile.y) * TILE_SIZE
        var y = GRID_OFFSET_Y + (tile.x + tile.y) * TILE_SIZE/2

        var v1 = Vec2.new(x + (TILE_SIZE), y) // top vertex
        var v2 = Vec2.new(x + (TILE_SIZE), y + (TILE_SIZE)) // center vertex
        var v3 = Vec2.new(x, y + (TILE_SIZE/2)) // left vertex
        var v4 = Vec2.new(x + (TILE_SIZE * 2), y + (TILE_SIZE/2)) // right vertex

        if (Vec2.pointInQuad(pointer.x, pointer.y, v1, v2, v3, v4)) {
          if (Mouse.isJustPressed(MouseButton.LEFT)) {
            _selectedUnit = null
            unit.vec2 = Vec2.new(tile.x, tile.y)
          }
        }

        Draw.texturedQuad(x, y, TILE_SIZE, TILE_SIZE, GreenTile)
      }
    }

    // draw red tiles
    if (_selectedUnit == null) {
      for (i in _projectiles.count-1..-1) {
        if (i == -1) break
        
        var projectile = _projectiles[i]

        var pt = projectile.projectTiles
        if (pt.count == null) {
          _projectiles.removeAt(i)
          continue
        }

        if (pt.count > 0) {
          for (j in 0..pt.count-1) {
            var tile = pt[j]

            if (tile.x < 0 || tile.y < 0 || tile.x > GRID_SIZE-1 || tile.y > GRID_SIZE-1) continue 

            var ptx = GRID_OFFSET_X + (tile.x - tile.y) * TILE_SIZE
            var pty = GRID_OFFSET_Y + (tile.x + tile.y) * TILE_SIZE/2 + TILE_SIZE

            Draw.texturedQuad(ptx, pty, TILE_SIZE, TILE_SIZE, RedTile)
          }
        }
      }
    }

    // draw units
    for (i in 0.._units.count-1) {
      var unit = _units[i]

      var x = GRID_OFFSET_X + (unit.x - unit.y) * TILE_SIZE
      var y = GRID_OFFSET_Y + (unit.x + unit.y) * TILE_SIZE/2 - TILE_SIZE

      var w = TILE_SIZE * 2
      var v1 = Vec2.new(x, y)
      var v2 = Vec2.new(x + w, y)
      var v3 = Vec2.new(x + w, y + w)
      var v4 = Vec2.new(x, y + w)

      if (Vec2.pointInQuad(pointer.x, pointer.y, v1, v2, v3, v4)) {
        Draw.texturedQuad( x - 3, y - 3 , unit.width + 3, unit.height + 3, unit.texture)
        
        if (Mouse.isJustPressed(MouseButton.LEFT) && _selectedUnit == null) {
          _selectedUnit = unit
          System.print(unit.id)

          if (_selectedUnit.id == 1) {
            _greenTiles = Tile.getReachable(unit.x, unit.y, unit.speed)
            System.print(_greenTiles)
          }
        }
      } else {
        Draw.texturedQuad(x, y, unit.width, unit.height, unit.texture)
        if (Mouse.isJustPressed(MouseButton.LEFT)) {
          _selectedUnit = null
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

      if (pt.count > 0) {
        var x = GRID_OFFSET_X + (projectile.x - projectile.y) * TILE_SIZE/1
        var y = GRID_OFFSET_Y + (projectile.x + projectile.y) * TILE_SIZE/2

        if (Tile.isCorner(projectile.x, projectile.y)) {
          Draw.texturedQuad(x, y, TILE_SIZE, TILE_SIZE, projectile.texture2)
        } else {
          Draw.texturedQuad(x, y, TILE_SIZE, TILE_SIZE, projectile.texture)
        }
        Draw.texturedQuad(x, y, TILE_SIZE, TILE_SIZE, projectile.drawArrow)

        if (projectile.timer > 0) {
            for (j in 1..projectile.timer) {
            var tx = x + j * 16
            var ty = y + 16
            Draw.texturedQuad(tx, ty, 16, 16, WispSprite)
          }
        } else {
          var steps = (projectile.speed) % pt.count
          for (step in 1..steps) {
            var fiber = Fiber.new {
              var target = pt[step]
              if (projectile.vec2 != target) {
                projectile.vec2 = Vec2.moveTowards(projectile.vec2, target, projectile.speed)    
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