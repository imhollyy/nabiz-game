# NABIZ — v0.1 Prototype

A one-touch, single-life 2D arcade prototype made with Godot 4.x and GDScript.

## Rules

- Tap/click to send a ring-shaped pulse.
- Pulse pushes **both** red threats and green energy away.
- Green energy reaching the core: **+1 point**.
- **One red impact ends the run immediately**. No extra life, revive, checkpoints or ad-based continuation.
- Tap the end screen to restart.
- The best score is saved locally in `user://nabiz_high_score.txt`.

## Run locally

1. Install Godot 4.x (recommended 4.3 or newer).
2. In Godot, choose **Import** and select `project.godot`.
3. Press F5 / **Run Project**.
4. Desktop: left click. Phone: tap the display (Android export to be added after prototype testing).

The project deliberately uses **no external assets, subscriptions, online services or backend**.

## Repository workflow

- `main`: reviewed code only.
- `feat/initial-game-prototype`: initial playable prototype.
- Subsequent PRs: scoring/combo, tuning, sound and effects, mobile export, test automation.

## Initial playtest checklist

- [ ] Tap from title screen starts a fresh game.
- [ ] Pulse pushes red and green particles outward.
- [ ] Green touching the core increases score by exactly 1.
- [ ] The **first** red touching the core immediately ends the game.
- [ ] Tapping after game over starts from zero.
- [ ] Record survives closing and reopening the game.
- [ ] Mouse and phone taps do not cause duplicate pulses.

## Scope notes

This is **not a release candidate**. The v0.1 prototype focuses on the core loop. Combo, leaderboards, sound, ads, monetization, store packaging and balancing are intentionally deferred.

The game name and visual direction are temporary working assets; review naming/trademark availability before publishing.
