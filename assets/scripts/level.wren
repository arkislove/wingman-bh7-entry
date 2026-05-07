class Level {
  construct new() {
    _sprites = {}
  }

  sprites { _sprites }
  sprites=(value){
    _sprites = value
  }
  
  static level0 (sprites) {
    return {
      "grid" : [
        [0,4, sprites["main"]["snowTileBase"]],
        [1,4, sprites["main"]["snowTileBase"]],
        [2,2, sprites["main"]["snowTileBase"]],
        [2,4, sprites["main"]["snowTileBase"]],
        [3,4, sprites["main"]["snowTileBase"]],
        [3,0, sprites["main"]["snowTileBase"]],
        [3,1, sprites["main"]["snowTileBase"]],
        [3,2, sprites["main"]["snowTileBase"]],
        [3,4, sprites["main"]["snowTileBase"]],
        [4,0, sprites["main"]["snowTileBase"]],
        [4,2, sprites["main"]["snowTileBase"]],
        [4,1, sprites["main"]["snowTileBase"]],
        [4,3, sprites["main"]["snowTileBase"]],
        [4,4, sprites["main"]["snowTileBase"]],
        [5,0, sprites["main"]["snowTileBase"]],
        [5,1, sprites["main"]["snowTileBase"]],
        [5,2, sprites["main"]["snowTileBase"]],
        [6,0, sprites["main"]["snowTileBase"]],
        [6,1, sprites["main"]["snowTileBase"]],
        [6,2, sprites["main"]["snowTileBase"]],
        [7,-1, sprites["main"]["snowTileBase"]],
        [7,0, sprites["main"]["snowTileBase"]],
        [7,1, sprites["main"]["snowTileBase"]],
        [7,2, sprites["main"]["snowTileBase"]],
      ],
      "units" : [
        [2,2, sprites["main"]["mountain"]],
        [2,1, sprites["main"]["mountain"]],
        [2,0, sprites["main"]["mountain"]],
        [2,-1, sprites["main"]["mountain"]],
        [3,-1, sprites["main"]["mountain"]],
        [4,-1, sprites["main"]["mountain"]],
        [5,-1, sprites["main"]["mountain"]],
        [6,-1, sprites["main"]["mountain"]],
        [7,-1, sprites["main"]["mountain"]],
      ]
    }
  }
}