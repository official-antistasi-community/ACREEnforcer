class CfgPatches
{
	class TeamSpeakEnforcer
	{
		// Meta information for editor
		name = "Team Speak Enforcer";
		author[] = {"Sparker", "Killerswin2"};
		url = "";

		// Minimum compatible version. When the game's version is lower, pop-up warning will appear when launching the game.
		requiredVersion = 1.60; 
		// Required addons, used for setting load order.
		// When any of the addons is missing, pop-up warning will appear when launching the game.
		requiredAddons[] = {};
		// List of objects (CfgVehicles classes) contained in the addon. Important also for Zeus content unlocking.
		units[] = {};
		// List of weapons (CfgWeapons classes) contained in the addon.
		weapons[] = {};
	};
};

class CfgFunctions
{
   	class TSE
	{
		class Functions
		{
			class init
			{
				file = "x\TSE\addons\enforcer\Init\fn_init.sqf";
				preInit = 1;
			};
		};
	};
};