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

bool g_bNoscope[MAXPLAYERS+1] = {false, ...};

ConVar g_hMessageLoc, g_hRanked, g_hKnifeDamage, g_hWeapon;

int g_iRand = 1;

public Plugin myinfo =
{
    name = "CS:GO Multi1v1: Noscope round addon",
    author = "Cruze",
    description = "Adds an noscope round-type",
    version = "1.2.6",
    url = "http://steamcommunity.com/profiles/76561198132924835"
};

public void OnPluginStart()
{
	g_hMessageLoc 	= CreateConVar("sm_1v1_ns_msgloc", 		"1", "Message location of \"This is noscope round\" message. 0 = Chat. 1 = Hintbox");
	g_hRanked 		= CreateConVar("sm_1v1_ns_ranked", 		"1", "Ranked? 0 for no.");
	g_hKnifeDamage  = CreateConVar("sm_1v1_ns_knifedmg", 	"0", "1 - Enable or 0 - Disable knife damage in noscope round.");
	g_hWeapon		= CreateConVar("sm_1v1_ns_weapon", 		"3", "1 - AWP, 2 - SSG 08, 3 - Both");
	
	AutoExecConfig(true, "plugin.1v1ns");

	HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("round_end", Event_RoundEnd);

	LoadTranslations("multi1v1-ns.phrases");
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientPutInServer(client);
		}
	}
}

public void OnMapStart()
{
	for(int client = 0; client < MaxClients; client++)
	{
		g_bNoscope[client] = false;
	}
	g_iRand = 1;
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PreThink, PreThink);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
	g_bNoscope[client] = false;
}

public Action PreThink(int client)
{
	if(IsPlayerAlive(client) && g_bNoscope[client])
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
	if (!IsValidEntity(weapon) || g_hKnifeDamage.BoolValue)
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
	if(!g_bNoscope[attacker] || !g_bNoscope[victim])
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
	if(g_hRanked.BoolValue)
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
	if(g_hWeapon.IntValue == 3)
		g_iRand = GetRandomInt(1, 2);
}

public void NoscopeHandler(int client)
{
	Multi1v1_GivePlayerKnife(client);
	int iWeapon = -1;
	if(g_hWeapon.IntValue == 1)	
	{
		iWeapon = GivePlayerItem(client, "weapon_awp");
	}
	else if(g_hWeapon.IntValue == 2)
	{
		iWeapon = GivePlayerItem(client, "weapon_ssg08");
	}
	else if(g_hWeapon.IntValue == 3)
	{
		if(g_iRand == 1)
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
		SetFailState("[Multi1v1-NS] Wrong integer value in \"sm_1v1_ns_weapon\"");
	}
	if(iWeapon != -1)
	{
		EquipPlayerWeapon(client, iWeapon);
	}
	
	g_bNoscope[client] = true;

	if(g_hMessageLoc.BoolValue)
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
	for(int client = 0; client < MaxClients; client++)
	{
		g_bNoscope[client] = false;
	}
	g_iRand = 1;
}

public Action Event_RoundEnd(Event ev, char[] name, bool dbc)
{
	for(int client = 0; client < MaxClients; client++)
	{
		g_bNoscope[client] = false;
	}
	g_iRand = 1;
}
