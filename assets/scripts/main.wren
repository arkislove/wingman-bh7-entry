import "shapes" for Draw
import "gfx" for Texture2D
import "vector" for Vec2
import "collision" for Collision2D
import "input" for Mouse, MouseButton, Keyboard, Key

var GRID_SIZE = 1
var TILE_SIZE = 64

var GRID_OFFSET_X = 500
var GRID_OFFSET_Y = 200

var CENTER_X = 1280 / 2
var CENTER_Y = 720 / 2

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

class StraightMovement {
  construct new(angle) {
    _angle = angle
  }

  move(obj) {
    var dx = obj.speed * _angle.cos
    var dy = obj.speed * _angle.sin
    obj.move(dx,dy)
  }
}

class RovingXMovement {
  direction { _direction }
  construct new(direction, width) {
    _direction = direction
    _width = width
    _t = width/2
  }

  move(obj) {
    var dx = obj.speed * _direction
    var dy = 0
    obj.move(dx,dy)

    _t = _t + 1

    if (_t >= _width) {
      _t = 0
      _direction = -_direction
    } 
  }
}

class RovingYMovement {
  direction { _direction }
  construct new(direction, width) {
    _direction = direction
    _width = width
    _t = width/2
  }

  move(obj) {
    var dx = 0
    var dy = obj.speed * _direction
    obj.move(dx,dy)

    _t = _t + 1

    if (_t >= _width) {
      _t = 0
      _direction = -_direction
    } 
  }
}

class Pattern {
  static createCrossBalls(anchor, group) {
      var ball = Enemy.new(anchor.x + TILE_SIZE / 2, anchor.y + TILE_SIZE / 2, 3, StraightMovement.new(Num.tau + Num.pi/4)) // bottom-right
      group.add(ball)
      ball = Enemy.new(anchor.x + TILE_SIZE / 2, anchor.y + TILE_SIZE / 2, 3, StraightMovement.new(Num.tau/2 + Num.pi/4)) // top-left
      group.add(ball)
      ball = Enemy.new(anchor.x + TILE_SIZE / 2, anchor.y + TILE_SIZE / 2, 3, StraightMovement.new(Num.tau/4 + Num.pi/4)) // bottom-left
      group.add(ball)
      ball = Enemy.new(anchor.x + TILE_SIZE / 2, anchor.y + TILE_SIZE / 2, 3, StraightMovement.new(3*Num.tau/4 + Num.pi/4)) // top-right
      group.add(ball)
  }

  static createPlusBalls(anchor, group) {
    var ball = Enemy.new(anchor.x + TILE_SIZE / 2, anchor.y + TILE_SIZE / 2, 3, StraightMovement.new(Num.tau)) // right
    group.add(ball)
    ball = Enemy.new(anchor.x + TILE_SIZE / 2, anchor.y + TILE_SIZE / 2, 3, StraightMovement.new(Num.tau/2)) // left
    group.add(ball)
    ball = Enemy.new(anchor.x + TILE_SIZE / 2, anchor.y + TILE_SIZE / 2, 3, StraightMovement.new(Num.tau/4)) // bottom
    group.add(ball)
    ball = Enemy.new(anchor.x + TILE_SIZE / 2, anchor.y + TILE_SIZE / 2, 3, StraightMovement.new(3*Num.tau/4)) // top
    group.add(ball)
  }

  static createEightBalls(anchor, group) {
    var ball = Enemy.new(anchor.x + TILE_SIZE / 2, anchor.y + TILE_SIZE / 2, 3, StraightMovement.new(Num.tau)) // right
    group.add(ball)
    ball = Enemy.new(anchor.x + TILE_SIZE / 2, anchor.y + TILE_SIZE / 2, 3, StraightMovement.new(Num.tau/2)) // left
    group.add(ball)
    ball = Enemy.new(anchor.x + TILE_SIZE / 2, anchor.y + TILE_SIZE / 2, 3, StraightMovement.new(Num.tau/4)) // bottom
    group.add(ball)
    ball = Enemy.new(anchor.x + TILE_SIZE / 2, anchor.y + TILE_SIZE / 2, 3, StraightMovement.new(3*Num.tau/4)) // top
    group.add(ball)
    ball = Enemy.new(anchor.x + TILE_SIZE / 2, anchor.y + TILE_SIZE / 2, 3, StraightMovement.new(Num.tau + Num.pi/4)) // bottom-right
    group.add(ball)
    ball = Enemy.new(anchor.x + TILE_SIZE / 2, anchor.y + TILE_SIZE / 2, 3, StraightMovement.new(Num.tau/2 + Num.pi/4)) // top-left
    group.add(ball)
    ball = Enemy.new(anchor.x + TILE_SIZE / 2, anchor.y + TILE_SIZE / 2, 3, StraightMovement.new(Num.tau/4 + Num.pi/4)) // bottom-left
    group.add(ball)
    ball = Enemy.new(anchor.x + TILE_SIZE / 2, anchor.y + TILE_SIZE / 2, 3, StraightMovement.new(3*Num.tau/4 + Num.pi/4)) // top-right
    group.add(ball)
  }

  static shootLaser(anchor, group) {
    var start 
    var ball = Enemy.new(anchor.x + TILE_SIZE / 2, anchor.y + TILE_SIZE / 2)
  }
}

class UI {
  static drawHP(anchor) {
    return Draw.quad(anchor.x, anchor.y - 30, anchor.hp, 5, 0x00FF00FF)
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

class Ball {
  construct new(x,y,r) {
    _x = x
    _y = y
    _radius = r
  }

  x { _x }
  y { _y }
  radius { _radius }

  movement { _movement }
  
  movement=(value) {
    _movement = value
  }

  vec2 {
    return Vec2.new(_x, _y)
  }

  vec2=(value) {
    _x = value.x
    _y = value.y
  }
}

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

var Bullet = Texture2D.fromUri("http://localhost:3000/textures/bullet/bullet.png")
var BulletMS = Texture2D.fromUri("http://localhost:3000/textures/bullet/bullet_ms.png")

var Mountain = Texture2D.fromUri("http://localhost:3000/textures/environment/mountain64px.png")
var Olaf = Texture2D.fromUri("http://localhost:3000/textures/olaf.png")

var LoremPicsum = Texture2D.fromUri("https://picsum.photos/64")

class Main {
  construct init() {
    _time = 0

    _demoLevel = []
    
    // grid tiles are the base
    _grid = []

    // units
    _units = []

    // movement tiles
    // green = unit possible tiles
    // red = enemy "threat" tiles
    _greenTiles = []
    _redTiles = []

    _balls = []

    var startingX = 4
    var startingY = 4

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

        if (i == 4 && j == 4) {
          startingX = x
          startingY = y
        }

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

    _olaf = Unit.new(1, startingX , startingY, TILE_SIZE, TILE_SIZE, Olaf)
    _units.add(_olaf)

    _selectedUnit = null
  }

  frame(dt) {
    _time = _time + dt * 0.5

    var pointer = Vec2.new(Mouse.x(), Mouse.y())


    // FOR ALL GRID OBJECTS: always add GRID_OFFSET_X and GRID_OFFSET_Y to x and y
    // draw grid
    for (i in 0.._grid.count-1) {
      var tile = _grid[i]

      var x = GRID_OFFSET_X + ((tile.x - tile.y) * TILE_SIZE)
      var y = GRID_OFFSET_Y + ((tile.x + tile.y) * TILE_SIZE/2) + TILE_SIZE

      Draw.texturedQuad(x, y, TILE_SIZE, TILE_SIZE, tile.texture)

      var v1 = Vec2.new(x + (TILE_SIZE), y) // top vertex
      var v2 = Vec2.new(x + (TILE_SIZE), y + (TILE_SIZE)) // center vertex
      var v3 = Vec2.new(x, y + (TILE_SIZE/2)) // left vertex
      var v4 = Vec2.new(x + (TILE_SIZE * 2), y + (TILE_SIZE/2)) // right vertex

      if (Vec2.pointInQuad(pointer.x, pointer.y, v1, v2, v3, v4)) {
        if (Mouse.isJustPressed(MouseButton.LEFT)) {
          tile.triggerClick()
        }
        Draw.texturedQuad(x,y, TILE_SIZE,TILE_SIZE, LoremPicsum)
      }
    }

    if (_selectedUnit != null) {
      var unit = _selectedUnit

      Draw.texturedQuad(0,600, 128,128, unit.texture)

      // draw available tiles
      for (i in 0.._greenTiles.count-1) {
        var x = GRID_OFFSET_X + (_greenTiles[i].x - _greenTiles[i].y) * TILE_SIZE
        var y = GRID_OFFSET_Y + (_greenTiles[i].x + _greenTiles[i].y) * TILE_SIZE/2

        var v1 = Vec2.new(x + (TILE_SIZE), y) // top vertex
        var v2 = Vec2.new(x + (TILE_SIZE), y + (TILE_SIZE)) // center vertex
        var v3 = Vec2.new(x, y + (TILE_SIZE/2)) // left vertex
        var v4 = Vec2.new(x + (TILE_SIZE * 2), y + (TILE_SIZE/2)) // right vertex

        if (Vec2.pointInQuad(pointer.x, pointer.y, v1, v2, v3, v4)) {
          if (Mouse.isJustPressed(MouseButton.LEFT)) {
            unit.vec2 = Vec2.new(_greenTiles[i].x,_greenTiles[i].y)
            _selectedUnit = null
          }
        }

        Draw.texturedQuad(x, y, TILE_SIZE, TILE_SIZE, GreenTile)
      }
    }

    // draw units
    for (i in 0.._units.count-1) {
      var unit = _units[i]

      var x = GRID_OFFSET_X + (unit.x - unit.y) * TILE_SIZE
      var y = GRID_OFFSET_Y + (unit.x + unit.y) * TILE_SIZE/2 - TILE_SIZE

      var v1 = Vec2.new(x + (TILE_SIZE), y)
      var v2 = Vec2.new(x + (TILE_SIZE), y + (TILE_SIZE))
      var v3 = Vec2.new(x, y + (TILE_SIZE/2))
      var v4 = Vec2.new(x + (TILE_SIZE * 2), y + (TILE_SIZE/2))

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
  }
}