extends Node2D
## NABIZ v0.1 — a single-life, one-touch score prototype.
## No external assets, network requests, ads or account system.

enum Phase { MENU, PLAYING, GAME_OVER }

const BG := Color("#0b1020")
const WHITE := Color("#ecf6ff")
const MUTED := Color("#8da6c7")
const CYAN := Color("#69ebf3")
const RED := Color("#ff697c")
const GREEN := Color("#6decae")
const CORE_RADIUS := 31.0
const PARTICLE_RADIUS := 11.0
const PULSE_COOLDOWN := 0.72
const PULSE_SPEED := 1400.0
const PULSE_MAX_RADIUS := 950.0
const PULSE_IMPULSE := 470.0
const BASE_SPAWN_INTERVAL := 1.10
const BEST_SCORE_PATH := "user://nabiz_high_score.txt"

var phase: Phase = Phase.MENU
var particles: Array[Dictionary] = []
var pulses: Array[Dictionary] = []
var score: int = 0
var best_score: int = 0
var seconds_alive: float = 0.0
var spawn_timer: float = 0.7
var pulse_timer: float = 0.0
var next_pulse_id: int = 0


func _ready() -> void:
	randomize()
	best_score = _load_best_score()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_on_tap()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_tap()


func _on_tap() -> void:
	if phase != Phase.PLAYING:
		_start_game()
		return
	if pulse_timer > 0.0:
		return
	pulse_timer = PULSE_COOLDOWN
	next_pulse_id += 1
	pulses.append({"id": next_pulse_id, "radius": 0.0})
	queue_redraw()


func _start_game() -> void:
	phase = Phase.PLAYING
	particles.clear()
	pulses.clear()
	score = 0
	seconds_alive = 0.0
	spawn_timer = 1.0
	pulse_timer = 0.0
	next_pulse_id = 0
	queue_redraw()


func _process(delta: float) -> void:
	if phase != Phase.PLAYING:
		return

	seconds_alive += delta
	pulse_timer = maxf(0.0, pulse_timer - delta)
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_particle()
		# Gradual increase in density; caps before becoming impossible.
		spawn_timer = maxf(0.40, BASE_SPAWN_INTERVAL - seconds_alive * 0.004)

	for i in range(pulses.size() - 1, -1, -1):
		pulses[i]["radius"] = float(pulses[i]["radius"]) + PULSE_SPEED * delta
		if float(pulses[i]["radius"]) > PULSE_MAX_RADIUS:
			pulses.remove_at(i)

	var center := get_viewport_rect().size / 2.0
	for i in range(particles.size() - 1, -1, -1):
		var particle: Dictionary = particles[i]
		var pos: Vector2 = particle["pos"]
		var vel: Vector2 = particle["vel"]
		var toward := (center - pos).normalized()
		var speed := float(particle["speed"])

		# A pulse pushes BOTH dangerous and beneficial particles away.
		for pulse in pulses:
			var pulse_id: int = pulse["id"]
			if int(particle["last_pulse_id"]) == pulse_id:
				continue
			if pos.distance_to(center) <= float(pulse["radius"]):
				vel += (pos - center).normalized() * PULSE_IMPULSE
				particle["last_pulse_id"] = pulse_id

		# Homing resumes gradually after the pulse kick.
		vel = vel.move_toward(toward * speed, 260.0 * delta)
		pos += vel * delta
		particle["pos"] = pos
		particle["vel"] = vel

		if pos.distance_to(center) <= CORE_RADIUS + PARTICLE_RADIUS * 0.65:
			if bool(particle["danger"]):
				_end_game()  # A single red impact ends the entire run.
				break
			score += 1
			particles.remove_at(i)
		elif pos.distance_to(center) > 1800.0:
			particles.remove_at(i)

	queue_redraw()


func _spawn_particle() -> void:
	var size := get_viewport_rect().size
	var edge := randi_range(0, 3)
	var margin := 18.0
	var pos := Vector2.ZERO
	match edge:
		0:
			pos = Vector2(randf_range(margin, size.x - margin), margin)
		1:
			pos = Vector2(size.x - margin, randf_range(margin, size.y - margin))
		2:
			pos = Vector2(randf_range(margin, size.x - margin), size.y - margin)
		_:
			pos = Vector2(margin, randf_range(margin, size.y - margin))
	var center := size / 2.0
	var speed := 105.0 + minf(seconds_alive * 1.10, 125.0) + randf_range(-12.0, 12.0)
	particles.append({
		"pos": pos,
		"vel": (center - pos).normalized() * speed,
		"speed": speed,
		"danger": randf() < 0.42,
		"last_pulse_id": -1
	})


func _end_game() -> void:
	phase = Phase.GAME_OVER
	pulses.clear()
	if score > best_score:
		best_score = score
		_save_best_score()
	queue_redraw()


func _load_best_score() -> int:
	if not FileAccess.file_exists(BEST_SCORE_PATH):
		return 0
	var file := FileAccess.open(BEST_SCORE_PATH, FileAccess.READ)
	if file == null:
		return 0
	return maxi(0, file.get_as_text().strip_edges().to_int())


func _save_best_score() -> void:
	var file := FileAccess.open(BEST_SCORE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(str(best_score))


func _draw() -> void:
	var size := get_viewport_rect().size
	var center := size / 2.0
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), BG)

	# A quiet orbital guide and glowing core, all generated from code.
	draw_arc(center, 105.0, 0.0, TAU, 96, Color(CYAN, 0.13), 2.0, true)
	draw_circle(center, 65.0, Color(CYAN, 0.055))
	draw_circle(center, 44.0, Color(CYAN, 0.13))
	draw_circle(center, CORE_RADIUS, Color("#25395a"))
	draw_arc(center, CORE_RADIUS, 0.0, TAU, 64, CYAN, 3.0, true)
	draw_circle(center, 15.0, Color("#f16b91"))
	draw_circle(center, 5.0, WHITE)

	for pulse in pulses:
		var radius: float = pulse["radius"]
		var alpha := 0.85 * (1.0 - radius / PULSE_MAX_RADIUS)
		draw_arc(center, radius, 0.0, TAU, 100, Color(CYAN, maxf(0.0, alpha)), 5.0, true)

	for particle in particles:
		var pos: Vector2 = particle["pos"]
		var color: Color = RED if bool(particle["danger"]) else GREEN
		draw_circle(pos, PARTICLE_RADIUS + 7.0, Color(color, 0.15))
		if bool(particle["danger"]):
			# Triangle adds a visual cue independent of the red/green color.
			var triangle := PackedVector2Array([
				pos + Vector2(0.0, -PARTICLE_RADIUS - 2.0),
				pos + Vector2(-PARTICLE_RADIUS - 2.0, PARTICLE_RADIUS),
				pos + Vector2(PARTICLE_RADIUS + 2.0, PARTICLE_RADIUS)
			])
			draw_colored_polygon(triangle, color)
		else:
			draw_circle(pos, PARTICLE_RADIUS, color)
			draw_circle(pos, 3.0, WHITE)

	if phase == Phase.PLAYING:
		_draw_centered(font, "SKOR  %d" % score, 88.0, 38, WHITE, size.x)
		_draw_centered(font, "TEK CAN", 120.0, 20, MUTED, size.x)
		_draw_centered(font, "DOKUN = NABIZ", size.y - 70.0, 20, MUTED, size.x)
	elif phase == Phase.MENU:
		_draw_centered(font, "NABIZ", center.y - 185.0, 64, WHITE, size.x)
		_draw_centered(font, "TEK DOKUNUS  •  TEK CAN", center.y - 130.0, 20, MUTED, size.x)
		_draw_centered(font, "YESIL = PUAN    KIRMIZI = SON", center.y + 185.0, 20, WHITE, size.x)
		_draw_centered(font, "BASLAMAK ICIN DOKUN", center.y + 235.0, 24, CYAN, size.x)
		_draw_centered(font, "EN IYI  %d" % best_score, size.y - 85.0, 20, MUTED, size.x)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#070b15aa"))
		_draw_centered(font, "OYUN BITTI", center.y - 100.0, 54, RED, size.x)
		_draw_centered(font, "SKOR  %d" % score, center.y - 32.0, 38, WHITE, size.x)
		_draw_centered(font, "EN IYI  %d" % best_score, center.y + 20.0, 25, MUTED, size.x)
		_draw_centered(font, "TEKRAR OYNAMAK ICIN DOKUN", center.y + 116.0, 23, CYAN, size.x)


func _draw_centered(font: Font, value: String, y: float, font_size: int, color: Color, width: float) -> void:
	draw_string(font, Vector2(0.0, y), value, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)
