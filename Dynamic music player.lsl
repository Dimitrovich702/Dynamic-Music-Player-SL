//start_unprocessed_text
/*integer DEBUG = TRUE;
float INTERVAL = 20 ;

/|/float INTERVAL =  llGetNotecardLine/( Name, pota );
float V = 1.0;
integer pota = 0;
integer CHAN = -392412;
integer ASSET = 12;

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

Initialize()
{
    llSetText("", <1,1,1>, 1.0);
                  CHAN = llFloor(llFrand(1000000) - 100000);
// dynamic chan 
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

    llOwnerSay( "Loading: "+ Name);

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

    llOwnerSay("Playing: "+ Name);

    llPlaySound(llList2Key(Musicuuids, Curl++), V);
    llPreloadSound( llList2Key(Musicuuids, Curl) );
    llSetTimerEvent(INTERVAL-1.0);
}


StopSong()
{
    if(DEBUG) llOwnerSay("StopSong");

    /|/ llPlaySound(silence, 0.0);

    llStopSound();
    llSetTimerEvent(0.0);

    playing = "";

    Musicuuids = [];
}

default
{
    state_entry()
    {
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
        if(DEBUG) llOwnerSay("dataserver: "+(string)songTrackCnt+" = "+data);

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
    
                    Musicuuids += llList2String(dataParts, 0);
                    songTrackCnt += 1;
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

            llDialog(llDetectedKey(0), DirSound, but, CHAN);
        }
    }

    listen(integer CHAN, string name, key id, string message)
    {
        if(DEBUG) llOwnerSay("listen: "+message);

        /|/list words = llParseString2List(message, [" ", " ", "="], []);
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

        llSetTimerEvent(INTERVAL);

        if ( Curl <= songTrackCnt )
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

            llPlaySound(silence, 0.0);

            llSetTimerEvent(0.0);
        }

        if(DEBUG) llOwnerSay("timer end: playing = "+playing+", Curl="+(string)Curl+", songTrackCnt="+(string)songTrackCnt);
    }
}*/
//end_unprocessed_text
//nfo_preprocessor_version 0
//program_version Firestorm-Releasex64 6.6.14.69596 - LiamHoffen & Dimitrovich702
//last_compiled 12/24/2023 
//mono




integer DEBUG = TRUE;
float INTERVAL = 20 ;


float V = 1.0;
integer CHAN = -192117;
integer ASSET = 6;
integer inti = TRUE;
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


StopSong()
{
    if(DEBUG) llOwnerSay("StopSong");

    

    llStopSound();
    llSetTimerEvent(0.0);

    playing = "";

    Musicuuids = [];
}

PlaySong()
{
    if(DEBUG) llOwnerSay("PlaySong with INTERVAL=" + (string)INTERVAL);

    playing = Name;

    Curl = 0;

    llOwnerSay("Playing: "+ Name);

    llPlaySound(llList2Key(Musicuuids, Curl++), V);
    llPreloadSound( llList2Key(Musicuuids, Curl) );
    llSetTimerEvent(INTERVAL-1.0);
}

LoadSong()
{
    if(DEBUG) llOwnerSay("LoadSong");

    llOwnerSay( "Loading: "+ Name);

    INTERVAL = 0;

    songTrackCnt = 0;
    lineNumber = 0;
    DataRequest = llGetNotecardLine( Name, lineNumber++ );
}

Initialize()
{
    llSetText("", <1,1,1>, 1.0);
   
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

default
{
    state_entry()
    {
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
        if(DEBUG) llOwnerSay("dataserver: "+(string)songTrackCnt+" = "+data);

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
    
                    Musicuuids += llList2String(dataParts, 0);
                    songTrackCnt += 1;
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

            llDialog(llDetectedKey(0), DirSound, but, CHAN);
        }
    }

    listen(integer CHAN, string name, key id, string message)
    {
        if(DEBUG) llOwnerSay("listen: "+message);

        
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

        llSetTimerEvent(INTERVAL);

        if ( Curl <= songTrackCnt )
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

            llPlaySound(silence, 0.0);

            llSetTimerEvent(0.0);
        }

        if(DEBUG) llOwnerSay("timer end: playing = "+playing+", Curl="+(string)Curl+", songTrackCnt="+(string)songTrackCnt);
    }
}
