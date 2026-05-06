import "vector" for Vec2

class Collision2D {
  static rectCollision(a,b) {
    var aLeft = a.x
    var aRight = a.x + a.width
    var aTop = a.y
    var aBottom = a.y + a.height

    var bLeft = b.x
    var bRight = b.x + b.width
    var bTop = b.y
    var bBottom = b.y + b.height

    return aRight > bLeft && aLeft < bRight && aBottom > bTop && aTop < bBottom
  }

  static quadCollision(a, b) {
    for (v in a.vertices) {
      if (Vec2.pointInQuad(v.x, v.y, b.vertices[0], b.vertices[1], b.vertices[2], b.vertices[3])) {
        return true
      }
    }

    for (v in b.vertices) {
      if (Vec2.pointInQuad(v.x, v.y, a.vertices[0], a.vertices[1], a.vertices[2], a.vertices[3])) {
        return true
      }
    }

    for (i in 0...4) {
      var a1 = a.vertices[i]
      var a2 = a.vertices[(i + 1) % 4]

      for (j in 0...4) {
        var b1 = b.vertices[j]
        var b2 = b.vertices[(j + 1) % 4]

        if (Vec2.linesIntersect(a1, a2, b1, b2)) {
          return true
        }
      }
    }

    return false
  }
}