## LsL Open Source Teleport system (LOST)
A simple (for now) sit and teleport script with configuration file. It is still in a very early alpha version, so features will be very limited and highly subject to change.

### Sounds and Animation
The script by default will play the first sound and animation files it finds in the object's inventory when the teleport is activated. These are optional and will not prevent the teleporter from working if they aren't present.

### Config file
You will need to add a notecard named `CONFIG` and add the following example text. Change settings as you feel you need to.
```
soundVolume, 1.0
sleepTime, 0.0
destination, <0.0, 0.0, 0.0>
```

The format is comma separated values with one setting per line. Options available:
- `soundVolume`: (float) When a sound file is present it will play this sound at the specified volume
- `sleepTime`: (float) A time delay before the user is teleported to the destination
- `destination`: (vector) Coordinates to teleport the user to within the sim.
