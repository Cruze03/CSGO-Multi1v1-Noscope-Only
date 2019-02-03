//Thanks to Bara's headshot only addon of multi1v1. Took help from that code.

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <multi1v1>

#pragma semicolon 1
#pragma newdecls required

#define m_flNextSecondaryAttack FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack") 

bool g_Noscope[MAXPLAYERS+1] = false;

ConVar gh_MessageLoc, gh_Ranked, gh_KnifeDamage;

public Plugin myinfo =
{
    name = "CS:GO Multi1v1: Noscope round addon",
    author = "Cruze",
    description = "Adds an noscope round-type",
    version = "1.1",
    url = "http://steamcommunity.com/profiles/76561198132924835"
};

public void OnPluginStart()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			SDKHook(client, SDKHook_PreThink, PreThink);
			SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
		}
	}
	gh_MessageLoc 	= CreateConVar("sm_1v1_ns_msgloc", "1", "Message location of \"This is noscope round\" message. 0 = Chat. 1 = Hintbox");
	gh_Ranked 		= CreateConVar("sm_1v1_ns_ranked", "1", "Ranked? 0 for no.");
	gh_KnifeDamage  = CreateConVar("sm_1v1_ns_knifedmg", "0", "1 - Enable or 0 - Disable knife damage in noscope round.");
	
	AutoExecConfig(true, "plugin.1v1ns");
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PreThink, PreThink);
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

public Action PreThink(int client)
{
	if(IsPlayerAlive(client))
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(!IsValidEdict(weapon) || !IsValidEntity(weapon))
			return Plugin_Continue;

		char item[64];
		GetEdictClassname(weapon, item, sizeof(item)); 
		if(g_Noscope[client] && StrEqual(item, "weapon_awp"))// || StrEqual(item, "weapon_scout") || StrEqual(item, "weapon_ssg08"))
		{
			SetEntDataFloat(weapon, m_flNextSecondaryAttack, GetGameTime() + 9999.9);
		}
	}
	return Plugin_Continue;
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (!IsValidEntity(weapon) || gh_KnifeDamage.BoolValue)
		return Plugin_Continue;
	if (attacker <= 0 || attacker > MaxClients)
		return Plugin_Continue;
	char WeaponName[20];
	GetEntityClassname(weapon, WeaponName, sizeof(WeaponName));
	if(StrContains(WeaponName, "knife", false) != -1 || StrContains(WeaponName, "bayonet", false) != -1 || StrContains(WeaponName, "fists", false) != -1 || StrContains(WeaponName, "axe", false) != -1 || StrContains(WeaponName, "hammer", false) != -1 || StrContains(WeaponName, "spanner", false) != -1 || StrContains(WeaponName, "melee", false) != -1)
	{
		if(g_Noscope[attacker] && g_Noscope[victim])
		{
			PrintCenterText(attacker, "Knife damage is disabled in this round.");
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void Multi1v1_OnRoundTypesAdded()
{
	if(gh_Ranked.BoolValue)
		Multi1v1_AddRoundType("NoScope", "noscope", NoscopeHandler, true, true, "NoscopeOnly", true);
	else
		Multi1v1_AddRoundType("NoScope", "noscope", NoscopeHandler, true, false, "", true);
}

public void NoscopeHandler(int client)
{
	int iAWP = GivePlayerItem(client, "weapon_awp");
	EquipPlayerWeapon(client, iAWP);
	Multi1v1_GivePlayerKnife(client);
	int offset = FindSendPropInfo("CCSPlayer", "m_bHasHelmet");
	SetEntData(client, offset, true);
	
	g_Noscope[client] = true;

	if(gh_MessageLoc.BoolValue)
		PrintHintText(client, "<font color='#8b0000'>This is a noscope only round!</font>");
	else
		Multi1v1_Message(client, " {darkred}This is a noscope only round!");
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
