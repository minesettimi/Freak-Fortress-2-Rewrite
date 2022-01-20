/*
	void Command_PluginStart()
*/

void Command_PluginStart()
{
	AddCommandListener(Command_Voicemenu, "voicemenu");
	AddCommandListener(Command_KermitSewerSlide, "explode");
	AddCommandListener(Command_KermitSewerSlide, "kill");
	AddCommandListener(Command_Spectate, "spectate");
	AddCommandListener(Command_JoinTeam, "jointeam");	
	AddCommandListener(Command_AutoTeam, "autoteam");
	AddCommandListener(Command_JoinClass, "joinclass");
	AddCommandListener(Command_EurekaTeleport, "eureka_teleport");
}

public Action Command_Voicemenu(int client, const char[] command, int args)
{
	if(client && args == 2 && Client(client).IsBoss && IsPlayerAlive(client) && (!Enabled || RoundActive))
	{
		char arg[4];
		GetCmdArg(1, arg, sizeof(arg));
		if(arg[0] == '0')
		{
			GetCmdArg(2, arg, sizeof(arg));
			if(arg[0] == '0')
			{
				float rageDamage = Client(client).RageDamage;
				if(rageDamage < 99999.0)
				{
					int rageType = Client(client).RageMode;
					if(rageType != 2)
					{
						float rageMin, charge;
						if(rageDamage <= 1.0 || (charge=Client(client).GetCharge(0)) >= (rageMin=Client(client).RageMin))
						{
							Bosses_UseSlot(client, 0, 0);
							
							if(rageDamage > 1.0)
							{
								if(rageType == 1)
								{
									Client(client).SetCharge(0, charge - rageMin);
								}
								else if(rageType == 0)
								{
									Client(client).SetCharge(0, 0.0);
								}
							}
							return Plugin_Handled;
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Command_KermitSewerSlide(int client, const char[] command, int args)
{
	if(Enabled)
	{
		if((Client(client).IsBoss || Client(client).Minion) && !CvarBossSewer.BoolValue)
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_Spectate(int client, const char[] command, int args)
{
	if(!Client(client).IsBoss && !Client(client).Minion && (!Enabled || !GameRules_GetProp("m_bInWaitingForPlayers", 1)))
		return Plugin_Continue;
	
	int team = TFTeam_Spectator;
	return SwapTeam(client, team);
}

public Action Command_AutoTeam(int client, const char[] command, int args)
{
	if(!Client(client).IsBoss && !Client(client).Minion && (!Enabled || !GameRules_GetProp("m_bInWaitingForPlayers", 1)))
		return Plugin_Continue;
	
	int reds, blus;
	for(int i=1; i<=MaxClients; i++)
	{
		if(client != i && IsClientInGame(i))
		{
			int team = GetClientTeam(i);
			if(team == 3)
			{
				blus++;
			}
			else if(team == 2)
			{
				reds++;
			}
		}
	}
	
	int team;
	if(reds > blus)
	{
		team = TFTeam_Blue;
	}
	else if(reds < blus)
	{
		team = TFTeam_Red;
	}
	else if(GetClientTeam(client) == TFTeam_Red)
	{
		team = TFTeam_Blue;
	}
	else
	{
		team = TFTeam_Red;
	}
	
	return SwapTeam(client, team);
}

public Action Command_JoinTeam(int client, const char[] command, int args)
{
	if(!Client(client).IsBoss && !Client(client).Minion && (!Enabled || !GameRules_GetProp("m_bInWaitingForPlayers", 1)))
		return Plugin_Continue;
	
	char buffer[10];
	GetCmdArg(1, buffer, sizeof(buffer));
	
	int team = TFTeam_Unassigned;
	if(StrEqual(buffer, "red", false))
	{
		team = TFTeam_Red;
	}
	else if(StrEqual(buffer, "blue", false))
	{
		team = TFTeam_Blue;
	}
	else if(StrEqual(buffer, "auto", false))
	{
		return Command_AutoTeam(client, command, args);
	}
	else if(StrEqual(buffer, "spectate", false))
	{
		team = TFTeam_Spectator;
	}
	else
	{
		team = GetClientTeam(client);
	}
	
	return SwapTeam(client, team);
}

static Action SwapTeam(int client, int &newTeam)
{
	if(Enabled)
	{
		// No suicides
		if(!CvarBossSewer.BoolValue && IsPlayerAlive(client) && (Client(client).IsBoss || Client(client).Minion))
			return Plugin_Handled;
		
		// Prevent going to spectate with cvar disabled
		if(newTeam <= TFTeam_Spectator && !CvarAllowSpectators.BoolValue)
			return Plugin_Handled;
		
		int currentTeam = GetClientTeam(client);
		
		// Prevent going to same team unless spec team trying to actually spec
		if(currentTeam > TFTeam_Spectator && newTeam == currentTeam)
			return Plugin_Handled;
		
		if(Client(client).IsBoss || Client(client).Minion)
		{
			// Prevent swapping to a different team unless to spec
			if(newTeam > TFTeam_Spectator)
				return Plugin_Handled;
		}
		else if(!CvarBossVsBoss.BoolValue)
		{
			// Prevent swapping to a different team unless in spec or going to spec
			if(currentTeam > TFTeam_Spectator && newTeam > TFTeam_Spectator)
				return Plugin_Handled;
			
			// Manage which team we should assign
			if(newTeam > TFTeam_Spectator)
				newTeam = Bosses_GetBossTeam() == TFTeam_Red ? TFTeam_Blue : TFTeam_Red;
		}
	}
	else if(Client(client).IsBoss)
	{
		if(newTeam <= TFTeam_Spectator && !CvarAllowSpectators.BoolValue)
			return Plugin_Handled;
	}
	
	if(Client(client).IsBoss || Client(client).Minion)
	{
		// Remove properties
		Bosses_Remove(client);
		ForcePlayerSuicide(client);
		ChangeClientTeam(client, newTeam);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_JoinClass(int client, const char[] command, int args)
{
	if(Client(client).IsBoss || Client(client).Minion)
	{
		if(Enabled)
		{
			char class[16];
			GetCmdArg(1, class, sizeof(class));
			TFClassType num = TF2_GetClass(class);
			if(num != TFClass_Unknown)
				SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", num);
		
			return Plugin_Handled;
		}
		else
		{
			Bosses_Remove(client);
			ForcePlayerSuicide(client);
		}
	}
	return Plugin_Continue;
}

public Action Command_EurekaTeleport(int client, const char[] command, int args)
{
	if(Enabled && RoundActive && IsPlayerAlive(client))
	{
		char buffer[4];
		GetCmdArg(1, buffer, sizeof(buffer));
		if(StringToInt(buffer) != 1)
			return Plugin_Handled;
	}
	return Plugin_Continue;
}