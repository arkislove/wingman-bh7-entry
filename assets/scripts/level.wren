import "vector" for Vec2
import "sprites" for Sprite2D, AnimatedSprite2D
import "units" for Unit, UnitType
import "projectiles" for Projectile, ProjectileType, ProjectileEffect

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

  vec2 { 
    return Vec2.new(_x,_y)
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

class Event {
  static CREATE_TILE          { 0 }
  static DESTROY_TILE         { 1 }
  static CREATE_UNIT          { 2 }
  static DESTROY_UNIT         { 3 }
  static CREATE_PROJECTILE    { 4 }
  static DESTROY_PROJECTILE   { 5 }
}

class Level {
  construct new(template, sprites, animatedSprites) {
    _template = template
    _sprites = sprites
    _animatedSprites = animatedSprites
    _grid = []
    _units = []
    _projectiles = []

    _unitId = 0
    _projectileId = 0
  }

  template { _template }

  sprites { _sprites }
  sprites=(value){
    _sprites = value
  }

  unitId() {
    return _unitId = _unitId + 1 
  }
  projectileId() {
    return _projectileId = _projectileId + 1  
  }

  grid { _grid }
  grid=(value) { _grid = (value)}
  sortGrid() { _grid.sort {|a, b| a.id < b.id }}

  units { _units }
  units=(value) { _units = (value)}

  projectiles { _projectiles }
  projectiles=(value) { _projectiles = (value)}

  executeEvent(event) {
    var type = event["type"]

    if (type == Event.CREATE_TILE) {
      var x = event["x"]
      var y = event["y"]
      var sprite = event["sprite"]
      createTile(x,y,sprite)
    }

    if (type == Event.DESTROY_TILE) {
      var x = event["x"]
      var y = event["y"]
      destroyTile(x,y)
    }

    if (type == Event.CREATE_UNIT) {
      var x = event["x"]
      var y = event["y"]

      var unitType = event["unitType"]
      createUnit(x,y,unitType)
    }

    if (type == Event.CREATE_PROJECTILE) {
      var x = event["x"]
      var y = event["y"]
      var tx = event["targetX"]
      var ty = event["targetY"]
      var speed = event["speed"]
      var waitTime = event["waitTime"]
      var projectileType = event["projectileType"]
      createProjectile(x, y, tx, ty, speed, waitTime, projectileType)
    }
  }

  createTile(x,y,sprite) {
    var newTile = Tile.new(x,y,sprite)
    _grid.add(newTile)
    sortGrid()
  }

  destroyTile(x,y) {
    for (i in _grid.count-1..-1) {
      if (i == -1) break

      var tile = _grid[i]
      if (tile.vec2 == Vec2.new(x,y)) {
        _grid.removeAt(i)
        return
      }
    }
  }

  createUnit(x,y,type) {
    var id = unitId()
    var sprite = null
    var hp = null
    var speed = null

    if (type == UnitType.MC) {
      sprite = _animatedSprites["units"]["mc"]
      hp = 5
      speed = 1
    }

    if (type == UnitType.WISP) {
      sprite = _sprites["main"]["wisp"]
      hp = 3
      speed = 0
    }

    if (type == UnitType.LANTERN) {
      sprite = _sprites["main"]["lanternOn"]
      hp = 3
      speed = 0
    }
    
    if (sprite == null) {
      sprite = _sprites["main"]["wisp"]
    }
    
    var newUnit = Unit.new(id, type, x, y, sprite, hp, speed)
    _units.add(newUnit)
  }

  destroyUnit(id) {
    for (i in _units.count-1..-1) {
      if (i == -1) break

      var unit = _units[i]
      if (unit.id == id) {
        _unit.removeAt(i)
        return
      }
    }
  }

  createProjectile(x, y, tx, ty, speed, waitTime, type) {
    var id = projectileId()
    var effects = []
    var sprite = null

    System.print(_sprites["bullet"]["bullet"])
    if (type == ProjectileType.Bullet) {
      sprite = _sprites["bullet"]["bullet"]
      effects = [
        ProjectileEffect.DEAL_DAMAGE,
      ]
    }

    if (type == ProjectileType.Boulder) {
      sprite = _sprites["bullet"]["bullet"]
      effects = [
        ProjectileEffect.DEAL_DAMAGE,
        ProjectileEffect.KNOCKBACK
      ]
    }

    if (type == ProjectileType.Avalanche) {
      // not yet implemented
    }

    if (sprite == null) System.print("no sprite for projectile id: %(id) ")

    var newProjectile = Projectile.new(id, type, x, y, tx,ty, effects, speed, waitTime, sprite)
    _projectiles.add(newProjectile)
  }

  isOnATile(obj) {
    for (i in 0.._grid.count-1) {
      var tile = _grid[i]
      if (obj.vec2 == tile.vec2) {
        return true
      } 
    }

    return false 
  }

  projectilesWaitTimeDown() {
    for (i in _projectiles.count-1..-1) {
      if (i == -1) break
      var projectile = _projectiles[i]
      projectile.waitTime = projectile.waitTime - 1
    }
  } 
}

class LevelTemplates {
  static level0 (sprites, animatedSprites) {
    return {
      "init" : [
        {
          "type": Event.CREATE_TILE,
          "x": 3,
          "y": 0,
          "sprite": sprites["main"]["snowTileBase"]
        },
        {
          "type": Event.CREATE_TILE,
          "x": 3,
          "y": 1,
          "sprite": sprites["main"]["snowTileLand"]
        },
        {
          "type": Event.CREATE_TILE,
          "x": 3,
          "y": 2,
          "sprite": sprites["main"]["snowTileBase"]
        },
        {
          "type": Event.CREATE_TILE,
          "x": 4,
          "y": 0,
          "sprite": sprites["main"]["snowTileBase"]
        },
        {
          "type": Event.CREATE_TILE,
          "x": 4,
          "y": 1,
          "sprite": sprites["main"]["snowTileBase"]
        },
        {
          "type": Event.CREATE_TILE,
          "x": 4,
          "y": 2,
          "sprite": sprites["main"]["snowTileBase"]
        },
        {
          "type": Event.CREATE_TILE,
          "x": 5,
          "y": 0,
          "sprite": sprites["main"]["snowTileBase"]
        },
        {
          "type": Event.CREATE_TILE,
          "x": 5,
          "y": 1,
          "sprite": sprites["main"]["snowTileBase"]
        },
        {
          "type": Event.CREATE_TILE,
          "x": 5,
          "y": 2,
          "sprite": sprites["main"]["snowTileBase"]
        },
        {
          "type": Event.CREATE_TILE,
          "x": 6,
          "y": 0,
          "sprite": sprites["main"]["snowTileBase"]
        },
        {
          "type": Event.CREATE_TILE,
          "x": 6,
          "y": 1,
          "sprite": sprites["main"]["snowTileBase"]
        },
        {
          "type": Event.CREATE_TILE,
          "x": 6,
          "y": 2,
          "sprite": sprites["main"]["snowTileBase"]
        },
        {
          "type": Event.CREATE_TILE,
          "x": 7,
          "y": 0,
          "sprite": sprites["main"]["snowTileBase"]
        },
        {
          "type": Event.CREATE_TILE,
          "x": 7,
          "y": 1,
          "sprite": sprites["main"]["snowTileBase"]
        },
        {
          "type": Event.CREATE_TILE,
          "x": 7,
          "y": 2,
          "sprite": sprites["main"]["snowTileBase"]
        },
        {
          "type": Event.CREATE_TILE,
          "x": 8,
          "y": 0,
          "sprite": sprites["main"]["snowTileBase"]
        },
        {
          "type": Event.CREATE_TILE,
          "x": 8,
          "y": 1,
          "sprite": sprites["main"]["snowTileBase"]
        },
        {
          "type": Event.CREATE_TILE,
          "x": 8,
          "y": 2,
          "sprite": sprites["main"]["snowTileBase"]
        },
      ],
      "phases": {
        "start" : {
          "goal": [3,1],
          "nextPhase": "getLantern",
          "turnEvents": {
            0 : [
              {
                "type": Event.CREATE_UNIT,
                "x": 8,
                "y": 1,
                "unitType": UnitType.MC,
              },
              {
                "type": Event.CREATE_UNIT,
                "x": 3,
                "y": 1,
                "unitType": UnitType.WISP
              },
              {
                "type": Event.CREATE_PROJECTILE,
                "x": 7,
                "y": 3,
                "targetX": 7,
                "targetY": -1,
                "speed": 1,
                "waitTime": 1,
                "projectileType": ProjectileType.Bullet
              }, 
              {
                "type": Event.CREATE_PROJECTILE,
                "x": 6,
                "y": -1,
                "targetX": 6,
                "targetY": 3,
                "speed": 1,
                "waitTime": 2,
                "projectileType": ProjectileType.Bullet
              },
              {
                "type": Event.CREATE_PROJECTILE,
                "x": 5,
                "y": 3,
                "targetX": 5,
                "targetY": -1,
                "speed": 1,
                "waitTime": 3,
                "projectileType": ProjectileType.Bullet
              },
            ],
          },
        },
        "getLantern" : {
          "goal": [5,1],
          "nextPhase": "trap",
          "turnEvents": {
            0: [
              {
                "type": Event.CREATE_UNIT,
                "x": 5,
                "y": 1,
                "unitType": UnitType.LANTERN,
              }
            ],
            1: [
              {
                "type": Event.DESTROY_TILE,
                "x": 3,
                "y": 2,
              },
              {
                "type": Event.DESTROY_TILE,
                "x": 3,
                "y": 1,
              },
              {
                "type": Event.DESTROY_TILE,
                "x": 3,
                "y": 0,
              },
              {
                "type": Event.DESTROY_TILE,
                "x": 4,
                "y": 0,
              },
              {
                "type": Event.DESTROY_TILE,
                "x": 5,
                "y": 0,
              },
              {
                "type": Event.DESTROY_TILE,
                "x": 6,
                "y": 0,
              },
              {
                "type": Event.DESTROY_TILE,
                "x": 7,
                "y": 0,
              },
              {
                "type": Event.DESTROY_TILE,
                "x": 8,
                "y": 0,
              }
            ],
          },
        },
        "trap" : {  
          "goal": [4,4],
          "nextPhase": "end",
          "turnEvents": {
            0: [
              {
                "type" : Event.CREATE_TILE,
                "x": 0,
                "y": 4,
                "sprite": sprites["main"]["snowTileLand"]
              },
              {
                "type" : Event.CREATE_TILE,
                "x": 1,
                "y": 4,
                "sprite": sprites["main"]["snowTileBase"]
              },
              {
                "type" : Event.CREATE_TILE,
                "x": 2,
                "y": 4,
                "sprite": sprites["main"]["snowTileBase"]
              },
              {
                "type" : Event.CREATE_TILE,
                "x": 3,
                "y": 4,
                "sprite": sprites["main"]["snowTileBase"]
              },
              {
                "type" : Event.CREATE_TILE,
                "x": 4,
                "y": 4,
                "sprite": sprites["main"]["snowTileBase"]
              },
              {
                "type" : Event.CREATE_TILE,
                "x": 4,
                "y": 3,
                "sprite": sprites["main"]["snowTileBase"]
              },
            ],
          },
        },
        "end" : {
          "goal": [0,4],
          "nextPhase": null,
          "turnEvents": {
            0: [
              {
                "type": Event.CREATE_PROJECTILE,
                "x": 4,
                "y": 5,
                "targetX": 4,
                "targetY": -1,
                "speed": 1,
                "waitTime": 1,
                "projectileType": ProjectileType.Bullet
              },
              {
                "type": Event.CREATE_PROJECTILE,
                "x": 5,
                "y": 3,
                "targetX": 5,
                "targetY": 3,
                "speed  ": 1,
                "waitTime": 2,
                "projectileType": ProjectileType.Bullet
              },
              {
                "type": Event.CREATE_PROJECTILE,
                "x": 2,
                "y": 5,
                "targetX": 2,
                "targetY": 3,
                "speed": 1,
                "waitTime": 3,
                "projectileType": ProjectileType.Bullet
              },
              {
                "type": Event.CREATE_PROJECTILE,
                "x": 1,
                "y": 5,
                "targetX": 1,
                "targetY": 3,
                "speed": 1,
                "waitTime": 3,
                "projectileType": ProjectileType.Bullet
              },
              {
                "type": Event.CREATE_PROJECTILE,
                "x": 1,
                "y": 3,
                "targetX": 1,
                "targetY": 5,
                "speed": 1,
                "waitTime": 4,
                "projectileType": ProjectileType.Bullet
              },
              {
                "type": Event.CREATE_PROJECTILE,
                "x": 2,
                "y": 3,
                "targetX": 2,
                "targetY": 5,
                "speed": 1,
                "waitTime": 4,
                "projectileType": ProjectileType.Bullet
              },
              {
                "type": Event.CREATE_PROJECTILE,
                "x": 3,
                "y": 3,
                "targetX": 3,
                "targetY": 5,
                "speed": 1,
                "waitTime": 5,
                "projectileType": ProjectileType.Bullet
              },
            ]
          },
        },
      },
    }
  }
}