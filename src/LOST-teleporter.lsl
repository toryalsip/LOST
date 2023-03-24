string SCRIPT_VERSION = "v0.0.1-alpha6";
string scriptMode;
key notecardQueryId; //Identifier for the dataserver event
string configName = "CONFIG"; //Name of a notecard in the object's inventory.
integer notecardLine; //Initialize the counter value at 0
key notecardKey; //Store the notecard's key, so we don't read it again by accident.
string DEFAULT_ANIMATION = "sit";
string animation; // the first animation in inventory will automatically be used
// the animation name must be stored globally to be able to stop the animation when standing up
vector avOffset = <0.0, -0.1, 0.1>; // Offset position of the avatar sitting on the object
vector avRotation = <0.0, 0.0, 0.0>; // Rotation for sittarget 
string sound; // The sound that will play when sitting
float soundVolume = 1.0;
float sleepTime = 2.0;
string menuText = "Teleport";
string teleportMessage;
list destinations;
list destinationNames;
integer destinationCount;
integer MAX_DESTINATION_COUNT = 12; // This is to avoid errors when loading menu

integer dialogListener;
integer DIALOG_CHANNEL = -99;
integer SETTING_CHANNEL = -100;
integer ADMIN_CHANNEL;
string adjustMode;

vector COLOR_GREEN = <0.0, 1.0, 0.0>;
float OPAQUE = 1.0;

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
    else if (itemName == "avOffset")
        avOffset = (vector)itemValue;
    else if (itemName == "avRotation")
        avRotation = (vector)itemValue;
    else if (itemName == "menuText")
        menuText = itemValue;
}

SetSitValues()
{
    llSitTarget(avOffset, llEuler2Rot(avRotation * DEG_TO_RAD));
    llSetSitText(menuText);
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

OpenAdminMenu()
{
    key av = llDetectedKey(0);
    // Only the object owner should be able to open the admin tools menu
    if (av == llGetOwner())
    {
        dialogListener = llListen(ADMIN_CHANNEL, "", av, "");
        llDialog(av, "\nCurrent Mode: " + scriptMode + "\n\nSelect a mode", ["default", "test"], ADMIN_CHANNEL);
    }

}

OpenAdjustMenu()
{
    key av = llAvatarOnSitTarget();
    if (av == llGetOwner())
    {
        dialogListener = llListen(SETTING_CHANNEL, "", av, "");
        llDialog(av, "\nSelect pose setting to adjust.\nClick DUMP to show current settings",
            ["offset", "rotation", "DUMP"], SETTING_CHANNEL);
    }
}

OpenAdjustSetting(string msg, key av)
{
    string dialogMessage = "";
    list buttons = [
        "-X", "-Y", "-Z", 
        "+X", "+Y", "+Z",
        "[ BACK ]"
    ];
    if (msg == "offset")
    {
        dialogMessage = "Adjust avOffset";
        adjustMode = "offset";
    }
    else if (msg == "rotation")
    {
        dialogMessage = "Adjsut avRotation";
        adjustMode = "rotation";
    }
    else if (msg == "DUMP")
    {
        llOwnerSay("Current sit target settings. Copy these into your CONFIG notecard");
        llOwnerSay("avOffset, " + (string)avOffset);
        llOwnerSay("avatarRotaton, " + (string)avRotation);
        OpenAdjustMenu();
        return;
    }
    llDialog(av, dialogMessage, buttons, SETTING_CHANNEL);
}

HandleAdjustOffset(string msg, key av)
{
    if (msg != "[ BACK ]")
    {
        avOffset = IncrementVector(avOffset, msg, 0.1);
        UpdateSitTarget(avOffset, llEuler2Rot(avRotation * DEG_TO_RAD));
        OpenAdjustSetting(adjustMode, av);
    }
    else
    {
        adjustMode = "";
        OpenAdjustMenu();
    }
}

HandleAdjustRotation(string msg, key av)
{
    if (msg != "[ BACK ]")
    {
        avRotation = IncrementVector(avRotation, msg, 5.0);
        UpdateSitTarget(avOffset, llEuler2Rot(avRotation * DEG_TO_RAD));
        OpenAdjustSetting(adjustMode, av);
    }
    else
    {
        adjustMode = "";
        OpenAdjustMenu();
    }

}

vector IncrementVector(vector value, string msg, float amount)
{
    if (msg == "+X")
        value.x += amount;
    else if (msg == "+Y")
        value.y += amount;
    else if (msg == "+Z")
        value.z += amount;
    else if (msg == "-X")
        value.x -= amount;
    else if (msg == "-Y")
        value.y -= amount;
    else if (msg == "-Z")
        value.z -= amount;
    return value;
}

//Sets / Updates the sit target moving the avatar on it if necessary.
UpdateSitTarget(vector pos, rotation rot)
{//Using this while the object is moving may give unpredictable results.
    llSitTarget(pos, rot);//Set the sit target
    key user = llAvatarOnSitTarget();
    if (user)//true if there is a user seated on the sit target; if so, update their position
    {
        vector size = llGetAgentSize(user);
        if (size)//This tests to make sure the user really exists.
        {
            //We need to make the position and rotation local to the current prim
            rotation localrot = ZERO_ROTATION;
            vector   localpos = ZERO_VECTOR;
            if (llGetLinkNumber() > 1)//only need the local rot if it's not the root.
            {
                localrot = llGetLocalRot();
                localpos = llGetLocalPos();
            }
            integer linkNum = llGetNumberOfPrims();
            do
            {
                if (user == llGetLinkKey(linkNum))//just checking to make sure the index is valid.
                {
                    //<0.008906, -0.049831, 0.088967> are the coefficients for a parabolic curve that best fits real avatars. It is not a perfect fit.
                    float fAdjust = ((((0.008906 * size.z) + -0.049831) * size.z) + 0.088967) * size.z;
                    llSetLinkPrimitiveParamsFast(linkNum,
                        [PRIM_POS_LOCAL, (pos + <0.0, 0.0, 0.4> - (llRot2Up(rot) * fAdjust)) * localrot + localpos,
                         PRIM_ROT_LOCAL, rot * localrot]);
                    jump end;//cheaper but a tad slower than return
                }
            } while(--linkNum);
        }
        else
        {//It is rare that the sit target will bork, but if it does happen, this can help to fix it.
            llUnSit(user);
        }
    }
    @end;
}//Written by Strife Onizuka, size adjustment and improvements provided by Talarus Luan

// This is only temporary until Firestorm adds support for llReplaceSubString
string strReplace(string str, string search, string replace) {
    return llDumpList2String(llParseStringKeepNulls((str = "") + str, [search], []), replace);
}

default
{
    state_entry()
    {
        llSay(0, "Starting LOST-teleporter script version " + SCRIPT_VERSION);
        llSetText("", ZERO_VECTOR, 0);
        scriptMode = "default";
        ADMIN_CHANNEL = (integer)llFrand(2147483646);
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
        if (chan == DIALOG_CHANNEL)
        {
            key av = llAvatarOnSitTarget();
            if (av) 
            {
                DoTeleportByName(msg, av);
            }
        }
        else if (chan == ADMIN_CHANNEL)
        {
            if (msg == "test")
            {
                state test;
            }
            llSetTimerEvent(0.1);
        }
    }

    dataserver(key query_id, string data)
    {
        if (query_id == notecardQueryId)
        {
            if (data == EOF) //Reached end of notecard (End Of File).
            {
                SetSitValues();
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

    touch(integer num_detected)
    {
        OpenAdminMenu();
    }

    timer()
    {
        llListenRemove(dialogListener);
        llSetTimerEvent(0);
    }
}

state test
{
    state_entry()
    {
        scriptMode = "test";
        llSetText("Running in TEST mode, teleport function disabled.", COLOR_GREEN, OPAQUE);
        llOwnerSay("Now running in TEST mode");
    }

    touch(integer num_detected)
    {
        OpenAdminMenu();
    }
    
    listen(integer chan, string name, key id, string msg)
    {
        if (chan == ADMIN_CHANNEL)
        {
            if (msg == "default")
            {
                state default;
            }
            llSetTimerEvent(0.1);
        }
        else if (chan == SETTING_CHANNEL)
        {
            if (adjustMode == "offset")
                HandleAdjustOffset(msg, id);
            else if (adjustMode == "rotation")
                HandleAdjustRotation(msg, id);
            else
                OpenAdjustSetting(msg, id);
        }
    }
    
    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            key av = llAvatarOnSitTarget();
            if (av)
            {
                if (av == llGetOwner())
                {
                    llRequestPermissions(av, PERMISSION_TRIGGER_ANIMATION);
                }
                else
                {
                    llUnSit(av);
                }
            }
            else // avatar is standing up
            {
                llListenRemove(dialogListener);
                if (animation)
                    llStopAnimation(animation); // stop the started animation
            }
        }
    }
    
    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            if (animation)
            {
                llStopAnimation(DEFAULT_ANIMATION);
                llStartAnimation(animation);
            }
            OpenAdjustMenu();
        }
    }


    timer()
    {
        llListenRemove(dialogListener);
        llSetTimerEvent(0);
    }
}
