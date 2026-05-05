class Vec2 {
    construct new(x, y) {
        _x = x
        _y = y
    }

    static fromPolar(r, theta) { new(r * theta.cos, r * theta.sin) }

    x { _x }
    y { _y }

    +(v) { Vec2.new(_x + v.x, _y + v.y) }
    -(v) { Vec2.new(_x - v.x, _y - v.y) }
    *(s) { Vec2.new(_x * s,   _y * s) }
    /(s) { Vec2.new(_x / s,   _y / s) }
    ==(other) { _x == other.x && _y == other.y}

    magnitude {
        return ( _x * _x + _y * _y).sqrt
    }

    static moveTowards(current, target, maxDistanceDelta) {
        var toVector = target - current
        var dist = toVector.magnitude

        if (dist <= maxDistanceDelta || dist == 0) {
            return target
        }

        return current + (toVector  / dist) * maxDistanceDelta
    }

    toString { "(%(_x), %(_y))" }

    static sign(px, py, ax, ay, bx, by) {
        return (px - bx) * (ay - by) - (ax - bx) * (py - by)
    }

    static pointInTriangle(px, py, ax, ay, bx, by, cx, cy) {
        var d1 = sign(px, py, ax, ay, bx, by)
        var d2 = sign(px, py, bx, by, cx, cy)
        var d3 = sign(px, py, cx, cy, ax, ay)

        var hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0)
        var hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0)

        return !(hasNeg && hasPos)
    }

    static pointInQuad(px, py, v1, v2, v3, v4) {
        return pointInTriangle(px, py, v1.x, v1.y, v2.x, v2.y, v3.x, v3.y) ||
            pointInTriangle(px, py, v1.x, v1.y, v3.x, v3.y, v4.x, v4.y)
    }
}