extends Node
## Shared pixel-ish drawing helpers

static func draw_panel(ci: CanvasItem, rect: Rect2, fill: Color, border: Color) -> void:
	ci.draw_rect(rect, fill, true)
	ci.draw_rect(rect, border, false, 2.0)
	var s := 3.0
	ci.draw_rect(Rect2(rect.position, Vector2(s, s)), Color(0.36, 0.55, 1.0, 0.5), true)
	ci.draw_rect(Rect2(rect.position + Vector2(rect.size.x - s, 0), Vector2(s, s)), Color(0.36, 0.55, 1.0, 0.5), true)
	ci.draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - s), Vector2(s, s)), Color(0.36, 0.55, 1.0, 0.5), true)
	ci.draw_rect(Rect2(rect.position + Vector2(rect.size.x - s, rect.size.y - s), Vector2(s, s)), Color(0.36, 0.55, 1.0, 0.5), true)
