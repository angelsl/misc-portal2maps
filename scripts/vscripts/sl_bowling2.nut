class Game {
	// This class stores data for each game, and handles score calculation.
	constructor() {
		Frame = -1;
		Shot = 0;
		ShotData = [];
	}
	
	function NextFrame() {
		ShotData.push([]);
		ShotData.top().push(Shot());
		++Frame;
		Shot = 0;
	}
	
	function NextShot() {
		ShotData.top().push(Shot());
		++Shot;
	}
	
	function GetCurrShot() {
		return ShotData.top().top();
	}
	
	Frame = null;
	Shot = null;
	ShotData = null;
}

class Shot {
	// This class simply stores data for each shot.
	constructor() {
		PinsDowned = [];
		for(local ix = 0; ix < 10; ++ix)
			PinsDowned[ix] = false;
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

On <- {}; // Functions in the On table are called from the map by controller;RunScriptCode.
C <- {}; // Functions in the C table are helpers that do things like show text.
Game <- null;

// Begin On functions
function On::MapSpawn() {
	N::F("paint_stick", "Paint");
	N::F("hint_NewGame", "ShowHint");
}

function On::BallGutter() {
}

function On::BallIn() {
}

function On::BallDown() {
}

function On::PinDown(n) {	
}

function On::ScorePressed() {
}

function On::ControlPressed() {
}
// End On functions

// Begin C functions
function C::ShowText(text = "", delay = 0) {
	F("text", "SetText", delay, text + "");
	F("text", "Display", delay + 0.01);
}

function C::RunScriptAfter(code, delay) {
	F("controller", "RunScriptCode", delay, code);
}

function C::BeginTimer(delay = 0) {
	F("timer_relay", "Trigger", delay);
}

function C::DissolvePin(number) {
}
// End C functions

function F(targetname, input, delay = 0, params = "") {
	EntFire(targetname, input, params, delay);
}