extends Node
class_name event_class

signal MouseClicked(button,position)
signal TileClicked(tile)
signal TilePlaced(x,y,type)
signal PlaySound(path)
signal DeleteTiles(tiles)
signal AddScore(score)
signal DestroyBricks(gems)
signal CreateLightning(point_a,point_b,color)
signal Explode(x,y)

signal GameOver()
signal DeselectTools()

enum Type {
	board,
	pit,
	tool,
	selected
}
