# NABIZ — v0.2 Balanced Prototype

One-touch, **one-life**, high-score arcade prototype for Godot 4.x.

## Core loop

- **Green circle**: moves toward the core and awards **+5** on arrival. Pulses do **not** affect greens.
- **Red triangle**: moves toward the core; if it touches the core even once, the run **ends immediately**.
- **Tap/click**: sends an outward pulse, which **destroys** red threats that cross the wave.
- The pulse has a **limited range (215 game pixels)**, marked by a faint circle, and a **0.65-second cooldown**.
- Red destruction awards **+10**. Consecutive destroys within 3.5 seconds increase the award (x2, up to x3); combo expires if not renewed.
- Each run opens with **three green particles before the first red** to teach the scoring loop.
- Red spawns are spaced apart; spawn density and speed grow slowly.
- Best score is stored on the device in `user://nabiz_high_score.txt`.

**One-life rule is non-negotiable:** no health bar, revive, rewarded-ad continuation, second chance or checkpoints.

## Run locally

1. Install Godot 4.x, preferably 4.3+.
2. Clone or download the `feat/initial-game-prototype` branch.
3. In Godot Project Manager select **Import**, then open `project.godot`.
4. Press **F5** or **Run Project**.
5. Desktop: left mouse click. Mobile: screen tap (Android export is a later task).

After a code update, re-download the branch or run `git pull` on that branch. Don't test an older extracted ZIP.

## Changes since v0.1

The first prototype made scores frustrating: pulse repelled *both* colors, and every red returned repeatedly. The revision removes those incentives:
- Reds are now permanently destroyed when pulse reaches them.
- Greens always fly to the core without being repelled.
- Limited pulse radius creates meaningful timing.
- Gentler initial spawn schedule guarantees several early scoring opportunities.
- Immediate +5 / +10 onscreen feedback and simple red-defense combos make successful actions legible.

## Manual playtest checklist — v0.2

- [ ] Menu appears; one click starts a new run at score zero.
- [ ] Three green circles arrive before the first red triangle appears.
- [ ] Each green touching the core awards **+5**.
- [ ] Pulsing near a green has **no effect** on its trajectory.
- [ ] A red triangle hit by a pulse disappears permanently and awards **+10** (with possible combo multiplier).
- [ ] Pulses do **not** destroy reds outside the faint maximum-range ring.
- [ ] Rapid taps during pulse cooldown do not create extra pulses.
- [ ] First red contacting the core ends the run **immediately**.
- [ ] One click on game-over starts a fresh run; score returns to zero.
- [ ] Best score persists after exiting and reopening.
- [ ] Play for two minutes: frequency rises gradually without impossible early stacks.
- [ ] Test both mouse and touchscreen before release.

## Project workflow

- `main` — reviewed, merged code only.
- `feat/initial-game-prototype` — PR #1, **do not merge until playtested**.
- Future: feel/juice and sound, rhythm-based perfect pulse, Android export, accessibility, store release.

No assets, paid services, backend, ads or internet connection required for v0.2.
Visuals and game name are placeholders until publishing decisions.
