# GDD

Written from the Unity version ([TrainRush](https://github.com/tiago-xavier-braga/TrainRush)),
which is the reference for the port.
Numbers come from its scenes and ScriptableObjects.

## Pitch

An arcade tycoon game: you run a two-platform train station. Open the gates so passengers queue
up and board the wagons, then pull the lever to send the train off. Every passenger pays a
ticket, and the coins buy more wagons, more seats and faster trains.

## Overview

- **Genre:** Arcade tycoon (idle-like)
- **Art:** 3D low poly (Kenney kits), top-down camera
- **Platform:** Web build on GitHub Pages, desktop and mobile browsers
- **References:** Hypercasual "tycoon" games where you walk over plates to buy upgrades

## Core Loop

1. Player does: walks to a plate and stands on it (opens a gate, releases the train, buys an
   upgrade)
2. Game responds: passengers queue and board, the train leaves, coins come in
3. Player decides: which station and which upgrade to spend the coins on
4. Repeat: every upgrade makes each train trip pay more or come back sooner

## Rules

### Station layout

Two identical stations, one on each side of the tracks (the left one is the right one turned
180 degrees). Each station has its own train, 4 fence gates, 4 wagon queues, a traffic light
with a lever and 3 upgrade plates. The coins are shared.

### Player

- Moves on the ground plane with WASD, the arrow keys or the left stick; on mobile, an
  on-screen joystick.
- Speed: 5 m/s. Turns smoothly to face the movement direction.
- The camera follows the player from a fixed offset (18 m up, 18 m back), looking at them.

### Pressure plates

- Every interaction is a plate on the floor. The player stands on it and holds still for
  **2 s** to trigger it; leaving the plate resets the timer.
- A plate shows its price. It animates when the player can afford it and plays a success or
  failure sound when triggered.

### Passengers

- Each station has a pool of 50 passengers (random Kenney mini characters). They appear at a
  random point in a 10 x 7 m spawn area and walk to the end of a gate queue.
- A passenger who waits idle for **15 s** shows a random angry emote for 5 s, then the timer
  restarts.

### Fence gates

- 4 revolving fence gates per station, each with a 4-place queue in front of it.
- A locked gate has a plate with its price. Right station prices: 0, 100, 200, 400. The first
  gate of the left station starts unlocked.
- An unlocked gate keeps its queue full. It only opens while the player stands on its plate:
  stepping on opens it, standing there lets the first passenger through whenever a wagon queue
  has room, and stepping off closes it. Holding the plate on a locked gate buys it.

### Boarding

- Each wagon has its own 4-place queue. A passenger coming through a gate goes to the first
  queue whose wagon still has room (or any queue with a free place).
- While the train waits at the platform, the first passenger in each queue boards, until the
  wagon is full.
- Wagon capacity: `2 + capacity tier` seats.

### Train cycle

1. **Approaching:** the train rides in from 100 m away to the platform at 10 m/s, eased by a
   movement curve, with a moving sound.
2. **Waiting for signal:** horn; the traffic light is red and the lever plate becomes active.
3. **Departing:** the player triggers the lever plate; the light turns green, the horn plays
   and the train rides 100 m out. Passengers' tickets are paid now.
4. **Finalized:** the light turns yellow and the wagons are emptied.
5. After the respawn time (10 s at the start), the train comes back (step 1).

Triggering the lever while the train is not waiting plays the failure feedback.

### Revenue

- When the train departs: `passengers on board x ticket price` (ticket price: 1 coin).
- A floating "+N" text appears over the platform with a coin sound.

## Progression

Each station has its own upgrades. `tier` starts at 0.

| Upgrade | Effect | Price |
|---|---|---|
| Wagon unlock | Unlocks the next wagon (4 per station, 2 unlocked at the start); the plate disappears when all are unlocked | `150 + 50 x unlocked wagons` |
| Capacity | +1 seat in every wagon of the station | `10 + 5 x tier` |
| Train speed | Respawn time `10 - 0.5 x tier` s, minimum 4 s (max tier 11) | `5 + 10 x tier` |

- The train model changes at speed tiers 5, 10, 15... (7 models, `TrainData 1-7`), one model
  at a time.
- A wagon uses the first model whose tier is at least the capacity tier (`WagonData 1-7` at
  tiers 0, 5, 10... 30): model 1 at tier 0, model 2 at tiers 1-5, model 3 at tiers 6-10, and so
  on.
- The money counter sits top right; the number shrinks and pops back when it changes.
- When the train departs, a "+N" with a banknote icon pops up and rises over the platform.
- Plate icons: gates show a key, the wagon plate a train, the capacity plate a person with a
  plus, the speed plate a gauge.

## Tutorial

On the first run (right station only), a bobbing guide arrow points at the first fence gate.
When the unlocked wagons are full, it moves to the traffic light. When the train departs, the
tutorial is marked as done and saved (see the quirks below).

## Feedback

- Plates: the floor marker bobs while the plate can be used (affordable, train waiting) and
  sinks while the player stands on it. Success blinks it green with a level-up sound, failure
  red with a buzz; stepping on and off plays a click.
- Wagons swell (up to 1.2x wider and taller) as passengers board; a full wagon shows a bubble
  with a red "max capacity" icon. Every capacity upgrade plays the level-up sound.
- Train: a moving sound that gets louder over the trip, a horn when it stops and when it
  leaves, smoke puffs from the chimney (models 1 and 2), and a chime when its model changes.
- Passengers waiting idle for 15 s show an annoyed emote (anger, cross, zZ, gloom) for 5 s.
- The cash register employee plays the idle animation. Music loops at 30% volume.
- On touch screens, an on-screen joystick (bottom center) replaces the keys.

## Save data

Saved in the browser's localStorage (Save Kit), after every change: coins, per-station tiers
(capacity, speed), unlocked wagons, unlocked gates, tutorial done. Unity saved through the
CrazyGames SDK; the port is not published there, so Unity saves are not read.

## Unity quirks to decide on

Behaviors of the Unity build that look like bugs. The port keeps them until a decision is
made in the roadmap backlog.

- The left station saves under the right station's keys (`TierCapacityLeft` uses the key
  `TierCapacityRight`, and so on), and some gate keys are shared between stations, so the two
  stations overwrite each other's progress. **Not ported:** each station saves its own keys.
- `IsTutorialCompleted` has an empty save key. **Not ported.**
- The speed upgrade stops at tier 11, so only train models 1-3 (tiers 0, 5, 10) can be seen.
  The upgrade code also never switches to the last train model.
- On load, the train picks the first model whose tier is at least the saved speed tier, so a
  saved tier 1 already shows model 2 (in play, model 2 only comes at tier 5).
- Wagon models switch at capacity tier 1, 6, 11... instead of 5, 10, 15 (see above).
- The tutorial is meant to end after two departures, but its check runs every frame while the
  train departs, so it ends on the first one.
