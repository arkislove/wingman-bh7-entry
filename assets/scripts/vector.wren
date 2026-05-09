class Vec2 {
  construct new(x, y) {
    _x = x
    _y = y
  }

  // converts polar coordinates -> Cartesian (x,y) 
  static fromPolar(r, theta) { new(r * theta.cos, r * theta.sin) }

  x { _x }
  y { _y }

  +(v) { Vec2.new(_x + v.x, _y + v.y) }
  -(v) { Vec2.new(_x - v.x, _y - v.y) }
  *(s) { Vec2.new(_x * s,   _y * s) }
  /(s) { Vec2.new(_x / s,   _y / s) }
  ==(other) { _x == other.x && _y == other.y}
  >(other) { _x > other.x && y > other.y}
  <(other) { _x < other.x && y < other.y}

  magnitude {
    return ( _x * _x + _y * _y).sqrt
  }

  // use this move an object's Vec2 position towards target in a STRAIGHT LINE by maxDistanceDelta per frame
  // `current` is a Vec2
  // `target` is a Vec2   
  // `maxDistanceDelta` is a number
  static moveTowards(current, target, maxDistanceDelta) {
    var toVector = target - current
    var dist = toVector.magnitude

    if (dist <= maxDistanceDelta || dist == 0) {
        return target
    }

    return current + (toVector  / dist) * maxDistanceDelta
  }

  toString { "(%(_x), %(_y))" }

  // determines which side of the line the point is
  static sign(px, py, ax, ay, bx, by) {
    return (bx - ax) * (py - ay) - (by - ay) * (px - ax)
  }

  // determines if point is in triangle
  static pointInTriangle(px, py, ax, ay, bx, by, cx, cy) {
    var d1 = sign(px, py, ax, ay, bx, by)
    var d2 = sign(px, py, bx, by, cx, cy)
    var d3 = sign(px, py, cx, cy, ax, ay)

    var hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0)
    var hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0)

    return !(hasNeg && hasPos)
  }

  // determines if point is in quad 
  static pointInQuad(px, py, v1, v2, v3, v4) {
    return pointInTriangle(px, py, v1.x,v1.y, v2.x,v2.y, v3.x,v3.y) ||
      pointInTriangle(px, py, v2.x,v2.y, v3.x,v3.y, v4.x,v4.y) ||
      pointInTriangle(px, py, v1.x,v1.y, v3.x,v3.y, v4.x,v4.y)
  }

  // generates all the integer points between two positions
  static line(from, to) {
    var result = []

    var dx = (to.x - from.x).sign
    var dy = (to.y - from.y).sign

    var x = from.x
    var y = from.y

    result.add(Vec2.new(x, y))

    while (x != to.x || y != to.y) {
        if (x != to.x) x = x + dx
        if (y != to.y) y = y + dy
        result.add(Vec2.new(x, y))
    }

    return result
  }

  // determines if two lines intersect
  static linesIntersect(p1, p2, p3, p4) {
    var d1 = Vec2.sign(p3.x, p3.y, p1.x, p1.y, p2.x, p2.y)
    var d2 = Vec2.sign(p4.x, p4.y, p1.x, p1.y, p2.x, p2.y)
    var d3 = Vec2.sign(p1.x, p1.y, p3.x, p3.y, p4.x, p4.y)
    var d4 = Vec2.sign(p2.x, p2.y, p3.x, p3.y, p4.x, p4.y)

    return (d1 * d2 < 0) && (d3 * d4 < 0)
  }
}