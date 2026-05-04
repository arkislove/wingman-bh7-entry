import "shapes" for Draw
import "gfx" for Texture2D
import "vector" for Vector2D

var GRID_SIZE = 8
var TILE_SIZE = 64

var CENTER_X = 1280 / 2
var CENTER_Y = 720 / 2

class Tile {
  id { _id }
  x { _x }
  y { _y }
  color { _color }

  construct new(id, x, y, color) {
    _id = id
    _x = x
    _y = y
    _color = color
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

class Ball {
  vec2 { _vec2 }
  
  construct new(vec2) {
    _vec2 = vec2
  }
}

var SnowTile = Texture2D.fromUri("http://localhost:3000/textures/snow_tile.png")


class Main {
  construct init() {
    _time = 0

    _grid = []
    _balls = []

    var startingX = 4 
    var startingY = 4

    for (i in 0..GRID_SIZE-1) {
      for (j in 0..GRID_SIZE-1) {
        var id = i + j
        
        var isoX = (i - j) * (TILE_SIZE)
        var isoY = (i + j) * (TILE_SIZE/2)
        var x = 500 + isoX
        var y = 300 + isoY
        var tile = Tile.new(id, x, y, 0xFFFFFFFF)
        _grid.add(tile)

        if (i == 3 && j == 3) {
          startingX = tile.x
          startingY = tile.y
        }
      }
    }

    _ball = Vector2D.new(300,300)
    _target = Vector2D.new(700,700)

  }

  frame(dt) {
    _time = _time + dt * 0.5

    // // draw tiles
    // for (i in 0.._grid.count-1) {
    //   var tile = _grid[i]
    //   Draw.texturedQuad(tile.x, tile.y, TILE_SIZE, TILE_SIZE, SnowTile  )
    // }

    Draw.circle(_ball.x, _ball.y, TILE_SIZE/2, 0xFF0000FF)
    if (_time > 3) {
      _ball = Vector2D.moveTowards(_ball, _target, 2)  
    }



  }
}
