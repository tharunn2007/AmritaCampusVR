# Amrita Campus VR

A navigation-only Godot 4.7.2 / OpenXR prototype for Meta Quest, built from your supplied campus.blend. The original file on the drive is unchanged. `source/campus.blend` is a byte-identical archival copy; the game loads `assets/campus.glb`.

## Play on this computer

Run `./play-desktop.sh`, or open `project.godot` in Godot and press F6/F5. The launcher explicitly disables XR for desktop preview. Use `./open-editor.sh` to edit the project.

- WASD or arrow keys: move forward, backward, strafe, or combine keys diagonally, relative to the view. Walking speed is 4.317 metres/second.
- Hold Left Ctrl while moving: sprint at 5.612 metres/second in any direction (release to walk). Diagonal movement keeps the same speed. These approximate Minecraft walking/sprinting speeds: https://minecraft.wiki/w/Sprinting
- Mouse: look around. Looking up or down does not reduce movement speed.
- Q/E: turn 30 degrees.
- Hold T: aim the teleport ray; release T: teleport if a green landing ring appears.
- R: return to the starting location.
- Escape: release the mouse; click to capture it again.

## Quest controls

- Left thumbstick: movement in any direction relative to your view, at up to 4.317 metres/second.
- Hold the left thumbstick click while moving: sprint at up to 5.612 metres/second. Release the click to walk. Partial thumbstick deflection gives proportional speed.
- Right thumbstick left/right: 30-degree snap turn; release to centre before another turn.
- Hold right trigger: aim teleport; release: teleport to clear ground.
- Y: return to start.
- Head and controllers use OpenXR tracking. A short help panel is attached to the left controller.

Teleportation stops at walls, rejects building roofs and destinations without capsule clearance. Smooth movement uses a colliding capsule and gravity. Room-scale motion repositions the capsule beneath the head; physically moving your head through a virtual wall cannot be prevented by software.

## Android / Meta Quest build

`builds/amrita-campus-quest.apk` is a successfully exported, signed ARM64 debug APK (approximately 83 MiB). APK signature verification passed and the manifest includes the Quest VR launch category and head-tracking feature. It has not been installed or tested on a headset. To rebuild on this machine, run `./build-quest.sh`.

The `Meta Quest` preset uses ARM64, OpenXR, the Meta vendor plugin, Gradle, and the Compatibility renderer. The vendor plugin is copied from the existing local Godot XR project; its Linux/Windows binary paths were corrected in this copy. Vendor licenses remain with the addon.

Godot 4.7.2 Android templates have been installed on this computer. In Editor Settings > Export > Android use:

- Java SDK: `/usr/lib/jvm/java-17-openjdk-amd64`
- Android SDK: `/home/tharunn/android-sdk` (the previous editor setting points at a nonexistent `android-sdks` directory).

Choose Project > Export > Meta Quest > Export Project. This is a debug/sideload prototype, not a store release. To install a successfully built APK, enable developer mode on the Quest, connect USB, accept USB debugging inside the headset, and run:

```sh
adb install -r builds/amrita-campus-quest.apk
```

Open **Amrita Campus VR** from Unknown Sources. A real headset test is required to validate tracking, comfort, frame rate, and the exact Quest model/runtime. No headset was used during development.

Godot Android XR documentation: https://docs.godotengine.org/en/stable/tutorials/xr/deploying_to_android.html

## Model and scope

The source contains 267 meshes / 3,714 source vertices: 118 building meshes, 58 roads, 25 paths, 14 areas, 51 restriction overlays, and a ground plane. This is a simplified campus model with flat ground, not surveyed terrain or photorealistic building interiors. No web terrain or invented hills were added. One Blender unit is retained as one Godot metre; real-world scale has not been independently surveyed.

Runtime materials distinguish roads, paths, buildings and vegetation. Restriction overlays are hidden as map annotations; no access restrictions are inferred from them. Geometry and the original Blender materials remain preserved in the source asset. Named building labels appear within 160 metres. The start is near the model's main university road, not a verified entrance location.

No multiplayer, combat, quests, real-world GPS positioning or online services are included.

## Validation and maintenance

```sh
/path/to/godot --headless --path . --xr-mode off --script res://tests/navigation.gd
```

Tests check ground contact, 119 colliders, starting clearance, walking displacement, turning about the head, teleport selection and clearance, building walls and fall recovery. `builds/desktop-preview.png` is a rendered desktop capture.

Re-export the model without saving changes to the Blender source:

```sh
blender --background source/campus.blend --python tools/export_campus.py
```

The source and builds folders are ignored by Godot's asset importer. `assets/model_report.json` records source mesh bounds. Regenerated GLB files are imported automatically by Godot.

## Reference movement and sky adaptation

Movement is adapted from the Godot 3/OpenVR tutorial in `inpire.zip` to Godot 4.7/OpenXR: head-relative locomotion, radial thumbstick deadzone rescaling, a movement vignette in VR, and straight-ray point-and-teleport (25 metres). Aim down at clear ground, then release the trigger/T to teleport. The left stick controls locomotion and right stick controls snap turning. Keyboard navigation and sprint controls still work.

The deadzone remains 0.18 for Quest thumbsticks; input is smoothly rescaled from zero outside it. Analog speed, walking/sprinting rates, building collisions, and the vertical-look heading correction are retained. The vignette fades in during artificial VR movement and out when stopping; it is generated with shader code. The background uses the reference's ocean sky panorama, which is decorative and not the actual surroundings of Amrita.

The only visual asset copied from the ZIP is `assets/environment/ocean_sky.hdr`. No other scene, model, font, object texture, audio, or legacy plugin was imported. Code attribution and the archive's sky credit are in `third_party/`. The desktop render and automated checks do not replace an on-headset check of the vignette and controls.
