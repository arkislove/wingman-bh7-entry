class Vector2D {
    construct new(x, y) {
        _x = x
        _y = y
    }

    static fromPolar(r, theta) { new(r * theta.cos, r * theta.sin) }

    x { _x }
    y { _y }

    +(v) { Vector2D.new(_x + v.x, _y + v.y) }
    -(v) { Vector2D.new(_x - v.x, _y - v.y) }
    *(s) { Vector2D.new(_x * s,   _y * s) }
    /(s) { Vector2D.new(_x / s,   _y / s) }

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
}