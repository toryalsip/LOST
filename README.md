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
- `avOffset`: (vector) An optional item that can override the default positioning of the avatar sitting
- `avRotation`: (vector) An optional item to specify avatar rotation if needed depending on your animation
- `message`: (string) An optional custom message to display when teleporting.
- `menuText`: (string) Optional text to display in menu when object is right-clicked. Default: Teleport

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

Make sure that your destination coordinates are valid vectors that you can teleport to within the sim. If they are not, the script will display a warning and set the coordinates to the same as the object.
```
# This will result in a warning and the teleport won't work.
destination,<10.0,100.0, 50.0, Ground Level
```

### Custom message
The teleporter can send a message to local chat when someone teleports by specifying the `message` parameter in you CONFIG. It also does a little string substitution, so if you include `$DISPLAY_NAME` in your message it will substitute the display name of the avatar sitting

Example:
```
message, $DISPLAY_NAME is teleported somewhere!
```

### Adjusting Poses and Test Mode
Getting the offset and rotation for a pose can be a lot of trial and error, so the test mode is there to help you out. To access test mode just

1. Touch the teleporter (if your default action on the object is sit you will want to right-click and select Touch)
2. In the menu that opens up select the `test` option.
3. Green text will appear above the teleporter saying `Running in TEST mode, teleport function disabled.` In this mode:
    1. Only the owner may sit on the teleporter
    2. Teleport actions will not happen
    3. Sitting on the teleporter will open the Adjust setting menu

Adjust setting will have 3 options:
1. offset (tweak the offset along the X, Y, and Z axis)
2. rotation (tweak the rotation in 5 degree ingrements along the X, Y, and Z axis)
3. DUMP (print the current settings for avRotation and avOffset to chat)

Make sure to stand up off the teleporter once you are done adjusting.

To exit out of Test mode just touch the object again and select `default` instead.
