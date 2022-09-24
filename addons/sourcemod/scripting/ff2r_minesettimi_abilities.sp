/*

	"rage_spellbook"
	{
		"slot"			"-1"
		"spellid"		"5"
		"useimmediately"	"true"
	}

	0 : fireball
	1: bat swarm
	2: healing aura
	3: pumpkin bombs
	4: blast jump
	5: invis
	6: teleport
	7: lightning
	8: minify
	9: meteor shower
	10: monoculus
	11: skeleton

*/

#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <sourcemod>
#include <cfgmap>
#include <ff2r>
#undef REQUIRE_PLUGIN

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "Minesettimi's FF2 Subplugin",
	author = "minesettimi",
	description = "",
	version = "1.0.0",
	url = ""
};

public void FF2R_OnAbility(int client, const char[] ability, AbilityData cfg)
{
	if (!StrContains(ability, "rage_spellbook", false))
	{
		Rage_Spellbook(client, cfg);
	}
}

void Rage_Spellbook(int client, ConfigData cfg)
{
	int spell = cfg.GetInt("spellid", 5);
	bool use = cfg.GetBool("useimmediately", true);

	int spellbook = FindSpellBook(client);
	if (spellbook != -1)
	{
		SetEntProp(spellbook, Prop_Send, "m_iSelectedSpellIndex", spell);

		if (use)
		{
			if (!TF2_IsPlayerInCondition(client, TFCond_Cloaked) || !TF2_IsPlayerInCondition(client, TFCond_CloakFlicker))
			{
				FakeClientCommand(client, "use tf_weapon_spellbook");
			}
		}
	}
}

int FindSpellBook(int client)
{
	int book = -1;
	while ((book = FindEntityByClassname(book, "tf_weapon_spellbook")) != -1)
	{
		if (IsValidEntity(book) && GetEntPropEnt(book, Prop_Send, "m_hOwnerEntity") == client)
		{
			if (!GetEntProp(book, Prop_Send, "m_bDisguiseWepaon"))
			{
				return book;
			}
		}
	}

	return -1;
}