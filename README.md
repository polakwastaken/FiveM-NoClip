# Advanced FiveM Noclip Script

A high-performance, standalone Noclip utility for FiveM. This script provides smooth movement, vehicle support and an intelligent "Fast-Bring-To-Ground" feature to ensure a seamless experience for admins and developers.

## Features

* **Vehicle & Ped Support:** Noclip works whether you are on foot or driving a vehicle.
* **Speed Presets:** Switch between 5 different speed levels on the fly using the mouse wheel.
* **Dynamic Boost:** Hold a key to multiply your current speed instantly.
* **Ground Snapping:** When exiting noclip, the script intelligently probes the ground and smoothly "snaps" you to it to prevent falling through the map or dying.
* **Instructional UI:** Uses GTA V native Scaleforms to show available controls on your screen.
* **Auto-Invisibility:** Automatically hides your character/vehicle and grants invincibility while active.

## Controls

While Noclip is active, the following controls are available:

| Action | Control | Description |
| :--- | :--- | :--- |
| **Move Forward/Back** | `W` / `S` | Move in camera direction |
| **Move Left/Right** | `A` / `D` | Strafe sideways |
| **Move Up/Down** | `Space` / `Left Ctrl` | Change altitude |
| **Speed +/-** | `Mouse Wheel Up/Down` | Cycle through speed presets |
| **Boost** | `Left Shift` | Multiplies speed while held |
| **Toggle** | `/noclip or F2` | Activate or deactivate the script |


## Detailed Configuration (`CONFIG`)

The script features a highly tunable `CONFIG` table at the top of the file. Here is what each section does:

### Movement & Speed
* **`speeds`**: An array of values `{ 0.5, 1.0, 2.0, 5.0, 10.0 }`. These are the base units moved per frame. You can add more or change these values.
* **`boostMultiplier`**: When the boost key is held, your current speed is multiplied by this value (Default: `2.0`).

### Key Controls (FiveM Control IDs)
These use standard [FiveM Control IDs](https://docs.fivem.net/docs/game-references/controls/):
* `speedUpControl`: 241 (Mouse Wheel Up)
* `speedDownControl`: 242 (Mouse Wheel Down)
* `moveUpControl`: 22 (Spacebar)
* `moveDownControl`: 36 (Left Control)
* `boostControl`: 21 (Left Shift)

### Ground Detection (The "Snapping" System)
This system prevents you from getting stuck in the air when you turn noclip off.
* **`groundProbeStep`**: How far apart each "check" for the ground is (in meters).
* **`groundProbeIterations`**: How many checks the script performs downwards from `1200.0` Z-height.
* **`groundPedOffset` / `groundVehicleOffset`**: How high above the ground you will be placed (prevents clipping into the floor).
* **`snapMinMs` / `snapMaxMs`**: The minimum and maximum duration of the "landing" animation.
* **`snapMsPerDistance`**: Determines how "fast" you fall based on distance (7ms per meter by default).

### Performance Tuning
* **`restoreDelayMs`**: Small delay after turning off noclip before collision and gravity are fully restored (prevents glitches).
* **`noclipIdleWaitMs`**: The tick-rate while noclip is **OFF** (250ms), ensuring zero CPU impact when not in use.

## Installation & Permissions

1.  Place the `noclip` folder into your server's `resources` directory.
2.  Add `ensure noclip` to your `server.cfg`.
3.  **Required:** You must set up ACE permissions in your `server.cfg` for the script to work. Add the following lines:

```cfg
# Allow the 'admin' group to use noclip
add_ace group.admin noclip.use allow
```

## MIT License

This project is released under the MIT License.
