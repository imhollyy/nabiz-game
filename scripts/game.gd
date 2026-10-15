extends Node2D
## NABIZ v0.2: one touch, one life, fair and rewarding pulse gameplay.
## A pulse DESTROYS red threats within range; green energy is unaffected.

enum Phase { MENU, PLAYING, GAME_OVER }

const BG := Color("#0b1020")
const WHITE := Color("#ecf6ff")
const MUTED := Color("#8da6c7")
const CYAN := Color("#69ebf3")
const RED := Color("#ff697c")
const GREEN := Color("#6decae")
const CORE_RADIUS := 31.0
const PARTICLE_RADIUS := 11.0
const SPAWN_DISTANCE := 300.0
const PULSE_COOLDOWN := 0.65
const PULSE_SPEED := 800.0
const PULSE_MAX_RADIUS := 215.0
const BASE_SPAWN_INTERVAL := 1.48
const MIN_SPAWN_INTERVAL := 0.95
const GREEN_SCORE := 5
const RED_SCORE := 10
const COMBO_WINDOW := 3.5
const BEST_SCORE_PATH := "user://nabiz_high_score.txt"

var phase: Phase = Phase.MENU
var particles: Array[Dictionary] = []
var pulses: Array[Dictionary] = []
var score: int = 0
var best_score: int = 0
var seconds_alive: float = 0.0
var spawn_timer: float = 0.65
var pulse_timer: float = 0.0
var spawn_count: int = 0
var last_red_spawn_at: float = -100.0
var red_combo: int = 0
var last_red_destroyed_at: float = -100.0
var feedback_text: String = ""
var feedback_color: Color = WHITE
var feedback_timer: float = 0.0


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

	# Prevent rapid tapping; player must time the next pulse.
	if pulse_timer > 0.0:
		return
	pulse_timer = PULSE_COOLDOWN
	pulses.append({"previous_radius": 0.0, "radius": 0.0})
	queue_redraw()


func _start_game() -> void:
	phase = Phase.PLAYING
	particles.clear()
	pulses.clear()
	score = 0
	seconds_alive = 0.0
	spawn_timer = 0.65
	pulse_timer = 0.0
	spawn_count = 0
	last_red_spawn_at = -100.0
	red_combo = 0
	last_red_destroyed_at = -100.0
	feedback_text = ""
	feedback_timer = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	if phase != Phase.PLAYING:
		return

	seconds_alive += delta
	pulse_timer = maxf(0.0, pulse_timer - delta)
	feedback_timer = maxf(0.0, feedback_timer - delta)
	if red_combo > 0 and seconds_alive - last_red_destroyed_at > COMBO_WINDOW:
		red_combo = 0

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_particle()
		# Gentle ramp: player gets time to learn; upper limit protects fairness.
		spawn_timer = maxf(MIN_SPAWN_INTERVAL, BASE_SPAWN_INTERVAL - seconds_alive * 0.003)

	# The wave is a moving ring with a MAXIMUM range, not a full-screen attack.
	for i in range(pulses.size() - 1, -1, -1):
		pulses[i]["previous_radius"] = float(pulses[i]["radius"])
		pulses[i]["radius"] = minf(PULSE_MAX_RADIUS, float(pulses[i]["radius"]) + PULSE_SPEED * delta)
		if float(pulses[i]["previous_radius"]) >= PULSE_MAX_RADIUS:
			pulses.remove_at(i)

	var center := get_viewport_rect().size / 2.0
	for i in range(particles.size() - 1, -1, -1):
		var particle: Dictionary = particles[i]
		var pos: Vector2 = particle["pos"]
		var distance := pos.distance_to(center)
		var is_danger: bool = particle["danger"]

		# Only RED threats are destroyed by a pulse. Green is never pushed away.
		if is_danger:
			var destroyed := false
			for pulse in pulses:
				var outer: float = pulse["radius"]
				var inner: float = pulse["previous_radius"]
				# Crossing check accommodates movement between rendered frames.
				if distance <= outer + PARTICLE_RADIUS and distance >= inner - PARTICLE_RADIUS:
					destroyed = true
					break
			if destroyed:
				particles.remove_at(i)
				_award_red()
				continue

		# All remaining particles travel straight toward the core.
		var direction := (center - pos).normalized()
		var speed: float = particle["speed"]
		pos += direction * speed * delta
		particle["pos"] = pos
		distance = pos.distance_to(center)

		if distance <= CORE_RADIUS + PARTICLE_RADIUS * 0.65:
			particles.remove_at(i)
			if is_danger:
				_end_game() # Exactly one red impact = immediate game over.
				break
			score += GREEN_SCORE
			_show_feedback("+%d ENERJI" % GREEN_SCORE, GREEN)
		elif distance > 1800.0:
			particles.remove_at(i)

	queue_redraw()


func _award_red() -> void:
	if seconds_alive - last_red_destroyed_at <= COMBO_WINDOW:
		red_combo = mini(red_combo + 1, 3)
	else:
		red_combo = 1
	last_red_destroyed_at = seconds_alive
	var points := RED_SCORE * red_combo
	score += points
	if red_combo > 1:
		_show_feedback("+%d  KOMBO x%d" % [points, red_combo], CYAN)
	else:
		_show_feedback("+%d SAVUNMA" % points, CYAN)


func _show_feedback(value: String, color: Color) -> void:
	feedback_text = value
	feedback_color = color
	feedback_timer = 0.75


func _spawn_particle() -> void:
	# All particles appear at a predictable distance from the core.
	var size := get_viewport_rect().size
	var center := size / 2.0
	var angle := randf_range(0.0, TAU)
	var pos := center + Vector2.from_angle(angle) * SPAWN_DISTANCE

	# Three opening green energies: scoring is possible BEFORE the first danger.
	var is_danger := false
	if spawn_count == 3:
		is_danger = true
	elif spawn_count > 3:
		var enough_space_since_red := seconds_alive - last_red_spawn_at >= 2.2
		is_danger = enough_space_since_red and randf() < minf(0.45, 0.33 + seconds_alive * 0.0012)

	if is_danger:
		last_red_spawn_at = seconds_alive
	spawn_count += 1
	var base_speed := 125.0 if is_danger else 160.0
	var speed := base_speed + minf(seconds_alive * 0.33, 43.0)
	particles.append({
		"pos": pos,
		"speed": speed,
		"danger": is_danger
	})


func _end_game() -> void:
	phase = Phase.GAME_OVER
	pulses.clear()
	feedback_text = ""
	feedback_timer = 0.0
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

	# Range indicator: red threats can only be hit INSIDE this ring.
	draw_arc(center, PULSE_MAX_RADIUS, 0.0, TAU, 96, Color(CYAN, 0.25), 2.0, true)
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
			# Triangle shape marks danger even for users with color-vision differences.
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
		var pulse_status := "NABIZ HAZIR" if pulse_timer <= 0.0 else "NABIZ DOLUYOR"
		_draw_centered(font, pulse_status, size.y - 69.0, 22, CYAN if pulse_timer <= 0.0 else MUTED, size.x)
		if feedback_timer > 0.0:
			_draw_centered(font, feedback_text, center.y - 98.0, 27, feedback_color, size.x)
	elif phase == Phase.MENU:
		_draw_centered(font, "NABIZ", center.y - 185.0, 64, WHITE, size.x)
		_draw_centered(font, "TEK DOKUNUS  -  TEK CAN", center.y - 130.0, 20, MUTED, size.x)
		_draw_centered(font, "YESIL TOPLA: +5", center.y + 162.0, 25, GREEN, size.x)
		_draw_centered(font, "KIRMIZIYI YOK ET: +10", center.y + 203.0, 23, RED, size.x)
		_draw_centered(font, "BASLAMAK ICIN DOKUN", center.y + 251.0, 24, CYAN, size.x)
		_draw_centered(font, "EN IYI  %d" % best_score, size.y - 75.0, 20, MUTED, size.x)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#070b15aa"))
		_draw_centered(font, "OYUN BITTI", center.y - 100.0, 54, RED, size.x)
		_draw_centered(font, "SKOR  %d" % score, center.y - 32.0, 38, WHITE, size.x)
		_draw_centered(font, "EN IYI  %d" % best_score, center.y + 20.0, 25, MUTED, size.x)
		_draw_centered(font, "TEKRAR OYNAMAK ICIN DOKUN", center.y + 116.0, 23, CYAN, size.x)


func _draw_centered(font: Font, value: String, y: float, font_size: int, color: Color, width: float) -> void:
	draw_string(font, Vector2(0.0, y), value, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)
