
/*
       if(llJsonGetValue(link_msg, ["target"]) == "DISPLAY")
        {
            // display?
            if(llJsonGetValue(link_msg, ["action"]) == "display") { RenderDisplay(link_msg); }
            // apply style?
            if(llJsonGetValue(link_msg, ["action"]) == "apply") { UpdateDisplay(link_msg); };*/


integer current;
integer end;
string title;
float currentPlayTime;
float totalTime;
string errorText;

integer mode;

integer listener;
integer dlgChannel;

ShowDialog(key avi)
{
    if (listener != 0)
        llListenRemove(listener);
    dlgChannel = -1000000 + (integer)llFrand(10000.0);
    listener = llListen(dlgChannel, "", llGetOwner(), "");

    string msg = "Select an action";
    list buttons = [ "Error", "Load", "Play" ];
    llDialog(avi, msg, buttons, dlgChannel);
}

SendError(string errorText)
{
    list errorList = [ "target", "DISPLAY", "action", "display", "type", "error", "msg", errorText ];
    string json = llList2Json(JSON_OBJECT, errorList);
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, errorList), NULL_KEY);
}

TriggerLoad()
{
    title = "test loading";
    current = 0;
    end = 300;
    mode = 1;
    llSetTimerEvent(3.0);
    SendLoadingList();
}

SendLoadingList()
{
    list loadingList = [ "target", "DISPLAY", "action", "display", "type", "loading", "current", current, "end", end, "title", title ];
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, loadingList), NULL_KEY);
}

TriggerPlay()
{
    title = "test playing";
    currentPlayTime = 0.0;
    totalTime = 60.0;
    mode = 2;
    llSetTimerEvent(3.0);
    SendPlayingList();

}

SendPlayingList()
{
    list playingList = [ "target", "DISPLAY", "action", "display", "type", "playing", "time", currentPlayTime, "totalTime", totalTime, "title", title ];
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, playingList), NULL_KEY);
}

default
{
    state_entry()
    {
        /*
            action      display
            type        playing / loading / error
            title       - for playing and loading
            time        - for playing
            totalTime   - for playing
            current     - for loading
            end         - for loading
            msg         - for error

        */
        list loadingList = [ "target", "DISPLAY", "action", "display", "type", "loading", "current", current, "end", end, "title", title ];
        list playingList = [ "target", "DISPLAY", "action", "display", "type", "playing", "time", currentPlayTime, "totalTime", totalTime, "title", title ];
        list errorList = [ "target", "DISPLAY", "action", "display", "type", "error", "msg", errorText ];
    }
    timer()
    {
        integer done = FALSE;
        if (mode == 1)
        {
            current += 10;
            if (current > end)
                current = end;
            SendLoadingList();
            if (current == end)
                done = TRUE;
        }
        else if (mode == 2)
        {
            currentPlayTime += 3.0;
            if (currentPlayTime > totalTime)
                currentPlayTime = totalTime;
            SendPlayingList();
            if (currentPlayTime >= totalTime)
                done = TRUE;
        }
        if (done)
        {
            llSetTimerEvent(0);
            SendError("");
        }

    }
    listen(integer channel, string name, key id, string msg)
    {
        if (msg == "Error")
            SendError("Here is the error we wanted to see.");
        else if (msg == "Load")
            TriggerLoad();
        else if (msg == "Play")
            TriggerPlay();
        ShowDialog(id);
    }

    touch_start(integer num)
    {
        ShowDialog(llDetectedKey(0));
    }
}