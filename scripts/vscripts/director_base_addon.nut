//=======================================================================\\
//		Copyright TSP172 || https://steamcommunity.com/id/tsp172/        \\
// 		You can freely modify and use this script in any of your maps    \\
// 		        Made for L4D2, credit is appreciated				     \\
//=======================================================================\\

const IN_ATTACK = 1;
const IN_JUMP = 2;
const IN_DUCK = 4;
const IN_FORWARD = 8;
const IN_BACK = 16;
const IN_USE = 32;
const IN_CANCEL = 64;
const IN_LEFT = 512;
const IN_RIGHT = 1024;
const IN_ATTACK2 = 2048;
const IN_RELOAD = 8192;

::BOTS_STAND_STILL <- 0;
::HUD_TOGGLE <- 1;

::HOST_CAMERA <- SpawnEntityFromTable("point_viewcontrol_survivor", {
    angles = QAngle(0, 0, 0),
    targetname = "host_camera",
    spawnflags = 3,
    LagCompensate = 1,
    fov = 90,
    fov_rate = 0.0,
    origin = Vector(0, 0, 0)
})

function OnGameEvent_player_say( params )
{
    if("userid" in params && "text" in params)
    {
    	local player = GetPlayerFromUserID(params.userid)
    	local whatsay = params.text.toupper()
        // && Convars.GetStr("sv_cheats") == "1"
        if(player == GetListenServerHost())
		{
			switch(whatsay)
            {
                case "!FREECAM": 
                {
                    ::HOST_CAMERA.GetScriptScope().FreeCameraActive = !::HOST_CAMERA.GetScriptScope().FreeCameraActive;
                    ::HOST_CAMERA.SetOrigin(GetListenServerHost().GetOrigin() + Vector(0, 0, 50));
                    if(::HOST_CAMERA.GetScriptScope().FreeCameraActive)
                    {
                        DoEntFire("!self", "Enable", "!activator", 0, GetListenServerHost(), ::HOST_CAMERA);
                        NetProps.SetPropInt(GetListenServerHost(), "movetype", 0); // 0 = MOVETYPE_NONE
                        //Convars.SetValue("go_away_from_keyboard", "1");
                        printl("Camera Activated!");
                    }
                    else 
                    {
                        DoEntFire("!self", "Disable", "!activator", 0, GetListenServerHost(), ::HOST_CAMERA);
                        //Convars.SetValue("go_away_from_keyboard", "0");
                        NetProps.SetPropInt(GetListenServerHost(), "movetype", 2); // 2 = MOVETYPE_WALK
                        printl("Camera Disabled!");
                    }
                    break;
                }
                case "!TIMESCALE":
                {
                    local timescale = params.text.split(" ")[1];
                    if(timescale != null && timescale != "" && (typeof(timescale) == "float" || typeof(timescale) == "integer"))
                    {
                        Convars.SetValue("host_timescale", timescale);
                        printl("Timescale Set To: " + timescale);
                    }
                    else
                    {
                        printl("Please specify a float or integer value after the command.");
                    }
                    break;
                }
                case "!FREEZEBOTS":
                {
                    if(::BOTS_STAND_STILL == 0)
                    {
                        ::BOTS_STAND_STILL = 1;
                        Convars.SetValue("sb_hold_position", 1);
                        printl("Bots Frozen!");
                    }
                    else
                    {
                        ::BOTS_STAND_STILL = 0;
                        Convars.SetValue("sb_hold_position", 0);
                        printl("Bots Unfrozen!");
                    }
                    break;
                }
                case "!HUDTOGGLE":
                {
                    if(::HUD_TOGGLE == 1)
                    {
                        ::HUD_TOGGLE = 0;
                        Convars.SetValue("cl_drawhud", 0);
                        Convars.SetValue("cc_subtitles", 0);
                        printl("HUD Disabled!");
                    }
                    else
                    {
                        ::HUD_TOGGLE = 1;
                        Convars.SetValue("cl_drawhud", 1);
                        Convars.SetValue("cc_subtitles", 1);
                        printl("HUD Enabled!");
                    }
                    break;
                }
            }

            local theCommand = split(whatsay, " ")
            if(theCommand.len() > 0 && theCommand[0] == "!FREECAMSPEED")
            {
                if (theCommand.len() < 2)
                {
                    printl("Please specify a numeric value after the command.");
                    return false;
                }
                local commandParam = theCommand[1];
                local newValue = commandParam.tofloat();

                ::HOST_CAMERA.GetScriptScope().CameraMoveSpeed = newValue;
                
                printl("Camera Speed Set To: " + newValue);
            }
		}
    }
}

if (::HOST_CAMERA.ValidateScriptScope())
{
    ::HOST_CAMERA.GetScriptScope()["FreeCameraActive"] <- false;
    ::HOST_CAMERA.GetScriptScope()["CameraMoveSpeed"] <- 500;
    ::HOST_CAMERA.GetScriptScope()["LastThinkTime"] <- Time();
	::HOST_CAMERA.GetScriptScope()["FreeCameraThink"] <- function()
    {
        if(!::HOST_CAMERA.GetScriptScope().FreeCameraActive)
        {
            ::HOST_CAMERA.GetScriptScope().LastThinkTime = Time();
            return 0.01;
        }

        local host = GetListenServerHost();

        if(host == null || !host.IsValid())
        {
            ::HOST_CAMERA.GetScriptScope().LastThinkTime = Time();
            return 0.01;
        }


        local buttons = host.GetButtonMask()
        local pos = ::HOST_CAMERA.GetOrigin();
        local forward = ::HOST_CAMERA.GetForwardVector();
        local right = ::HOST_CAMERA.GetAngles().Left() * 1.0;
        local speed = ::HOST_CAMERA.GetScriptScope().CameraMoveSpeed * 0.01;
        //printl("Speed: " + speed);
        //printl("Buttons: " + buttons);

        // Movement Key Checks (Bitwise operations on m_nButtons)
        if (buttons & IN_FORWARD)   pos += (forward * speed); // IN_FORWARD (W)
        if (buttons & IN_BACK)   pos -= (forward * speed); // IN_BACK (S)
        if (buttons & IN_LEFT) pos -= (right * speed);   // IN_LEFT (A)
        if (buttons & IN_RIGHT) pos += (right * speed);  // IN_RIGHT (D)
        if (buttons & IN_JUMP)   pos += Vector(0, 0, speed); // IN_JUMP
        if (buttons & IN_DUCK)   pos -= Vector(0, 0, speed); // IN_DUCK

        ::HOST_CAMERA.SetAngles(host.EyeAngles());
        ::HOST_CAMERA.SetOrigin(pos);

        return 0.01;
    }

    AddThinkToEnt(::HOST_CAMERA, "FreeCameraThink");
}

printl("FREE CAMERA SCRIPT LOADED");