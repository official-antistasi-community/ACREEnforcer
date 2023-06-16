/*
Object which is created per every joined client to store its state
*/

#include "..\OOP_Light\OOP_Light.h"
#include "..\Message\Message.hpp"
#include "..\TSE\messages.hpp"

//#define DEBUG

CLASS("TSEClientData", "")

	VARIABLE("uid"); // UID of the client
	VARIABLE("owner"); // Remote owner ID of the client
	VARIABLE("timeNextUpdate"); // When to update the client next time
	VARIABLE("timeUpdateInterval");
	VARIABLE("serverName"); // TS3 server name reported by client
	VARIABLE("magicNumber"); // Used for remote execution
	VARIABLE("controlsLocked"); // Controls: are they locked(true) or unlocked(true)
	VARIABLE("pluginEnabled"); // is the plugin enabled
	
	STATIC_VARIABLE("all");

	METHOD("new") {
		params [["_thisObject", "", [""]], ["_uid", "", [""]], ["_owner", 0, [0]]];
		SET_VAR(_thisObject, "uid", _uid);
		SET_VAR(_thisObject, "owner", _owner);
		SET_VAR(_thisObject, "timeNextUpdate", time);
		SET_VAR(_thisObject, "timeUpdateInterval", 2);
		SET_VAR(_thisObject, "serverName", "");
		SET_VAR(_thisObject, "controlsLocked", false); // Controls are locked by default
		SET_VAR(_thisObject, "pluginEnabled", false);
		private _all = GET_STATIC_VAR("TSEClientData", "all");
		_all pushBack _thisObject;
		SET_STATIC_VAR("TSEClientData", "all", _all);
	} ENDMETHOD;
	
	METHOD("delete") {
		params [["_thisObject", "", [""]]];
		SET_VAR(_thisObject, "uid", nil);
		SET_VAR(_thisObject, "owner", nil);
		SET_VAR(_thisObject, "timeNextUpdate", nil);
		SET_VAR(_thisObject, "timeUpdateInterval", nil);
		SET_VAR(_thisObject, "serverName", nil);
		SET_VAR(_thisObject, "magicNumber", nil);
		SET_VAR(_thisObject, "controlsLocked", nil);
		SET_VAR(_thisObject, "pluginEnabled", nil);
		private _all = GET_STATIC_VAR("TSEClientData", "all");
		_all = _all - [_thisObject];
		SET_STATIC_VAR("TSEClientData", "all", _all);
	} ENDMETHOD;

	// Asks client to return its TSE state
	METHOD("queryTSEState") {
		params [["_thisObject", "", [""]]];
		private _owner = GET_VAR(_thisObject, "owner");
		private _magicNumber = random 100;
		SET_VAR(_thisObject, "magicNumber", _magicNumber);
		[_magicNumber] remoteExec ["TSE_fnc_reportTSEDataClient", _owner];
		
		// Update the update timer
		private _interval = GET_VAR(_thisObject, "timeUpdateInterval");
		private _timeNew = time + _interval;
		SET_VAR(_thisObject, "timeNextUpdate", _timeNew);
	} ENDMETHOD;
	
	// Initialize osme functions for the client
	METHOD("init") {
		params [["_thisObject", "", [""]]];
		private _owner = GET_VAR(_thisObject, "owner");
		[[], {
			TSE_fnc_reportTSEDataClient = {
				params ["_magicNumber"];
				#ifdef DEBUG
				diag_log format ["[TSE_fnc_reportTSEDataClient] was called: %1", _magicNumber];
				#endif
				private _TSEAddonEnabled = !isNil "TFAR_fnc_isTeamSpeakPluginEnabled";
				private _TSEServerName = "";
				private _TSEChannelName = "";
				private _TSEPluginEnabled = false;
				if (_TSEAddonEnabled) then {
					_TSEPluginEnabled = call TFAR_fnc_isTeamSpeakPluginEnabled;
					_TSEServerName = call TFAR_fnc_getTeamSpeakServerName;
					_TSEChannelName = call TFAR_fnc_getTeamSpeakChannelName;
				};
				
				// check for acre
				if (!isNil "acre_api_fnc_isVOIPConnected") then {
					_TSEAddonEnabled = !isNil "acre_api_fnc_isVOIPConnected";
					_TSEPluginEnabled = call acre_api_fnc_isVOIPConnected;
					_TSEServerName = call acre_api_fnc_getVOIPServerName;
					_TSEChannelName = call acre_api_fnc_getVOIPChannelName;
				};

				[_magicNumber, [_TSEAddonEnabled, _TSEPluginEnabled, _TSEServerName, _TSEChannelName]] remoteExecCall ["TSEClientData_fnc_reportTSEDataServer", 2];
			};
		}] remoteExecCall ["call", _owner];
	} ENDMETHOD;
	
	// Remote-executed by the client at the server to report client's TSE state
	STATIC_METHOD("reportTSEDataServer") {
		params ["_magicNumber", "_TSEData"];
		_TSEData params ["_TSEAddonEnabled", "_TSEPluginEnabled", "_TSEServerName", "_TSEChannelName"];
		#ifdef DEBUG
		diag_log format ["[reportTSEDataServer] was called: %1", _this];
		#endif
		// Look up which client has reported its state
		private _remoteOwner = remoteExecutedOwner;
		private _object = CALL_STATIC_METHOD("TSEClientData", "findByOwner", [_remoteOwner]);
		// If the object was found
		if (_object != "") then {
			// Check the magic number
			private _thisMagicNumber = GET_VAR(_object, "magicNumber");
			if (_magicNumber == _thisMagicNumber) then {
				// Set object's variables
				SET_VAR(_object, "serverName", _TSEServerName);
				SET_VAR(_object, "pluginEnabled", _TSEPluginEnabled);
				// Send message to TSE
				private _msg = MESSAGE_NEW();
				_msg set [MESSAGE_ID_TYPE, MESSAGE_TYPE_CLIENT_REPORTED];
				_msg set [MESSAGE_ID_DATA, _object];
				CALL_METHOD(gTSE, "postMessage", [_msg]);
			} else {
				diag_log format ["[TSE] Error: Number is wrong for %1", _object];
			};
		} else {
			diag_log format ["[TSE] Error: clientData not found for owner: %1", _remoteOwner];
		};
	} ENDMETHOD;
	
	// Locks controls and shows a message
	METHOD("lockControls") {
		params [["_thisObject", "", [""]], "_messageText", "_TS3ServerAddressDisplay"];
		
		private _owner = GET_VAR(_thisObject, "owner");
		[[_messageText, _TS3ServerAddressDisplay], {
			params ["_messageText", "_TS3ServerAddressDisplay"];
			systemChat "Connection not active; Your controls are now locked!";
			
			private _TSEAddonEnabled = !isNil "TFAR_fnc_isTeamSpeakPluginEnabled" ;
			private _TSEPluginEnabled = false;
			if (_TSEAddonEnabled) then { _TSEPluginEnabled = call TFAR_fnc_isTeamSpeakPluginEnabled; };
			if (!isNil "acre_api_fnc_isVOIPConnected") then {_TSEPluginEnabled = call acre_api_fnc_isVOIPConnected;};
			private _text = format [_messageText,
									_TS3ServerAddressDisplay, ["disabled", "enabled"] select _TSEAddonEnabled, ["disabled", "enabled"] select _TSEPluginEnabled];
			"TSE_screenBlock" cutText [_text, "BLACK", 1, true, false];
			player enableSimulation false;
		}] remoteExecCall ["call", _owner];
		SET_VAR(_thisObject, "controlsLocked", true);
	} ENDMETHOD;

	// Unlocks controls and disables the message
	METHOD("unlockControls") {
		params [["_thisObject", "", [""]]];
		private _owner = GET_VAR(_thisObject, "owner");
		[[], {
			systemChat "Connection detected; your controls are now unlocked!";
			"TSE_screenBlock" cutFadeOut 1;
			player enableSimulation true;
		}] remoteExecCall ["call", _owner];
		private _owner = GET_VAR(_thisObject, "owner");
		SET_VAR(_thisObject, "controlsLocked", false);
	} ENDMETHOD;
	
	
	
	
	// Methods to get variable values
	METHOD("getControlsLocked") {
		params [["_thisObject", "", [""]]];
		GET_VAR(_thisObject, "controlsLocked")
	} ENDMETHOD;
	
	METHOD("getServerName") {
		params [["_thisObject", "", [""]]];
		GET_VAR(_thisObject, "serverName")
	} ENDMETHOD;
	
	METHOD("isPluginEnabled") {
		params [["_thisObject", "", [""]]];
		GET_VAR(_thisObject, "pluginEnabled")
	} ENDMETHOD;

	
	
	// Checks if the update time for this client has passed
	METHOD("isUpdateRequired") {
		params [["_thisObject", "", [""]]];
		private _time = GET_VAR(_thisObject, "timeNextUpdate");
		if (time > _time) then {
			true;
		} else {
			false;
		};
	} ENDMETHOD;

	// Increases the next update time by given value
	METHOD("setUpdateInterval") {
		params [["_thisObject", "", [""]], ["_interval", 10, [0]]];
		private _time = time + _interval;
		SET_VAR(_thisObject, "timeNextUpdate", _time);
		SET_VAR(_thisObject, "timeUpdateInterval", _interval);
	} ENDMETHOD;
	
	
	
	// Finding the object by its UID or owner ID
	STATIC_METHOD("findByOwner") {
		params [ ["_owner", 0, [0]] ];
		private _object = "";
		private _all = GET_STATIC_VAR("TSEClientData", "all");
		{
			private _thisOwner = GET_VAR(_x, "owner");
			if (_thisOwner == _owner) exitWith {_object = _x;};
		} forEach _all;
		_object
	} ENDMETHOD;
	
	STATIC_METHOD("findByUID") {
		params [ ["_uid", "", [""]] ];
		private _object = "";
		private _all = GET_STATIC_VAR("TSEClientData", "all");
		{
			private _thisUID = GET_VAR(_x, "uid");
			if (_thisUID == _uid) exitWith {_object = _x;};
		} forEach _all;
		_object
	} ENDMETHOD;
	
ENDCLASS;

SET_STATIC_VAR("TSEClientData", "all", []);