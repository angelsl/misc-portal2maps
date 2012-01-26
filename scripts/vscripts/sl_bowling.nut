Shot <- 0;
PinsDown <- [false, false, false, false, false, false, false, false, false, false];
CurrentFrame <- 0;
DownedPerFrame <- [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; 
Game <- false;
DropDelay <- 1;

function MapStart()
{
	EntFire("hint_NewGame", "ShowHint");
	//EntFire("hint_ShowScore", "ShowHint");
	EntFire("paint_stick", "Paint");
}

function NewGame()
{
	AllowControl(false);
	EntFire("hint_NewGame", "EndHint");
	EntFire("hint_EndRound", "ShowHint");
	Shot = 0;
	PinsDown = [false, false, false, false, false, false, false, false, false, false];
	CurrentFrame = 0;
	DownedPerFrame = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
	Game = true;
	NewFrame();
	ShowText("Frame " + (CurrentFrame+1), DropDelay);
}

function NewFrame()
{
	if(!Game) return;
	Debug("NewFrame()");
	DissolveAllPins();
	PinsDown = [false, false, false, false, false, false, false, false, false, false];
	Start4SecTimer(0.01);
	DropBall(DropDelay); // drop ball
	EntFire("pins_maker", "ForceSpawn", "", DropDelay); // spawn turrets
	ResetCheckbox();
	EntFire("fizzler_AlleyBlocker", "Disable", "", DropDelay);
	AllowControl(true, DropDelay+ 0.01);
}

function Debug(add)
{
	SendToConsole("echo \"[" + add + "] Frame " + CurrentFrame + " Shot " + Shot + " DPF " + DTFDebug() + "\"");
}

function BallIn()
{
	if(!Game) return;
	EntFire("fizzler_AlleyBlocker", "Enable"); // turn on fizzler
}

function DissolvePin(number)
{
	EntFire("dissolver", "Dissolve", "pin"+number);
}

function DissolveAllPins()
{
	for(local i = 1; i < 11; i += 1)
	{
		DissolvePin(i);
	}
}

function ResetCheckbox()
{
	for(local i = 1; i < 11; i += 1)
	{
		EntFire("pin" +i+ "fall-display", "Uncheck");
	}
}

function Hack()
{
	for(local i = 1; i < 11; i += 1)
	{
		PinDown(i);
	}
}

function PinDown(number)
{
	if(!Game) return;
	if(IsDown(number)) return;
	DissolvePin(number);
	PinsDown[number-1] = true;
	EntFire("pin" +number+ "fall-display", "Check");
	// ShowText("Pin " + number + " down!");
}

function ShowText(text, delay = 0)
{
	EntFire("text", "SetText", text+"", delay);
	EntFire("text", "Display", "", delay + 0.01);
}

function NumPinsDown()
{
	local r = 0;
	for(local i = 0; i < 10; i += 1)
	{
		if(PinsDown[i]) r += 1;
	}
	return r;
}

function FrameNumPinsDown()
{
	local ix = CurrentFrame * 2 + Shot; // frame 0 shot 1
	local r = DownedPerFrame[ix]; // 1
	for(local iy = 1; iy <= Shot; iy+=1) 
		r += DownedPerFrame[ix-iy];
	return r;
}

function IsDown(number)
{
	return PinsDown[number-1];
}

function RunScriptAfter(code, delay)
{
	EntFire("controller", "RunScriptCode", code, delay);
}

function TriggerBallGutter()
{
	Start4SecTimer();
	BallIn();
	RunScriptAfter("BallGutter()", DropDelay);
}

function TriggerBallDown()
{
	Start4SecTimer();
	RunScriptAfter("BallDown()", DropDelay);
}

function BallGutter()
{
	if(!Game) return;
		
	BallDown(true, true);
}

function BallDown(showtext = true, gutter = false)
{
	if(!Game) return;
	AllowControl(false);
	
	// if (First Shot && Strike) || (Second Shot && not frame 10) || (Second Shot && Frame 10 && No Spare/Strike) || Third Shot) End
	Debug("BallDown()");
	DoScore();
	if((Shot == 0 && CurrentFrame != 9) && NumPinsDown() == 10) { if(showtext) ShowText("Strike! Score: " + CalculateScore()); EndFrame(false); }
	else if(Shot == 2 && CurrentFrame == 9 && NumPinsDown() == 10) { if(showtext) ShowText("Strike! Score: " + CalculateScore()); EndFrame(false); }
	else if((Shot == 1 && (CurrentFrame != 9 || (CurrentFrame == 9 && (DownedPerFrame[18] + DownedPerFrame[19]) < 10))) || Shot >= 2) EndFrame(showtext, gutter);
	else if(CurrentFrame == 9 && Shot < 2 && NumPinsDown() == 10) { if(showtext) ShowText("Strike! Score: " + CalculateScore()); Shot += 1; NewFrame();  }
	// else -> First Shot
	else { 
		Shot += 1;
		DropBall(); 
		if(showtext && (NumPinsDown() >= 0 || !gutter)) ShowText(NumPinsDown() + " pins downed. Score: " + CalculateScore());
		else if(showtext && gutter && NumPinsDown() == 0) { ShowText("Gutter! Score: " + CalculateScore()); }
		//PinsDown = [false, false, false, false, false, false, false, false, false, false];
		EntFire("fizzler_AlleyBlocker", "Disable");
		AllowControl(true);
	}
	
}

function EndFrame(showtext = true, gutter = false)
{
	if(!Game) return;
	Debug("EndFrame()");
	if(showtext) {
		local n = FrameNumPinsDown();
		if(gutter && NumPinsDown() == 0) { ShowText("Gutter! Score: " + CalculateScore()); }
		else if(n == 10 && (CurrentFrame != 9 || (CurrentFrame == 9 && Shot == 1))) ShowText("Spare! Score: " + CalculateScore());
		else ShowText(n + " pins downed this frame. Score: " + CalculateScore());
	}
	if(CurrentFrame == 9)
	{
		EndGame(); return;
	}
	CurrentFrame += 1;
	Shot = 0;
	NewFrame();
	ShowText("Frame " + (CurrentFrame+1), DropDelay);
}

function EndGame()
{
	if(!Game) return;
	local s = CalculateScore();
	if(s == 117) ShowText("Game ended. SPARTAN-117. Post this on the forums. Easter Eggs~");
	else if(s == 300) ShowText("Game ended. Amazing! Perfect game! Final score: " + s);
	else if(s == 0) ShowText("Game ended. Amazing! Zero! Final score: " + s);
	else ShowText("Game ended. Final score: " + s);
	Game = false;
	EntFire("hint_NewGame", "ShowHint");
	EntFire("hint_EndRound", "EndHint");
	DissolveAllPins();
	AllowControl(true);
}

function DropBall(delay = 0)
{
	if(!Game) return;
	EntFire("@cube_dropper", "Trigger", "", delay);
}

// it's DropDelay seconds now. rofl. 
function Start4SecTimer(delay = 0)
{
	EntFire("timer_relay", "Trigger", "", delay);
}

function DoScore()
{
	local ix = CurrentFrame * 2 + Shot;
	DownedPerFrame[ix] = NumPinsDown();
	if(ix == 20 || (ix == 19 && DownedPerFrame[18] == 10)) return;
	for(local iy = 1; iy <= Shot; iy+=1) 
		DownedPerFrame[ix] -= DownedPerFrame[ix-iy];
}

function ControlPressed()
{
	if(Game) {
		EntFire("@cube_dropper", "FireUser1");
		EntFire("fizzler_AlleyBlocker", "Enable");
		BallDown();
	} else {
		NewGame();
	}
}

function AllowControl(allow, delay = 0)
{
	if(allow) EntFire("button_EndRound", "UnLock", "", delay);
	else EntFire("button_EndRound", "Lock", "", delay);
}

function DTFDebug()
{
	local r = "[";
	local sep = "";
	for(local ix = 0; ix < DownedPerFrame.len(); ix += 1)
	{
		r += sep + DownedPerFrame[ix];
		sep = ", ";
	}
	r += "]";
	return r;
}

function CalculateScore()
{
	local r = 0;
	for(local ix = 0; ix < DownedPerFrame.len(); ix+= 1)
	{
		local c = DownedPerFrame[ix];
		r += c;
		if((ix % 2 == 0) && c >= 10 && ix < 18) {
			if(ix < 16) {
				local d = DownedPerFrame[ix + 2];
				r += d;
				if(d == 10) {
					local e = DownedPerFrame[ix + 4];
					r += e;
				} else {
					local e = DownedPerFrame[ix + 3];
					r += e;
				}
			} else if(ix == 16)
			{
				r += DownedPerFrame[ix + 2] + DownedPerFrame[ix + 3];
			}
			ix += 1;
		}
		else if((ix % 2) == 1 && (c+DownedPerFrame[ix-1])>=10 && ix < 18)
		{
			r += DownedPerFrame[ix+1];
		}
	}
	return r;
}

function ScorePressed()
{
	ShowText("Score: " + CalculateScore());
}