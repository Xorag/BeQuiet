# BeQuiet
A simple add-on that suppresses the giant frame and the audio for the talking chat heads from NPCs when entering world quests or instances only leaving their text in the regular chat box.

Use '/bq config' or '/bq' to see the help and available options.

You can enable or disable the add-on functionality on the fly and also toggle your *current* major zone or sub-zone for whitelisting.

 

Functionality:

1. '/bq on | off | toggle' This will allow you turn the blocking functionality on or off - this is an account wide setting, not per-character.

2. '/bq whitelist (currentzone | currentsubzone)' This will allow talking heads in your current major zone or sub-zone. The zones are dictated by where you are in the game, but an example for a Major zone would be Orgrimmar and an example of the sub-zone would be the Valley of Strength. This should help users quickly whitelist areas based on their immediate needs and preferences and won't require me to maintain a full whitelist. Use the command once to add the zone to the whitelist and a second time to remove it.

3. '/bq blacklist (currentzone | currentsubzone)' Similar to the whitelist command, this will block the current zone or sub-zone always. Even when bq is set to off. Just like whitelist the command toggles. It defaults to empty.

4. '/bq reset' will reset the whitelist back to the withered army training, island expedition zones, and torghast only. This will also reset the blacklist back to empty.

5. '/bq show' will print the current list of whitelisted zones to your chatbox.

6. '/bg verbose' will print a message in your chat box indicating that a talking head was blocked. I'm adding this with the Shadowlands release for some players who might not realize the talking heads are being blocked when new content releases. Run the command to toggle it on or off.

7. '/bq delete' will totally delete the whitelist and blacklist.

8. '/bq vo' will allow the vo to continue when the ui frame is hidden.
