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
- `animationOffset`: (vector) An optional item that can override the default positioning of the avatar sitting
- `message`: (string) An optional custom message to display when teleporting.

### Destinations
There should be a minimum of at least 1 destination in the config. If there are none, it won't break anything but your teleporter won't function either.

You can have multiple `destination` lines in your config, each with different coordinates and a third item which would be the name of the destination and what will go in menu dialog. You do not have to specify this, but if you want users to know roughly where they are going, then you probably should set this.

Example:
```
destination,<10.0,100.0, 50.0>, Ground Level
destination,<10.0,100.0, 1500.0>, Skybox
```

You may only have up to 12 destinations in your teleport network currently. If you exceed this the script will just skip over any excess ones.

The script relies on unique destination names. If you have more than one name it will always pick the first destination on the list that matches that name.

### Custom message
The teleporter can send a message to local chat when someone teleports by specifying the `message` parameter in you CONFIG. It also does a little string substitution, so if you include `$DISPLAY_NAME` in your message it will substitute the display name of the avatar sitting

Example:
```
message, $DISPLAY_NAME is teleported somewhere!
```
