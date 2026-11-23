# Sawmill Studio setup

This version is designed for a Roblox experience you own and edit in Roblox Studio. It uses server-validated chopping; it does not rely on Delta, loadstring, Cloudflare, license keys, or external services.

## 1. Add the server script
1. Open the experience in Roblox Studio.
2. In Explorer, open **ServerScriptService**.
3. Insert a **Script** named `SawmillServer`.
4. Copy the contents of `studio/ServerScriptService/SawmillServer.server.lua` into it.

## 2. Add the client panel
1. Open **StarterPlayer > StarterPlayerScripts**.
2. Insert a **LocalScript** named `SawmillClient`.
3. Copy the contents of `studio/StarterPlayer/StarterPlayerScripts/SawmillClient.client.lua` into it.

## 3. Tag your tree models
1. Select each complete tree **Model** in Workspace.
2. In Studio, open **View > Tag Editor**.
3. Add the tag `ChoppableTree`.
4. Optionally add model Attributes:
   - `TreeType` (String), e.g. Oak, Cherry, Walnut, Fir.
   - `Health` (Number), e.g. 5.
5. Make sure each tree is a Model or BasePart and its pivot is near its trunk.

## 4. Set up an axe
1. Put your axe **Tool** in StarterPack (or give it to players through your own inventory system).
2. Set the Tool Attribute `IsAxe` to Boolean `true`. A Tool with "axe" in its name is also recognized.
3. Make sure the Tool is equippable.

## 5. Test
Use **Play** in Studio with two test players if possible:
- Tree Finder highlights tagged trees.
- Equip Axe, stand within 14 studs, and start Auto-Cut.
- Each tree starts with 5 health unless its `Health` attribute is set.
- When a tree is chopped down, a wood log drops. Players can collect it with the prompt; the script increments the `leaderstats.Wood` value.
- Save Location and Walk Back use normal pathfinding and movement.
- The panel supports touch/mouse dragging, minimize, close, and theme changes.

## Notes
- This is a starter system. Connect the awarded Wood value to your own inventory/economy if your game already has one.
- If your existing trees use a different model hierarchy or your axe has a custom server-side hit system, adapt the tag/axe checks to that structure rather than duplicating your existing damage logic.
- The old `main.lua` is a client preview tool for structure manipulation. These Studio scripts are a separate, server-authoritative sawmill implementation; they do not change that legacy file.
