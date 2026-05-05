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
}