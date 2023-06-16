#include "..\OOP_Light\OOP_Light.h"
#include "..\Message\Message.hpp"
#include "messages.hpp"

params [ ["_thisObject", "", [""]] , ["_msg", [], [[]]] ];

//#define DEBUG

#ifdef DEBUG
diag_log format ["[TSE] handleMessage: %1", _msg];
#endif

private _msgType = _msg select MESSAGE_ID_TYPE;

switch (_msgType) do {
	case (MESSAGE_TYPE_CLIENT_CONNECTED): {
		private _msgData = _msg select MESSAGE_ID_DATA;
		_msgData params ["_uid", "_owner"];
		diag_log format ["[TSE] Info: Client connected: %1", _msgData];
		private _args = [_uid, _owner];
		private _clientData = NEW("TSEClientData", _args);
		CALL_METHOD(_clientData, "init", []);
		CALL_METHOD(_clientData, "queryTSEState", []); // Get client's TSE state
		CALL_METHOD(_clientData, "setUpdateInterval", [4]); // Give the client some time to return its data
	};
	
	case (MESSAGE_TYPE_CLIENT_DISCONNECTED): {
		private _msgData = _msg select MESSAGE_ID_DATA;
		_msgData params ["_uid", "_owner"];
		diag_log format ["[TSE] Info: Client disconnected: %1", _msgData];
		// Find the TSEClientData object with corresponding UID
		private _clientData = CALL_STATIC_METHOD("TSEClientData", "findByUID", [_uid]);
		if (_clientData != "") then {
			DELETE(_clientData);
		} else {
			diag_log format ["[TSE] Error: clientData not found for UID: %1", _uid];
		};
	};
	
	case (MESSAGE_TYPE_TIMER): {
		private _msgData = _msg select MESSAGE_ID_DATA;
		#ifdef DEBUG
		diag_log format ["[TSE] Info: Message: timer!"];
		#endif
		// Check all clients
		private _allClients = GET_STATIC_VAR("TSEClientData", "all");
		{
			if (CALL_METHOD(_x, "isUpdateRequired", [])) then {
				if (CALL_METHOD(_thisObject, "handleClientState", [_x])) then { // Shoudl we retrieve the client's state again?
					CALL_METHOD(_x, "queryTSEState", []);
				};
			};
		} forEach _allClients;
	};
	
	case (MESSAGE_TYPE_CLIENT_REPORTED): {
		private _clientData = _msg select MESSAGE_ID_DATA; // TSEClientData
		#ifdef DEBUG
		diag_log format ["[TSE] Info: Message: client reported!"];
		#endif
		CALL_METHOD(_thisObject, "handleClientState", [_clientData]);
	};
};