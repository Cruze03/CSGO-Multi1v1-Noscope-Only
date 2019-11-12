/*
Thanks Bara. Took help from his headshot only addon of multi1v1. Took help from that code.
Thanks Abner. Took help from his noscope only plugin. Took help from that code.
*/
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <multi1v1>

#pragma semicolon 1
#pragma newdecls required

#define m_flNextSecondaryAttack FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack") 

bool g_Noscope[MAXPLAYERS+1] = false;

ConVar gh_MessageLoc, gh_Ranked, gh_KnifeDamage, gh_Weapon;

int Rand;

public Plugin myinfo =
{
    name = "CS:GO Multi1v1: Noscope round addon",
    author = "Cruze",
    description = "Adds an noscope round-type",
    version = "1.2.5",
    url = "http://steamcommunity.com/profiles/76561198132924835"
};

public void OnPluginStart()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			OnClientPutInServer(client);
		}
	}
	gh_MessageLoc 	= CreateConVar("sm_1v1_ns_msgloc", 		"1", "Message location of \"This is noscope round\" message. 0 = Chat. 1 = Hintbox");
	gh_Ranked 		= CreateConVar("sm_1v1_ns_ranked", 		"1", "Ranked? 0 for no.");
	gh_KnifeDamage  = CreateConVar("sm_1v1_ns_knifedmg", 	"0", "1 - Enable or 0 - Disable knife damage in noscope round.");
	gh_Weapon		= CreateConVar("sm_1v1_ns_weapon", 		"3", "1 - AWP, 2 - SSG 08, 3 - Both");
	
	HookEvent("round_start", Event_RoundStart);
	AutoExecConfig(true, "plugin.1v1ns");
	LoadTranslations("multi1v1-ns.phrases");
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PreThink, PreThink);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	g_Noscope[client] = false;
}

public Action PreThink(int client)
{
	if(IsPlayerAlive(client) && g_Noscope[client])
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(!IsValidEdict(weapon) || !IsValidEntity(weapon))
			return Plugin_Continue;

		char item[64];
		GetEdictClassname(weapon, item, sizeof(item)); 
		if(StrEqual(item, "weapon_awp") || StrEqual(item, "weapon_ssg08"))
		{
			SetEntDataFloat(weapon, m_flNextSecondaryAttack, GetGameTime() + 9999.9);
		}
	}
	return Plugin_Continue;
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (!IsValidEntity(weapon) || gh_KnifeDamage.BoolValue)
	{
		return Plugin_Continue;
	}
	if (attacker <= 0 || attacker > MaxClients)
	{
		return Plugin_Continue;
	}
	if (victim <= 0 || victim > MaxClients)
	{
		return Plugin_Continue;
	}
	if(!g_Noscope[attacker] || !g_Noscope[victim])
	{
		return Plugin_Continue;
	}
	char WeaponName[64];
	GetEntityClassname(weapon, WeaponName, sizeof(WeaponName));
	if(StrContains(WeaponName, "knife", false) != -1 || StrContains(WeaponName, "bayonet", false) != -1 || StrContains(WeaponName, "fists", false) != -1 || StrContains(WeaponName, "axe", false) != -1 || StrContains(WeaponName, "hammer", false) != -1 || StrContains(WeaponName, "spanner", false) != -1 || StrContains(WeaponName, "melee", false) != -1)
	{
		PrintCenterText(attacker, "%t", "KnifeDamageDisabled");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void Multi1v1_OnRoundTypesAdded()
{
	if(gh_Ranked.BoolValue)
	{
		Multi1v1_AddRoundType("NoScope", "noscope", NoscopeHandler, true, true, "NoscopeOnly", true);
	}
	else
	{
		Multi1v1_AddRoundType("NoScope", "noscope", NoscopeHandler, true, false, "", true);
	}
}

public Action Event_RoundStart(Event ev, char[] name, bool dbc)
{
	if(gh_Weapon.IntValue == 3)
		Rand = GetRandomInt(1, 2);
}

public void NoscopeHandler(int client)
{
	int iWeapon = -1;
	if(gh_Weapon.IntValue == 1)	
	{
		iWeapon = GivePlayerItem(client, "weapon_awp");
	}
	else if(gh_Weapon.IntValue == 2)
	{
		iWeapon = GivePlayerItem(client, "weapon_ssg08");
	}
	else if(gh_Weapon.IntValue == 3)
	{
		if(Rand == 1)
		{
			iWeapon = GivePlayerItem(client, "weapon_awp");
		}
		else
		{
			iWeapon = GivePlayerItem(client, "weapon_ssg08");
		}
	}
	else
	{
		SetFailState("Wrong integer value in \"sm_1v1_ns_weapon\"");
	}
	if(iWeapon != -1)
	{
		EquipPlayerWeapon(client, iWeapon);
	}
	Multi1v1_GivePlayerKnife(client);
	
	g_Noscope[client] = true;

	if(gh_MessageLoc.BoolValue)
	{
		PrintHintText(client, "%t", "ThisIsNoscopeHintText");
	}
	else
	{
		Multi1v1_Message(client, "%t", "ThisIsNoscopeChat");
	}
}

// Reset stuff
public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			g_Noscope[client] = false;
		}
	}
}
