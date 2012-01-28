class GameClass {
	// This class stores data for each game, and handles score calculation.
	// Works only with standard 10-pin bowling. Heh.
	constructor() {
		Frame = -1;
		Shot = -1;
		ShotData = [];
	}
	
	function NextFrame() {
		if((Frame+1) > 9) return;
		++Frame;
		Shot = -1;
		ShotData.push([]);
		NextShot();
	}
	
	function NextShot() {
		if (((Shot+1) > 1 && Frame < 9) || ((Shot+1) > 2 && Frame == 9)) return;
		ShotData.top().push(ShotClass());
		++Shot;
	}
	
	function GetCurrShot() {
		return ShotData.top().top();
	}
	
	function GetCurrFrameDowned() {
		local ret = 0;
		foreach(val in ShotData.top())
			ret += val.NumDowned();
		return ret;
	}
	
	function GetFrameDowned(ix) {
		if(ix >= ShotData.len()) return 0;
		local ret = 0;
		foreach(val in ShotData[ix])
			ret += val.NumDowned();
		return ret;
	}
	
	function GetShotDowned(ix, iy) {
		if(ix >= ShotData.len()) return 0;
		if(iy >= ShotData[ix].len()) return 0;
		return ShotData[ix][iy].NumDowned();
	}
	
	function IsStrike(ix) {
		if(ix >= ShotData.len()) return false;
		if(ShotData[ix].len() != 1) return false;
		return ShotData[ix][0].NumDowned() >= 10;
	}
	
	function CalculateScore() {
		local score = 0;
		for(local ix = 0; ix < ShotData.len() && ix < 10; ++ix) {
			local val = ShotData[ix];
			local fscore = 0;
			foreach(wal in val) fscore += wal.NumDowned();
			score += fscore;
			if(ix < 9 && fscore >= 10) { // bonuses galore
				if(val.len() == 1) { // Strike
					local iy = GetShotDowned(ix + 1, 0);
					score += iy + ((ix == 8 || iy < 10) ? GetShotDowned(ix + 1, 1) : GetShotDowned(ix + 2, 0));
				} else if(val.len() == 2) { // Spare
					score += GetShotDowned(ix + 1, 0);
				}
			}
		}
		return score;
	}
	
	Frame = null;
	Shot = null;
	ShotData = null;
	ShotClass = class {
		// This class simply stores data for each shot.
		constructor() {
			PinsDowned = [false, false, false, false, false, false, false, false, false, false];
		}
		
		function DownPin(number) {
			if (number < 0 || number > 9)
				return;
			PinsDowned[number] = true;
		}
		
		function IsDowned(number) {
			return PinsDowned[number];
		}
		
		function IsAllDowned() {
			local ret = true;
			foreach(val in PinsDowned)
				ret = ret && val;
			return ret;
		}
		
		function NumDowned() {
			local ret = 0;
			foreach(val in PinsDowned)
				if(val) ++ret;
			return ret;
		}
		
		PinsDowned = null;
	}
}



// Functions prefixed by On are called from the map by controller;RunScriptCode.
// Functions prefixed by C are EntFire helpers that do things like show text.
// Functions prefixed by L do logic or things that otherwise would be repeated if in On
InGame <- false;
BallInPlay <- true;
Game <- null;
DropDelay <- 1;

function F(targetname, input, delay = 0, params = "") {
	EntFire(targetname, input, params, delay);
}

// Begin On functions
function OnMapSpawn() {
	F("paint_stick", "Paint");
	F("open_dialogue", "PlaySound", 1);
	CShowNewGameHint();
}

function OnBallGutter() {
	if(!InGame || !BallInPlay) return;
	BallInPlay = false;
	CSetAlleyFizzler(true);
	CBeginTimer();
	CRunScriptAfter("LBallDown(\"Gutter! \")", DropDelay);
}

function OnBallIn() {
	if(!InGame) return;
	CSetAlleyFizzler(true);
}

function OnBallDown() {
	if(!InGame || !BallInPlay) return;
	BallInPlay = false;
	CSetAlleyFizzler(true);
	CBeginTimer();
	CRunScriptAfter("LBallDown()", DropDelay);
}

function OnPinDown(n) {
	if(!InGame || Game.GetCurrShot().IsDowned(n)) return;
	print(format("Pin %d downed!\n", n));
	Game.GetCurrShot().DownPin(n);
	CDissolvePin(n);
	CSetCheckbox(n, true);
}

function OnScorePressed() {
	CShowText(format("Score: %d", (Game == null ? 0 : Game.CalculateScore())));
}

function OnControlPressed() {
	if(InGame) {
		CFizzleBall();
		OnBallDown();
	} else {
		LNewGame();
	}
}
// End On functions

// Begin C functions
function CShowText(text = "", delay = 0) {
	F("text", "SetText", delay, text + "");
	F("text", "Display", delay + 0.01);
}

function CRunScriptAfter(code, delay) {
	F("controller", "RunScriptCode", delay, code);
}

function CBeginTimer(delay = 0) {
	F("timer_relay", "Trigger", delay);
}

function CDissolvePin(number, delay = 0) {
	F("dissolver", "Dissolve", delay, format("pin%d", number));
}

function CDissolveAllPins(delay = 0) {
	for(local ix = 0; ix < 10; ++ix)
		CDissolvePin(ix, delay);
}

function CSetAlleyFizzler(state, delay = 0) {
	F("fizzler_AlleyBlocker", state ? "Enable" : "Disable", delay);
}

function CSetCheckbox(number, state, delay = 0) {
	F(format("pin%dfall-display", number), state ? "Check" : "Uncheck", delay);
}

function CResetCheckbox(delay = 0) {
	for(local ix = 0; ix < 10; ++ix) 
		CSetCheckbox(ix, false, delay);
}

function CShowNewGameHint() {
	F("hint_EndRound", "EndHint");
	F("hint_NewGame", "ShowHint");	
}

function CShowEndRoundHint() {
	F("hint_NewGame", "EndHint");
	F("hint_EndRound", "ShowHint");
}

function CSpawnPins(delay = 0) {
	F("pins_maker", "ForceSpawn", delay);
}

function CAllowControl(state, delay = 0) {
	F("button_EndRound", state ? "UnLock" : "Lock", delay);
}

function CDropBall(delay = 0) {
	F("@cube_dropper", "Trigger", delay);
}

function CFizzleBall(delay = 0) {
	F("@cube_dropper", "FireUser1", delay);
}

function CVictory() {
	F("victory_dialogue", "PlaySound");
	F("victorypanel_open", "Trigger");
}
// End C functions

// Begin L functions
function LNewGame() {
	CAllowControl(false);
	CShowEndRoundHint();
	Game = GameClass();
	InGame = true;
	LNewFrame();
}

function LNewFrame(bonus = false) {
	CAllowControl(false);
	CDissolveAllPins();
	if(!bonus) Game.NextFrame();
	else Game.NextShot();
	CResetCheckbox();
	CShowText(format("Frame %d Shot %d. Score: %d", Game.Frame + 1, Game.Shot + 1, Game.CalculateScore()), DropDelay + 1);
	CBeginTimer(0.01);
	CSpawnPins(DropDelay);
	BallInPlay = true;
	CDropBall(DropDelay);
	CSetAlleyFizzler(false, DropDelay);
	CAllowControl(true, DropDelay + 0.01);
}

function LNewShot() {
	Game.NextShot();
	BallInPlay = true;
	CShowText(format("Frame %d Shot %d. Score: %d", Game.Frame + 1, Game.Shot + 1, Game.CalculateScore()), DropDelay + 1);
	CDropBall();
	CSetAlleyFizzler(false);
	CAllowControl(true);
}

function LBallDown(stext = "") {
	BallInPlay = false;
	CAllowControl(false);
	if(Game.GetCurrFrameDowned() == 10) {
		if(Game.Shot == 0 || (Game.Shot >= 1 && Game.Frame >= 9 && Game.GetShotDowned(9, Game.Shot - 1) == 10)) stext = "Strike! ";
		else if(Game.Shot == 1) stext = "Spare! ";
	}
	local text = format("%sThis shot: %d pin(s). This frame: %d pin(s).", stext, Game.GetCurrShot().NumDowned(), Game.GetCurrFrameDowned(), Game.CalculateScore());
	CShowText(text);
	if(Game.GetCurrFrameDowned() == 10 || (Game.Frame == 9 && Game.GetShotDowned(9, Game.Shot) == 10)) {
		if(Game.Frame == 9) {
			if(Game.Shot == 2) LEndGame();
			else LNewFrame(true);
		} else LNewFrame();
	} else if(Game.Frame == 9 && Game.Shot == 1) LEndGame();
	else if(Game.Shot == 1) LNewFrame();
	else if(Game.Shot == 0) LNewShot();
}

function LEndGame() {
	local stext = "";
	local s = Game.CalculateScore();
	if(s == 300) {
		CVictory();
		CShowNewGameHint();
		CFizzleBall();
		CSetAlleyFizzler(false);
		CDissolveAllPins();
		CResetCheckbox();
		InGame = false;
		CAllowControl(false);
		CShowText(format("Game ended. Final score: 300. Please enter the doorway.", stext, s), 1.5);
		return;
	} else if(s == 117) stext = "Master Chief Petty Officer of the Navy. ";
	else if(s == 0) stext = "Amazing! Zero! ";
	CShowNewGameHint();
	CFizzleBall();
	CSetAlleyFizzler(true);
	CDissolveAllPins();
	CResetCheckbox();
	InGame = false;
	CAllowControl(true);
	CShowText(format("Game ended. %sFinal score: %d", stext, s), 1.5);
}

function LHack() {
	for(local ix = 0; ix < 10; ++ix)
		OnPinDown(ix);
	CFizzleBall();
	OnBallDown();
}
// End L functions