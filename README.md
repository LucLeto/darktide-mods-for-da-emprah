# For Da Emprah!

`ForDaEmprah` is a Warhammer 40,000: Darktide mod that adds extra communication options as keybinds and wheel entries.

Current highlights:

- Restored a number of broken voice-line and wheel actions.
- Updated item-tag voice calls for things like medipacks, ammo crates, and med stimm.
- Added a `Sorry` option as both a keybind and a wheel entry.

## Installation

1. Copy the `ForDaEmprah` folder into your Darktide Mod Framework `mods` directory.
2. Make sure the mod is enabled in your Darktide mod list.
3. Configure wheel slots and keybinds in the mod settings menu.

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

- `Sorry` is implemented as a best-effort apology action because the current Darktide source does not expose a normal on-demand `sorry` wheel trigger.
- Some lines in Darktide are profile- and context-dependent, so behavior can vary by character voice.
