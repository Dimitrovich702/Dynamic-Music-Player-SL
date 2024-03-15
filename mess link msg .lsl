integer DEBUG = FALSE;
float INTERVAL = 3 ;

//float INTERVAL =  llGetNotecardLine/( Name, pota );
float V = 9.9;
integer pota = 0;
integer CHAN = -81412;
integer ASSET = 9;

integer trackCnt = 0;
integer inti = TRUE;
integer LINK_NUMBER = 0;
integer Curl = 0;
integer SoundID = 0;
integer songTrackCnt = 0;
integer lineNumber;
integer curSongOffset = 0;
integer totalSongs = 0;
integer curSongEnd = 8;
integer NotecardLine = 0;

string  DirSound = "";
string  Name = "";
string playing = "";

string NEXT_MSG = "Next >>";
string PREV_MSG = "<< Prev";
string STOP_MSG = "Stop";

list but = [];
list Names = [];
list Musicuuids = [];

key DataRequest = NULL_KEY;
key silence = NULL_KEY;
 list styleDATA = ["Default!♥", "▱", "▰", "▻", "►", "◅", "◄"];
vector displayColourNormal = <1.0, 1.0, 1.0>;
vector displayColourLoading = <0.8, 1.0, 0.8>;
vector displayColourError = <1.0, 0.2, 0.2>;
integer priorityTag;
// ================
// Global functions
// ================

// Create a progress bar from percentage
string ProgressBar(float percent, integer length)
{    
    string tmp_str;
    integer tmp_i;
    
    // First apply bright icons
    while(tmp_i < (integer)(percent * length)) {
        tmp_str += llList2String(styleDATA, 2);
        tmp_i++;
    }
    
    // Second apply dark icons
    while(tmp_i < length) {
        tmp_str += llList2String(styleDATA, 1);
        tmp_i++;
    }
    
    return tmp_str;
}

string CalcTime(integer seconds)
{
    string tmp_str;
    integer tmp_timer_sec;
    integer tmp_timer_min;
    integer tmp_timer_hour;
    // Calculate values
    if(seconds >= 3600) { tmp_timer_hour = llFloor(seconds / 3600); seconds = seconds % 3600; }
    if(seconds >= 60) { tmp_timer_min = llFloor(seconds / 60); seconds = seconds % 60; }
    if(seconds > 0) { tmp_timer_sec = seconds; }
    
    // Only include hours if applicable
    if(tmp_timer_hour) { tmp_str = (string)tmp_timer_hour + ":"; }
    
    // Include minutes
    if(tmp_timer_min < 10) { tmp_str += "0"; }
    tmp_str += (string)tmp_timer_min + ":";
    
    // Include seconds
    if(tmp_timer_sec < 10) { tmp_str += "0"; }
    tmp_str += (string)tmp_timer_sec;
    
    // Finished
    return tmp_str;
}

RenderDisplay(string JSON)
{    
    // play status?
    if(llJsonGetValue(JSON, ["type"]) == "playing")
    {
        // load & errors gets priority
        if(priorityTag < llGetUnixTime())
        {
            // scale progress bar according to title
            integer tmp_pb_length;
            string tmp_title = llJsonGetValue(JSON, ["title"]);
            if(llStringLength(tmp_title) < 12) {
                tmp_pb_length = 6;
            } else { 
                if(llStringLength(tmp_title) > 40) {
                    tmp_pb_length = 20;
                    tmp_title = llGetSubString(llJsonGetValue(JSON, ["title"]), 0, 40);
                } else {
                    tmp_pb_length = (integer)(llStringLength(tmp_title) / 4) * 2;
                }
            }
            
            // calc percentage
            float tmp_percent = (float)llJsonGetValue(JSON, ["time"]) / (float)llJsonGetValue(JSON, ["totalTime"]);
            
            // adjust icons accordingly
            string tmp_str_ico_left;
            string tmp_str_ico_right;
            if(tmp_percent < 0.52) { tmp_str_ico_left = llList2String(styleDATA, 3); } else { tmp_str_ico_left = llList2String(styleDATA, 4); }
            if(tmp_percent < 0.53) { tmp_str_ico_right = llList2String(styleDATA, 5); } else { tmp_str_ico_right = llList2String(styleDATA, 6); }
            
            // build display
            string tmp_str;
            tmp_str = ProgressBar(tmp_percent, tmp_pb_length);
            tmp_str = llInsertString(tmp_str, tmp_pb_length / 2, tmp_str_ico_left + "  " + CalcTime((integer)llJsonGetValue(JSON, ["time"])) + "  ⅼ  " + CalcTime((integer)llJsonGetValue(JSON, ["totalTime"])) + "  " + tmp_str_ico_right);
            tmp_str = tmp_title + "\n" + tmp_str;
            llSetText(tmp_str, displayColourNormal, 1.0);          
        }
    }
    
    // loading status?
    if(llJsonGetValue(JSON, ["type"]) == "loading")
    {
        // reserve priority
        priorityTag = llGetUnixTime() + 3;
        
        // build display
        float tmp_percent = (float)llJsonGetValue(JSON, ["current"]) / (float)llJsonGetValue(JSON, ["end"]);
        string tmp_str = ProgressBar(tmp_percent, 10);
        tmp_str = llInsertString(tmp_str, 5, (string)((integer)(tmp_percent * 100)) + "%");
        tmp_str = llJsonGetValue(JSON, ["title"]) + "\n" + tmp_str;
        llSetText(tmp_str, displayColourLoading, 1.0);
    }
    
    // error status?
    if(llJsonGetValue(JSON, ["type"]) == "error")
    {
        // reserve priority
        priorityTag = llGetUnixTime() + 10;
        
        // build display
        llSetText(llJsonGetValue(JSON, ["msg"]), displayColourError, 1.0);
    }
}

UpdateDisplay(string JSON) {
    // convert from object to json
    string tmp_json = llJsonGetValue(JSON, ["data"]);
    tmp_json = llDeleteSubString(tmp_json, 0, 1);
    tmp_json = llDeleteSubString(tmp_json, (llStringLength(llJsonGetValue(JSON, ["data"])) - 3),  llStringLength(llJsonGetValue(JSON, ["data"])));
    tmp_json = "{ " + tmp_json + " }";
    // store style
    styleDATA = [llJsonGetValue(tmp_json, ["SN"])];
    styleDATA += llParseString2List(llJsonGetValue(tmp_json, ["SD"]), ["|"], []);
}

Initialize()
{
    llSetText("", <1,1,1>, 1.0);
                  CHAN = llFloor(llFrand(1000000) - 100000);
// chan dynamical also 
    llListen(CHAN, "", NULL_KEY, "");

    playing = "";
    inti = TRUE;
    Curl = 1;
    curSongEnd = 8;
    curSongOffset = 0;


    totalSongs = llGetInventoryNumber(INVENTORY_NOTECARD);

    SoundID = 0;
    while(SoundID < totalSongs)
    {
        Names += llGetInventoryName(INVENTORY_NOTECARD, SoundID);
        SoundID += 1;
    }
    inti = FALSE;
}

curSongs()
{
    if(curSongOffset > 0)
    {
        but = [PREV_MSG];
    }
    else
    {
        but = [" "];
    }
    if(curSongEnd < (totalSongs-1))
    {
        but += [STOP_MSG, NEXT_MSG];
    }
    else
    {
        but += [STOP_MSG, " "];
    }

    integer i;
    DirSound = "\n \n";

    if (curSongOffset >= totalSongs)
    {
        curSongOffset = 0;
        curSongEnd = curSongOffset + (ASSET - 1);
    }

    if (curSongEnd >= totalSongs)
    {
        curSongEnd = totalSongs - 1;
    }

    for (i = curSongOffset; i <= curSongEnd; i++)
    {
        if (SoundID == i)
        {
            DirSound += "*";
        }
        else
        {
            DirSound += " ";
        }
        DirSound += (string) (i + 1) + ") ";
        DirSound += llList2String(Names, i);
        DirSound += "\n";

        but += (string)(i + 1);
    }
}

doNextSet()
{
    curSongOffset += ASSET;
    curSongEnd = curSongOffset + (ASSET - 1);

    if (curSongOffset >= totalSongs)
    {
        curSongOffset = 0;
        curSongEnd = curSongOffset + (ASSET - 1);
    }

    if (curSongEnd >= totalSongs)
    {
        curSongEnd = totalSongs - 1;
    }
}


doPrevSet()
{
    if (curSongOffset > 1 && ((curSongOffset - ASSET) < 1))
    {
        curSongOffset = 0;
    }
    else
    {
        curSongOffset -= ASSET;
    }

    curSongEnd = curSongOffset + (ASSET - 1);

    if (curSongEnd >= totalSongs)
    {
        curSongEnd = totalSongs - 1;
    }

    if (curSongOffset < 0)
    {
        curSongEnd = totalSongs - 1;
        curSongOffset = totalSongs - (ASSET - 1);
    }
}

LoadSong()
{
    if(DEBUG) llOwnerSay("LoadSong");

    llOwnerSay( "Loading: "+ Name);
     llParticleSystem([ 
         PSYS_PART_FLAGS, 259,
         PSYS_SRC_PATTERN, 2,
        PSYS_SRC_BURST_RADIUS, 1.000000,
    PSYS_PART_START_COLOR, <1.00000, 1.00000, 1.00000>,
      PSYS_PART_END_COLOR, <1.00000, 1.00000, 1.00000>,
          PSYS_PART_START_ALPHA, 1.000000,
           PSYS_PART_END_ALPHA,1.000000, 
          PSYS_PART_START_SCALE, <0.20000, 0.20000, 0.00000>,
           PSYS_PART_END_SCALE, <0.010000, 0.010000, 0.00000>,
        PSYS_SRC_MAX_AGE, 0.000000,
        PSYS_PART_MAX_AGE, 0.200000,
       PSYS_SRC_TEXTURE, "",
     PSYS_SRC_BURST_RATE, 0.100000,
          PSYS_SRC_BURST_PART_COUNT, 9999,
        PSYS_SRC_BURST_SPEED_MIN, 0.100000,
           PSYS_SRC_BURST_SPEED_MAX, 0.50000
  ]); 

    INTERVAL = 0;

    songTrackCnt = 0;
    lineNumber = 0;
    DataRequest = llGetNotecardLine( Name, lineNumber++ );
          llParticleSystem([]);
}

PlaySong()
{
    if(DEBUG) llOwnerSay("PlaySong with INTERVAL=" + (string)INTERVAL);

    playing = Name;

    Curl = 0;

    llOwnerSay("Playing: "+ Name);

    llPlaySound(llList2Key(Musicuuids, Curl++), V);
    llPreloadSound( llList2Key(Musicuuids, Curl) );
    llSetTimerEvent(INTERVAL-0.05);
}


StopSong()
{
    if(DEBUG) llOwnerSay("StopSong");

    // llPlaySound(silence, 0.0);

    llStopSound();
    llSetTimerEvent(0.0);

    playing = "";

    Musicuuids = [];
}

integer isUUID(string s)
{
    integer result = TRUE;
    
    if (llStringLength(s) != 36)
        result = FALSE;
    else
    {
        list temp = llParseStringKeepNulls(s, [ "-" ], []);
        if (llGetListLength(temp) != 5)
            result = FALSE;
    }
    return result;
}

default
{
    state_entry()
    {
        llSetSoundQueueing(TRUE);
     //   llRequestPermissions(llGetOwner(),PERMISSION_TRIGGER_ANIMATION);

        Initialize();
    }

    changed(integer change)
    {
        if(DEBUG) llOwnerSay("changed");

        if (change & CHANGED_INVENTORY)
        {
            llResetScript();
        }
    }

    on_rez(integer start_param)
    {
        llResetScript();
    }
     link_message(integer link_sender, integer link_number, string link_msg, key link_key)
    {
        // verify it's for us
        if(llJsonGetValue(link_msg, ["target"]) == "DISPLAY")
        {
            // display?
            if(llJsonGetValue(link_msg, ["action"]) == "display") { RenderDisplay(link_msg); }
            // apply style?
            if(llJsonGetValue(link_msg, ["action"]) == "apply") { UpdateDisplay(link_msg); };
        }
    }

    dataserver( key id, string data )
    {
        if(DEBUG) llOwnerSay("dataserver: "+(string)(lineNumber - 1)+" = "+data);

        if (id == DataRequest)
        {
            if (data != EOF)
            {
                if ((songTrackCnt == 0) && (INTERVAL <= 0.0))
                {
                    INTERVAL = (float)llStringTrim(data, STRING_TRIM);
                }
                else
                {
                    data = llStringTrim( data, STRING_TRIM );
                    list dataParts = llParseString2List(data, ["|"], [""]);
                    if (isUUID(llList2String(dataParts, 0)))
                    {
                        Musicuuids += llList2String(dataParts, 0);
                        songTrackCnt += 1;
                        
llMessageLinked(LINK_THIS, 0, ["target"], );

 //   float potato = songTrackCnt x 
   // llSetText((string)songTrackCnt, <1,1,1>, 1.0);

                 }
                }
                DataRequest = llGetNotecardLine( Name, lineNumber++ );
            }
            else
            {
                PlaySong();
            }
        }
    }

    
   

    touch_start(integer touchNumber)
    {
        if(DEBUG) llOwnerSay("touch_start");
        if(inti)
        {
            llOwnerSay("Busy loading songs, please wait a moment and try again...");
        }
        else
        {
            curSongs();
 //   llStartAnimation("guitar");
            llDialog(llDetectedKey(0), DirSound, but, CHAN);
        }
    }

    listen(integer CHAN, string name, key id, string message)
    {
        if(DEBUG) llOwnerSay("listen: "+message);

        //list words = llParseString2List(message, [" ", " ", "="], []);
        list words = llParseString2List(message, ["="], []);
        list testFind = llList2List(words, 0, 0);
        
        if (llList2String(testFind,0) == "Next >>")
        {
            doNextSet();
            curSongs();

            llDialog(id, DirSound, but, CHAN);
        }
        else if (llList2String(testFind,0) == "<< Prev")
        {
            doPrevSet();
            curSongs();

            llDialog(id, DirSound, but, CHAN);
        }
        else if (llList2String(testFind,0) == "Stop")
        {
               // llStopAnimation("guitar");
            StopSong();
        }
        else if ((integer)message > 0 && (integer)message < 256)
        {
            SoundID = (integer)message - 1;
            Name = llList2String(Names, SoundID);

            StopSong();

            LoadSong();
        }
    }


    timer()
    {
        if(DEBUG) llOwnerSay("timer: start: playing = "+(string)playing+", curTrack="+(string)Curl+", songTrackCnt="+(string)songTrackCnt);

        // llSetTimerEvent(INTERVAL);  // the timer will remain running, no need to keep restarting it.

        if ( Curl < songTrackCnt )
        {
            llPlaySound(llList2Key(Musicuuids, Curl), V);
            if ( ++Curl < songTrackCnt )
            {
                llPreloadSound( llList2Key(Musicuuids, Curl) );
            }
        }
        else
        {
            llOwnerSay("Finished: "+Name);

            llStopSound();

            // llPlaySound(silence, 0.0);

            llSetTimerEvent(0.0);
        }

        if(DEBUG) llOwnerSay("timer end: playing = "+playing+", Curl="+(string)Curl+", songTrackCnt="+(string)songTrackCnt);
    }
}
