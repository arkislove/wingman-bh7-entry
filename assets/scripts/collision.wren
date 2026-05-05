import "vector" for Vec2

class Collision2D {
    static checkCollision(a,b) {
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
}