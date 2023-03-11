string SCRIPT_VERSION = "v0.0.1-alpha4";
key notecardQueryId; //Identifier for the dataserver event
string configName = "CONFIG"; //Name of a notecard in the object's inventory.
integer notecardLine; //Initialize the counter value at 0
key notecardKey; //Store the notecard's key, so we don't read it again by accident.
string DEFAULT_ANIMATION = "sit";
string animation; // the first animation in inventory will automatically be used
// the animation name must be stored globally to be able to stop the animation when standing up
vector animationOffset = <0.0, -0.1, 0.1>; // Offset position of the avatar sitting on the object
vector avatarRotation = <0.0, 0.0, 0.0>; // Rotation for sittarget 
string sound; // The sound that will play when sitting
float soundVolume = 1.0;
float sleepTime = 2.0;
string teleportMessage;
list destinations;
list destinationNames;
integer destinationCount;
integer MAX_DESTINATION_COUNT = 12; // This is to avoid errors when loading menu

integer dialogListener;
integer DIALOG_CHANNEL = -99;

ReadConfig()
{
    key configKey = llGetInventoryKey(configName);
    if (configKey == NULL_KEY)
    {
        llOwnerSay( "Notecard '" + configName + "' missing or unwritten."); //Notify user.
        return; //Don't do anything else.
    }
    else if (configKey == notecardKey) return;
    //This notecard has already been read - call to read was made in error, so don't do anything. (Notecards are assigned a new key each time they are saved.)

    llOwnerSay("Reading config, please wait..."); //Notify user that read has started.
    destinations = [];
    destinationNames = [];
    destinationCount = 0;
    notecardLine = 0;

    notecardKey = configKey;
    notecardQueryId = llGetNotecardLine(configName, notecardLine);
}

ParseConfigLine(string data)
{
    list items = llCSV2List(data);
    string itemName = llList2String(items, 0);
    string itemValue = llList2String(items, 1);
    if (itemName == "soundVolume")
        soundVolume = (float)itemValue;
    else if (itemName == "sleepTime")
        sleepTime = (float)itemValue;
    else if (itemName == "message")
        teleportMessage = itemValue;
    else if (itemName == "destination")
    {
        string destinationName = llList2String(items, 2);
        if (destinationName == "" )
        {
            destinationName = (string)(destinationCount + 1);
        }
        if (destinationCount < MAX_DESTINATION_COUNT)
        {
            ++destinationCount;
            destinations += (vector)itemValue;
            destinationNames += destinationName;
        }
        else
        {
            llOwnerSay("Warning, skipping destination " + destinationName + 
                ". Please keep destinations at " + (string)MAX_DESTINATION_COUNT + " or less.");
        }
    }
    else if (itemName == "animationOffset")
        animationOffset = (vector)itemValue;
    else if (itemName == "avatarRotation")
        avatarRotation = (vector)itemValue;
}

SetSitTarget()
{
    llSitTarget(animationOffset, llEuler2Rot(avatarRotation * DEG_TO_RAD));
}

StartTeleportDialog(key av)
{
    llListenRemove(dialogListener);
    dialogListener = llListen(DIALOG_CHANNEL, "", av, "");
    llDialog(av, "\nPlease select a destination", destinationNames, DIALOG_CHANNEL);
}

DoTeleportByName(string destinationName, key av)
{
    DoTeleport(
        llList2Vector(destinations,llListFindList(destinationNames,[destinationName])),
        av
    );
}

DoTeleport(vector destination, key av)
{
    if (sound)
    {
        llPlaySound(sound, soundVolume);
    }

    if (teleportMessage)
    {
        llSay(0, strReplace(teleportMessage, "$DISPLAY_NAME", llGetDisplayName(av)));
    }

    llSleep(sleepTime);
    
    vector start = llGetPos();
    
    llSetRegionPos(destination);
    llUnSit(av);
    llSetRegionPos(start); 
}

// This is only temporary until Firestorm adds support for llReplaceSubString
string strReplace(string str, string search, string replace) {
    return llDumpList2String(llParseStringKeepNulls((str = "") + str, [search], []), replace);
}

default
{
    state_entry()
    {
        llSay(0, "Starting LOST-teleporter script version " + SCRIPT_VERSION);
        ReadConfig();
        // Preload inventory item names so we don't have to do it later
        animation = llGetInventoryName(INVENTORY_ANIMATION,0);
        sound = llGetInventoryName(INVENTORY_SOUND,0);
    }
 
    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            key av = llAvatarOnSitTarget();
            if (av)
            {
                llRequestPermissions(av, PERMISSION_TRIGGER_ANIMATION);
            }
            else // avatar is standing up
            {
                llListenRemove(dialogListener);
                if (animation)
                    llStopAnimation(animation); // stop the started animation
            }
        }
        else if (change & CHANGED_INVENTORY)
        {
            ReadConfig();
        }
    }
    
    listen(integer chan, string name, key id, string msg)
    {
        DoTeleportByName(msg, id);
        // This is done to immediately cleanup the dialog
    }

    dataserver(key query_id, string data)
    {
        if (query_id == notecardQueryId)
        {
            if (data == EOF) //Reached end of notecard (End Of File).
            {
                SetSitTarget();
                llOwnerSay("Done reading config, you may now use the teleporter!"); //Notify user.
            }
            else
            {
                ParseConfigLine(data); //Add the line being read to a new entry on the list.
                ++notecardLine; //Increment line number (read next line).
                notecardQueryId = llGetNotecardLine(configName, notecardLine); //Query the dataserver for the next notecard line.
            }
        }
    }
    
    run_time_permissions(integer perm)
    {
        key av = llAvatarOnSitTarget();
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            if (animation)
            {
                llStopAnimation(DEFAULT_ANIMATION);
                llStartAnimation(animation);

                
                
            }
            if (destinationCount <= 0)
            {
                llUnSit(av);
                return;
            }
            else if (destinationCount == 1)
            {
                vector destination = llList2Vector(destinations, 0);
                DoTeleport(destination, av);
            }
            else
            {
                StartTeleportDialog(av);
            }
        }
    }
}
