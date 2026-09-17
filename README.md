![KP Liberation](https://www.killahpotatoes.de/images/arma/liberation.png)

# KP Liberation for Arma 3

[![CI](https://github.com/KillahPotatoes/KP-Liberation/workflows/CI/badge.svg)](https://github.com/KillahPotatoes/KP-Liberation/actions?query=workflow%3ACI)
[![license](https://img.shields.io/github/license/KillahPotatoes/KP-Liberation.svg)](https://github.com/KillahPotatoes/KP-Liberation/blob/master/LICENSE.md)
[![GitHub release](https://img.shields.io/github/release/KillahPotatoes/KP-Liberation.svg)](https://github.com/KillahPotatoes/KP-Liberation/releases)
[![GitHub Release Date](https://img.shields.io/github/release-date/KillahPotatoes/KP-Liberation.svg)](https://github.com/KillahPotatoes/KP-Liberation/releases)

[![Github All Releases](https://img.shields.io/github/downloads/KillahPotatoes/KP-Liberation/total.svg)](https://github.com/KillahPotatoes/KP-Liberation)
[![GitHub stars](https://img.shields.io/github/stars/KillahPotatoes/KP-Liberation)](https://github.com/KillahPotatoes/KP-Liberation/stargazers)
[![GitHub issues](https://img.shields.io/github/issues-raw/KillahPotatoes/KP-Liberation.svg)](https://github.com/KillahPotatoes/KP-Liberation/issues)
[![GitHub closed issues](https://img.shields.io/github/issues-closed-raw/KillahPotatoes/KP-Liberation.svg)](https://github.com/KillahPotatoes/KP-Liberation/issues?q=is%3Aissue+is%3Aclosed)

[![GitHub contributors](https://img.shields.io/github/contributors/KillahPotatoes/KP-Liberation)](https://github.com/KillahPotatoes/KP-Liberation/graphs/contributors)
[![GitHub forks](https://img.shields.io/github/forks/KillahPotatoes/KP-Liberation)](https://github.com/KillahPotatoes/KP-Liberation/network)
[![GitHub pull requests](https://img.shields.io/github/issues-pr-raw/KillahPotatoes/KP-Liberation.svg)](https://github.com/KillahPotatoes/KP-Liberation/pulls)
[![GitHub closed pull requests](https://img.shields.io/github/issues-pr-closed-raw/KillahPotatoes/KP-Liberation.svg)](https://github.com/KillahPotatoes/KP-Liberation/pulls?q=is%3Apr+is%3Aclosed)

[![KP Discord](https://img.shields.io/discord/154937272368758784?label=Discord)](https://discord.gg/Qk35Sw8)

[BI Forum Thread](https://forums.bistudio.com/topic/202711-mpcti-coop-liberation-continued/)

[Steam Workshop](http://steamcommunity.com/id/wyqer/myworkshopfiles/?appid=107410)

This mission is only a continued project based on the original, but most likely abandoned, mission from [GreuhZbug](https://github.com/GreuhZbug).

[Original Liberation mission v0.924](https://github.com/GreuhZbug/greuh_liberation.Altis)

If you like the work and think it's worth a small donation, feel free to use the following link:

[Donate via paypal.me](https://www.paypal.me/wyqer)

## Overview
The area has fallen to the enemy, and it is up to you to take it back. Embark on a persistent campaign with your teammates to liberate all the major cities of the area that will most likely span several weeks of real time.
* Experience a massive “Capture the Island” campaign involving a large range of different settlements across the entire area.
* Cooperate with up to 34 players, including a Commanding role, two fire-team squads, a medevac and a logistical support squad as well as AI recruits to fill the gaps.
* Purchase both infantry and both ground and air vehicles using three different types of physical resources; supplies, ammunition and fuel.
* Build the FOB of your dreams with an in-game "what you see is what you get" system.
* Play within an immersive engine that not only punishes you for civilian casualty but diversely reacts in turn.
* Combat aggressive and cunning hostile forces who react and adapt to your actions.
* Monitor and work alongside, or against, independent guerrilla forces.
* Learn that every window is a threat thanks to the custom urban combat AI.
* Accomplish meaningful secondary objectives that will benefit your progression.
* Never lose your progress with the built-in server-side save system.

## Testing the AI helicopter taxi (v0.97.0 development)

Build this checkout with `build.bat` on Windows, or run `npm install` and `npx gulp` in `_tools`. Load the rebuilt mission with ACE3 and its dependencies. In-game verification of issue #3 is still in progress.

With at least one FOB established, carry a vanilla `ItemRadio` either equipped or in inventory. While on foot and outside build mode, choose **Call Taxi** in the action menu. Select the departure FOB, choose Light or Armed, then click a destination **300–9,000 m from that FOB** to enable **Call**. The selected FOB needs fuel crates in its storage area; a call costs 2 fuel per kilometre, rounded up, with a minimum of 5.

The taxi starts airborne about 2.5 km away and flies to a clear landing site within 150 m of the departure FOB. Board there using the normal get-in action. It waits for the first passenger, then for 15 seconds without a boarding change before departing for the selected insertion LZ. Landing and boarding each have a five-minute timeout.

For the rope test, choose **Armed / Ghost Hawk**. It receives FRIES and four 36 m ACE ropes at spawn. At the LZ, the pilot must settle into a low, slow hover before ropes deploy and passengers descend automatically, one at a time. Passenger groups are preserved. The default Light / Hummingbird lacks ACE rope support and uses a landing instead. ACE's [fast-roping framework](https://ace3.acemod.org/wiki/framework/fastroping-framework) describes aircraft compatibility.

After insertion, the same helicopter waits near the FOB for up to five minutes. **Extract at LZ** recalls your squad's nearest active taxi to a new field landing site; after boarding it returns to the departure FOB. **Return to FOB**, a timeout, or damage above 50% ends the insertion. The pilot must return and land rather than attack enemies or retry the insertion. Get out normally at the FOB. Cleanup only deletes an empty taxi away from players; if it cannot return or passengers remain aboard, it stays in the world.

Regression checks (require Arma; static checks do not verify AI flight):

- With ACE and a FOB available, verify Call Taxi appears with a radio equipped, remains available with it in inventory, and disappears after removing it entirely. Check both recall actions with an active taxi too.
- Choose an LZ about 1 km from the selected FOB: Call enables and the request uses that FOB, including when it is not the first entry in the list.
- Watch the taxi approach and land; it must not spawn beside the FOB or depart for insertion empty.
- Board two passengers several seconds apart, including an FFV seat where available: departure must wait 15 seconds after the last boarding change.
- Leave the taxi empty: it should depart after the boarding timeout and release its pool slot. Interrupt a pickup or destroy the taxi and verify passengers are not deleted and a destroyed airframe's slot enters cooldown.
- In the Ghost Hawk, check FRIES and rope cargo before takeoff. Test insertion with two player clients and an AI passenger: ropes deploy once, everyone reaches the ground, and departure waits for all ropes to clear plus the grace period.
- Damage the Ghost Hawk above 50% while hovering with passengers still aboard. It must abort to the FOB without strafing, retrying insertion, despawning, or ejecting passengers. Leave a passenger aboard for more than five minutes after landing: the aircraft must remain and still occupy its pool slot until they disembark.
- Test Extract at LZ, Return to FOB, and two active taxis from different squads. A recall must affect only the requesting squad's taxi, and extraction must finish with landing and unloading at the departure FOB.
- After a damage abort starts, repair the helicopter and request extraction: it must still finish returning to the FOB. With a healthy taxi on standby, let the original caller respawn and verify another member of the requesting squad can still recall it.

## Needed Mods
These mods are needed if you want to use the prepackaged missionfiles from the release tab or Steam Workshop.
You can play every map without any mods (only the maps themself) if you set the preset to custom in the file `kp_liberation_config`.
* Al Rayak (pja310)
    * [CUP Terrains - Core](http://steamcommunity.com/sharedfiles/filedetails/?id=583496184)
    * [G.O.S Al Rayak](http://steamcommunity.com/sharedfiles/filedetails/?id=648172507)
    * [RHS: Armed Forces of the Russian Federation](http://steamcommunity.com/sharedfiles/filedetails/?id=843425103)
    * [RHS: United States Forces](http://steamcommunity.com/sharedfiles/filedetails/?id=843577117)
* Altis
    * None
* Chernarus
    * [CUP Terrains - Core](http://steamcommunity.com/sharedfiles/filedetails/?id=583496184)
    * [CUP Terrains - Maps](http://steamcommunity.com/sharedfiles/filedetails/?id=583544987)
    * [RHS: Armed Forces of the Russian Federation](http://steamcommunity.com/sharedfiles/filedetails/?id=843425103)
    * [RHS: United States Forces](http://steamcommunity.com/sharedfiles/filedetails/?id=843577117)
* Chernarus Winter
    * [CUP Terrains - Core](http://steamcommunity.com/sharedfiles/filedetails/?id=583496184)
    * [CUP Terrains - Maps](http://steamcommunity.com/sharedfiles/filedetails/?id=583544987)
    * [RHS: Armed Forces of the Russian Federation](http://steamcommunity.com/sharedfiles/filedetails/?id=843425103)
    * [RHS: United States Forces](http://steamcommunity.com/sharedfiles/filedetails/?id=843577117)
* Livonia
    * Contact DLC
* Lythium
    * [Jbad](http://steamcommunity.com/sharedfiles/filedetails/?id=520618345)
    * [Lythium](http://steamcommunity.com/sharedfiles/filedetails/?id=909547724)
    * [Project OPFOR](http://steamcommunity.com/sharedfiles/filedetails/?id=735566597)
    * [RHS: Armed Forces of the Russian Federation](http://steamcommunity.com/sharedfiles/filedetails/?id=843425103)
    * [RHS: United States Forces](http://steamcommunity.com/sharedfiles/filedetails/?id=843577117)
* Malden
    * None
* Panthera
    * [CUP Terrains - Core](http://steamcommunity.com/sharedfiles/filedetails/?id=583496184)
    * [CUP Units](https://steamcommunity.com/sharedfiles/filedetails/?id=497661914)
    * [CUP Vehicles](https://steamcommunity.com/sharedfiles/filedetails/?id=541888371)
    * [CUP Weapons](https://steamcommunity.com/sharedfiles/filedetails/?id=497660133)
    * [Island Panthera](https://steamcommunity.com/sharedfiles/filedetails/?id=708278910)
* Sahrani
    * [CUP Terrains - Core](http://steamcommunity.com/sharedfiles/filedetails/?id=583496184)
    * [CUP Terrains - Maps](http://steamcommunity.com/sharedfiles/filedetails/?id=583544987)
    * [RHS: Armed Forces of the Russian Federation](http://steamcommunity.com/sharedfiles/filedetails/?id=843425103)
    * [RHS: United States Forces](http://steamcommunity.com/sharedfiles/filedetails/?id=843577117)
* Song Bin Tanh
    * [The Unsung Vietnam War Mod](https://steamcommunity.com/sharedfiles/filedetails/?id=943001311)
* Takistan
    * [CUP Terrains - Core](http://steamcommunity.com/sharedfiles/filedetails/?id=583496184)
    * [CUP Terrains - Maps](http://steamcommunity.com/sharedfiles/filedetails/?id=583544987)
    * [Project OPFOR](http://steamcommunity.com/sharedfiles/filedetails/?id=735566597)
    * [RHS: Armed Forces of the Russian Federation](http://steamcommunity.com/sharedfiles/filedetails/?id=843425103)
    * [RHS: United States Forces](http://steamcommunity.com/sharedfiles/filedetails/?id=843577117)
* Tanoa
    * Apex DLC
* Taunus (very resource-intensive map)
    * [BWMod](http://steamcommunity.com/sharedfiles/filedetails/?id=1200127537)
    * [CBA A3](http://steamcommunity.com/sharedfiles/filedetails/?id=450814997)
    * [CUP Terrains - Core](http://steamcommunity.com/sharedfiles/filedetails/?id=583496184)
    * [CUP Terrains - Maps](http://steamcommunity.com/sharedfiles/filedetails/?id=583544987)
    * [RHS: Armed Forces of the Russian Federation](http://steamcommunity.com/sharedfiles/filedetails/?id=843425103)
    * [RHS: United States Forces](http://steamcommunity.com/sharedfiles/filedetails/?id=843577117)
    * [X-Cam-Taunus (Version 1.1)](http://steamcommunity.com/sharedfiles/filedetails/?id=836147398)
* Weferlingen
    * Global Mobilization CDLC
* Weferlingen Winter
    * Global Mobilization CDLC
* Yulakia
    * [Yulakia Map](https://steamcommunity.com/sharedfiles/filedetails/?id=2950257727)
    * [CUP Terrains - Core](http://steamcommunity.com/sharedfiles/filedetails/?id=583496184) 

## Recommended Mods
These mods are recommended by us, as they are likely to increase your gaming experience:
* [ACE](https://steamcommunity.com/sharedfiles/filedetails/?id=463939057)
* [ACE Compat - RHS Armed Forces of the Russian Federation](https://steamcommunity.com/workshop/filedetails/?id=773131200)
* [ACE Compat - RHS United States Armed Forces](https://steamcommunity.com/workshop/filedetails/?id=773125288)
* [ACE3 - BWMOD Compatibility](https://steamcommunity.com/sharedfiles/filedetails/?id=1200145989)
* [ACRE 2](https://steamcommunity.com/sharedfiles/filedetails/?id=751965892)
* [Advanced Urban Rappeling](https://steamcommunity.com/sharedfiles/filedetails/?id=730310357)
* [CBA_A3](https://steamcommunity.com/sharedfiles/filedetails/?id=450814997)
* [Discord Rich Presence](https://steamcommunity.com/sharedfiles/filedetails/?id=1493485159)
* [DUI - Squad Radar](https://steamcommunity.com/sharedfiles/filedetails/?id=1638341685)
* [Enhanced Movement](https://steamcommunity.com/sharedfiles/filedetails/?id=333310405)
* [Immerse](https://steamcommunity.com/sharedfiles/filedetails/?id=825172265)
* [JSRS SOUNDMOD](https://steamcommunity.com/sharedfiles/filedetails/?id=861133494)
* [JSRS SOUNDMOD - RHS AFRF Mod Pack Sound Support](https://steamcommunity.com/sharedfiles/filedetails/?id=945476727)
* [JSRS SOUNDMOD - RHS USAF Mod Pack Sound Support](https://steamcommunity.com/sharedfiles/filedetails/?id=1180533757)
* [KP Ranks](https://steamcommunity.com/sharedfiles/filedetails/?id=741621641)
* [Suppress](https://steamcommunity.com/sharedfiles/filedetails/?id=825174634)

Also you should think about using these mods as serverside mods:
* [Advanced Rappeling](http://steamcommunity.com/sharedfiles/filedetails/?id=713709341)
* [Advanced Sling Loading](http://steamcommunity.com/sharedfiles/filedetails/?id=615007497)
* [Advanced Towing](http://steamcommunity.com/sharedfiles/filedetails/?id=639837898)

## Recommended Difficulty Settings
I recommend using the following difficulty settings for this mission (User profile of your server):
```
difficulty="Custom";
class DifficultyPresets
{
    class CustomDifficulty
    {
        class Options
        {
            groupIndicators=0;
            friendlyTags=0;
            enemyTags=0;
            detectedMines=0;
            commands=0;
            waypoints=0;
            weaponInfo=1;
            stanceIndicator=1;
            reducedDamage=0;
            staminaBar=0;
            weaponCrosshair=0;
            visionAid=0;
            thirdPersonView=0;
            cameraShake=1;
            scoreTable=0;
            deathMessages=0;
            vonID=1;
            mapContent=0;
            autoReport=0;
            multipleSaves=0;
            squadRadar=0;
            tacticalPing=0;
        };
        aiLevelPreset=3;
    };
    class CustomAILevel
    {
        skillAI=1.0;
        precisionAI=0.15;
    };
};
```

In the server config file:
```
forcedDifficulty = "custom";

class Missions
{
    class kp_liberation
    {
        template = "kp_liberation.Altis";
        difficulty = "custom";
    };
};
```
