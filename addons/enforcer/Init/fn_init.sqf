#include "..\OOP_Light\OOP_Light.h"

// Initialize functions
TSE_fnc_onPlayerConnected = compileFinal preprocessFileLineNumbers "x\TSE\addons\enforcer\Init\onPlayerConnected.sqf";
TSE_fnc_handlePlayerConnected = compileFinal preprocessFileLineNumbers "x\TSE\addons\enforcer\Init\handlePlayerConnected.sqf";
TSE_fnc_onPlayerDisconnected = compileFinal preprocessFileLineNumbers "x\TSE\addons\enforcer\Init\onPlayerDisconnected.sqf";

// Initialize event handlers
addMissionEventHandler ["PlayerConnected", TSE_fnc_onPlayerConnected];
addMissionEventHandler ["PlayerDisconnected", TSE_fnc_onPlayerDisconnected];

// Initialize OOP_Light
call compile preprocessFileLineNumbers "x\TSE\addons\enforcer\OOP_Light\OOP_Light_init.sqf";

// Initialize MessageReceiver class
call compile preprocessFileLineNumbers "x\TSE\addons\enforcer\MessageReceiver\MessageReceiver.sqf";

// Initialize MessageLoop class
call compile preprocessFileLineNumbers "x\TSE\addons\enforcer\MessageLoop\MessageLoop.sqf";

// Initialize TSE class
call compile preprocessFileLineNumbers "x\TSE\addons\enforcer\TSE\TSE.sqf";

// Initialize TSEClientData class
call compile preprocessFileLineNumbers "x\TSE\addons\enforcer\TSEClientData\TSEClientData.sqf";

diag_log "[TSE] Info: Module init done";

// Create a new message loop
private _msgLoop = NEW("MessageLoop", []);

// Create a new TSE object
gTSE = NEW("TSE", [_msgLoop]);