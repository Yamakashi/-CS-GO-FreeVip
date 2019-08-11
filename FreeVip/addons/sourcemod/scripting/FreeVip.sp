/******* [ ChangeLog ] *******

	1.0 - Pierwsze wydanie pluginu.
	1.1 - Naprawienie kilku błędów.
	1.2 - Poprawa kodu.

******** [ ChangeLog ] *******/

/* [ Includes ] */
#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <multicolors>

/* [ Compiler Options ] */
#pragma newdecls required
#pragma semicolon 1

/* [ Defines ] */
#define PluginTag "{darkred}[ {lightred}★{darkred} FreeVip {lightred}★ {darkred}]{default}"

/* [ ConVars ] */
ConVar g_cvFreeVipTime;
ConVar g_cvFreeVipForAll;
ConVar g_cvFreeVipTimeStart;
ConVar g_cvFreeVipTimeEnd;

/* [ Handles ] */
Handle g_hCookie;
Handle g_hTimer;

/* [ Integers ] */
int g_iFreeVipTime[MAXPLAYERS + 1];

/* [ Booleans ] */
bool g_bFreeVip[MAXPLAYERS + 1];

/* [ Plugin Author and Information ] */
public Plugin myinfo =
{
	name = "[CS:GO] FreeVip",
	author = "Yamakashi",
	description = "Plugin pozwala na odebranie FreeVipa na określony czas.",
	version = "1.2",
	url = "https://steamcommunity.com/id/yamakashisteam"
};

/* [ Plugin Startup ] */
public void OnPluginStart()
{
	/* [ Commands ] */
	RegConsoleCmd("sm_freevip", FreeVip_CMD, "[FreeVip] Odebranie FreeVipa.");
	RegConsoleCmd("sm_fv", FreeVip_CMD, "[FreeVip] Odebranie FreeVipa.");

	/* [ ConVars ] */
	g_cvFreeVipTime = CreateConVar("sm_freevip_time", "60", "[FreeVip] Czas na jaki ma być odebrany FreeVip");
	g_cvFreeVipForAll = CreateConVar("sm_freevip_enable", "1", "[FreeVip] Czy w godzinach X-Y ma być FreeVip dla wszystkich?");
	g_cvFreeVipTimeStart = CreateConVar("sm_freevip_time_start", "22", "[FreeVip] Od której godziny ma zaczynać się FreeVip?");
	g_cvFreeVipTimeEnd = CreateConVar("sm_freevip_time_end", "9", "[FreeVip] Do której godziny ma być FreeVip?");
	
	/* [ Cookies ] */
	g_hCookie = RegClientCookie("yamakashi_freevip", "", CookieAccess_Private);
	
	/* [ Hooks ] */
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	/* [ Timers ] */
	CreateTimer(60.0, PluginAuthor, _, TIMER_FLAG_NO_MAPCHANGE);
	
	/* [ Check Player ] */
	for(int i = 1; i <= MaxClients; i++)
		if(IsValidClient(i))
			OnClientCookiesCached(i);	
}

/* [ Standart Actions ] */
public void OnMapStart()
{
	g_hTimer = CreateTimer(60.0, RemoveTime, _, TIMER_REPEAT);
	CreateTimer(30.0, AddFreeVipFlags, _, TIMER_FLAG_NO_MAPCHANGE);
	AutoExecConfig(true, "Yamakashi_FreeVip", "yPlugins");
}

public void OnMapEnd()
{
	KillTimer(g_hTimer, false);
	g_hTimer = INVALID_HANDLE;
}

public void OnClientPostAdminCheck(int client)
{
	if(g_iFreeVipTime[client] > 0)
	{
		AddUserFlags(client, Admin_Reservation, Admin_Custom1);
		g_bFreeVip[client] = true;
	}
	else
		g_bFreeVip[client] = false;
}	

public void OnClientDisconnect(int client)
{
	if(IsClientInGame(client))
		if(AreClientCookiesCached(client))
		{
			char sTimeLeft[4];
			Format(sTimeLeft, sizeof(sTimeLeft), "%d", g_iFreeVipTime[client]);
			SetClientCookie(client, g_hCookie, sTimeLeft);
		}
	g_bFreeVip[client] = false;
	g_iFreeVipTime[client] = 0;
}

public void OnClientCookiesCached(int client)
{
	char sTimeLeft[4];
	GetClientCookie(client, g_hCookie, sTimeLeft, sizeof(sTimeLeft));
	g_iFreeVipTime[client] = StringToInt(sTimeLeft);
}

/* [ Commands ] */
public Action FreeVip_CMD(int client, int args)
{	
	if(g_iFreeVipTime[client] == -1)
	{
		CPrintToChat(client, "%s {lightred}Nie możesz użyć tej komendy, ponieważ wykorzystałeś już {darkred}FreeVipa{lightred}.", PluginTag);
		return Plugin_Handled;
	}
	
	if(0 < g_iFreeVipTime[client])
	{
		CPrintToChat(client, "%s {lightred}Już posiadasz {darkred}FreeVipa{lightred}. Pozostały czas FreeVipa to {darkred}%d{lightred} minut.", PluginTag, g_iFreeVipTime[client]);
		return Plugin_Handled;
	}
	
	g_iFreeVipTime[client] = g_cvFreeVipTime.IntValue;
	AddUserFlags(client, Admin_Reservation, Admin_Custom1);
	g_bFreeVip[client] = true;
	
	CPrintToChatAll("{orange}╔═══════════ FreeVip ═══════════╗");
	CPrintToChatAll("{orange}» {lightred}%N{lime} właśnie aktywował {lightred}FreeVipa{lime}.", client);
	CPrintToChatAll("{orange}╚═══════════ FreeVip ═══════════╝");

	CPrintToChat(client, "%s {green}Gratulacje! {lime}Właśnie aktywowałeś {lightred}FreeVipa{lime}.", PluginTag);
	return Plugin_Continue;
}

/* [ Timers ] */
public Action RemoveTime(Handle timer)
{
	if(timer == g_hTimer)
		for(int i = 1; i <= MaxClients; i++)
			if(IsValidClient(i))
				if(0 < g_iFreeVipTime[i])
				{
					g_iFreeVipTime[i]--;
					if(g_iFreeVipTime[i] == 0)
					{	
						g_iFreeVipTime[i] = -1;
						g_bFreeVip[i] = false;
						RemoveUserFlags(i, Admin_Reservation, Admin_Custom1);
						CPrintToChatAll("%s {lime}Graczowi {lightred}%N{lime} właśnie skończył się {lightred}FreeVip{lime}.", PluginTag, i);
						CPrintToChatAll("%s {lime}Aby odebrać {lightred}FreeVipa{lime} należy użyć komendy {lightred}!freevip{lime} lub {lightred}!fv{lime}.", PluginTag);
					}
				}
}

public Action PluginAuthor(Handle timer)
{
	CPrintToChatAll("%s {lightred}Plugin{lime} został napisany przez {lightred}Yamakashiego{lime}.", PluginTag);
	CreateTimer(60.0, PluginAuthor, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action AddFreeVipFlags(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++)
		if(IsValidClient(i))
			if(g_bFreeVip[i])
				if(g_iFreeVipTime[i] > 0)
					AddUserFlags(i, Admin_Reservation, Admin_Custom1);

	CreateTimer(30.0, AddFreeVipFlags, _, TIMER_FLAG_NO_MAPCHANGE);
}

/* [ Events ] */
public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidClient(client)) return Plugin_Continue;
		
	int start_hour = g_cvFreeVipTimeStart.IntValue;
	int end_hour = g_cvFreeVipTimeEnd.IntValue;
	
	if(g_cvFreeVipForAll.BoolValue)
	{
		if(start_hour || end_hour)
		{
			char sHour[8];
			FormatTime(sHour, sizeof(sHour), "%H", GetTime());
			int hour = StringToInt(sHour);
			if(start_hour > end_hour)
			{
				if(hour > start_hour || hour < end_hour)
				{
					if(!g_bFreeVip[client])
						AddUserFlags(client, Admin_Reservation, Admin_Custom1);
				}
				else if(hour < start_hour && hour > end_hour)
					if(!g_bFreeVip[client])
						RemoveUserFlags(client, Admin_Reservation, Admin_Custom1);
			}					
		}
	}
		
	return Plugin_Continue;
}

/* [ Helpers ] */
stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	if(IsFakeClient(client)) return false;
	return IsClientInGame(client);
}