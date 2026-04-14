# For Da Emprah!

`ForDaEmprah` is a Warhammer 40,000: Darktide mod that adds extra communication options as keybinds and wheel entries.

## Features overview

### Expanded communication wheel
- Extends the communication wheel to **12 slots**.
- Lets you assign each slot freely, so you can build your own layout instead of being locked to the vanilla arrangement.
- Keeps the most common stock calls in familiar positions by default, while opening the rest of the wheel for additional commands.

### Extra callouts and item call-ins
The mod adds support for a wider set of communication options, including:

- **Combat and team calls**
  - For Da Emprah!
  - Yes
  - No
  - Sorry
  - Following
  - Need Ammo
  - Need Healing
  - Look There
  - Go There
  - Enemy
  - Thanks
  - Mine

- **Items and objectives**
  - Ammo
  - Ammo Crate
  - Grenade
  - Med Stimm
  - Medipack
  - Medipack Down
  - Medicae Station
  - Cryonic Rod
  - Power Cell
  - Vacuum Capsule
  - Scripture
  - Grimoire
  - Relic
  - Plasteel
  - Diamantine

### Direct keybind support
- Every supported command can be bound to its own key.
- Keybinds trigger the same communication behavior as the wheel entry, including voice playback, smart tags, and chat output where applicable.
- Input is ignored while menus or UI input are active, so it does not fire accidentally while navigating interfaces.

### Optional chat messages for extra commands
- Extra non-vanilla callouts can also post to **mission chat**.
- Chat output can be toggled **per command**, so you can decide exactly which extra wheel actions should also write a message.
- Where possible, the mod uses existing Darktide localization keys so the chat line resolves correctly for other players as well.

### Smart tagging support
- Location-based commands such as **Look There**, **Go There**, and **Enemy** still trigger the appropriate smart-tag behavior.
- Item and objective-related options use matching on-demand voice events for more natural communication.

### Custom apology behavior
- The **Sorry** command uses a custom execution path.
- Instead of a generic line, it attempts to play a fitting apology response based on the player class and available teammate dialogue rules.

### Localization
- Includes built-in localization support for multiple game languages.
- `mod_title` intentionally keeps the Warhammer 40k Ogryn-style flavor, while the rest of the mod uses normal language for labels and descriptions.

## Installation

1. Copy the `ForDaEmprah` folder into your Darktide Mod Framework `mods` directory.
2. Make sure the mod is enabled in your Darktide mod list.
3. Configure wheel slots and keybinds in the mod settings menu.

## Configuration

After enabling the mod, you can configure:
- the command assigned to each of the 12 wheel slots
- which extra commands should also post to mission chat
- individual keybinds for each available command

## Important Disclaimer

This mod is **not intended for public games**. If a feature affects other players or behaves like a serverside mod, using it in public matchmaking may violate Fatshark's modding rules and can put your account at risk.

Use it in private environments only, and only if you understand the risk.

The policy guidance this repository follows is:

> For those seeking serverside mods such as True Shirtless and Vacuum Capsule, such mods are intentionally restricted due to them being against Fatshark Modding Policy. The primary reason for this is that they affect unmodded players as such mods force an unintended experience unto them.
>
> I know it's not fun, but honestly we have a super sweet deal going on in terms of modding support. The fact that we can just enable any mod without them having to go through an approval process is awesome, and it's best not to cause enough trouble to force Fatshark to stop this.
>
> The more these serverside mods spread, the more it'll become a potential problem, so us modders want to avoid doing that as much as possible, sorry x,x
>
> Q: Will I be banned for using them?
> A: It's possible. If someone reports you or you mess with the servers, you run the risk of having action taken against you, so it's best to avoid them. Mods that interfere with servers are especially high risk, due to the possibility of crashing servers (which you will immediately get banned for in such cases).
>
> Q: May I still use them anyway?
> A: I suppose, but I doubt any of the modders here will share such mods due to the reasons above. We don't want to encourage any of the behavior, so asking about it will be frowned upon. We want to keep the modding community a healthy environment <3
>
> Q: Are clientside mods still okay?
> A: Yep! As long as you don't affect other players, cheat in any way, or crash the servers you'll be fine. Pretty much all the mods on nexus are fine, including the regular shirtless mod for private use.

## Notes

- Vanilla wheel commands are preserved and can still be placed on the wheel or bound directly.
- The wheel automatically adapts its spacing to the number of active entries.
- Some commands are focused on voice and chat communication, while others also create smart tags depending on the command type.
