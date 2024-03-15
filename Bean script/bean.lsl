//        ,
//        |\        __
//        | |      |--|             __
//        |/       |  |            |~'
//       /|_      () ()            |
//      //| \             |\      ()
//     | \|_ |            | \
//      \_|_/            ()  |
//        |                  |
//       @'                 ()
//  10th January, 2023
//  Developed by BEAN
//  secondlife:///app/agent/b3eb5433-ff0a-44fe-9a59-5615a090ae94/about
//  https://marketplace.secondlife.com/stores/232338

// ================
// Globals
// ================
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
    string type = llJsonGetValue(JSON, [ "type"]);
    
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
        priorityTag = llGetUnixTime(); // + 3;
        
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

default
{
    link_message(integer link_sender, integer link_number, string link_msg, key link_key)
    {
        // verify it's for us
        if(llJsonGetValue(link_msg, ["target"]) == "DISPLAY")
        {
            // display?
            if(llJsonGetValue(link_msg, ["action"]) == "display") 
            {
                RenderDisplay(link_msg); 
            }
            // apply style?
            else if(llJsonGetValue(link_msg, ["action"]) == "apply") 
            { 
                UpdateDisplay(link_msg); 
            }
        }
    }
}
