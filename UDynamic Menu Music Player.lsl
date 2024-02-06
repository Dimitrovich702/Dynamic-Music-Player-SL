integer DEBUG = FALSE;
float INTERVAL = 3 ;

float V = 6.0;
integer pota = 0;
integer CHAN = -81412;
integer ASSET = 6;

integer trackCnt = 0;
integer inti = TRUE;
integer LINK_NUMBER = 0;
integer Curl = 0;
integer SoundID = 0;
integer songTrackCnt = 0;
integer lineNumber;
integer curSongOffset = 0;
integer totalSongs = 0;
integer curSongEnd = 5;
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

Initialize()
{


    llSetText( "" , <1,1,1>, 1.0);
               CHAN = llFloor(llFrand(1000000) - 100000);

    llListen(CHAN, "", NULL_KEY, "");

    playing = "";
    inti = TRUE;
    Curl = 1;
    curSongEnd = 5;
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
    DirSound = "";

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
    llSetText("Playing "+ Name, <1,1,1>, 1.0);

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
}

PlaySong()
{
    if(DEBUG) llOwnerSay("PlaySong with INTERVAL=" + (string)INTERVAL);

    playing = Name;

    Curl = 0;
  llParticleSystem([]);

    llOwnerSay("Playing: "+ Name);

    llPlaySound(llList2Key(Musicuuids, Curl++), V);
    llPreloadSound( llList2Key(Musicuuids, Curl) );
    llSetTimerEvent(INTERVAL-1.0);
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
            //        CHAN = llFloor(llFrand(1000000) - 100000);

        if(inti)
        {
            llOwnerSay("Busy loading songs, please wait a moment and try again...");
        }
        else
        {
            curSongs();

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
                llSetText(" ", <1,1,1>, 1.0);

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
    llSetText(" ", <1,1,1>, 1.0);

            llStopSound();

            // llPlaySound(silence, 0.0);

            llSetTimerEvent(0.0);
        }

        if(DEBUG) llOwnerSay("timer end: playing = "+playing+", Curl="+(string)Curl+", songTrackCnt="+(string)songTrackCnt);
    }
}
