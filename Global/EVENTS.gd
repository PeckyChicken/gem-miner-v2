extends Node
class_name event_class

signal MouseClicked(button,position)

signal TileClicked(tile)
signal TilePlaced(x,y,type)
signal TileHovered(tile)

signal PlaySound(path)
signal DeleteTiles(tiles)
signal AddScore(score)
signal DestroyBricks(gems)
signal CreateLightning(point_a,point_b,color)
signal Explode(x,y)

signal GameOver()
signal DeselectTools()

signal UpdateHover()

signal Pause()
signal Resume()
signal Quit()
signal Restart()

signal LanguageChanged(locale)

enum Type {
	board,
	pit,
	tool,
	selected,
	preview
}
