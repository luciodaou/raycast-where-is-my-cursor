# Where's Cursor Changelog

## [Version 2.1] - 2025-08-19

Refactored the extension to simplify the commands and add more flexibility.

- The main command now accepts an optional `duration` argument to specify how long the cursor should be highlighted.
- The `toggle-dimming` command now simply calls the main command with a duration of 0, which toggles the dimming on and off.
- The `dim-with-duration` command has been removed and its functionality has been merged into the main command.

## [Version 2] - 2025-08-13

Swift app and Raycast commands fully reviewed to block multiple instances.
Added toggle mode - permanently on
Added Presentation mode - permanently on, area around cursor in yellow. Dimming values for screen and area around cursor can be changed. White circle can be turned on or off.

## [Initial Version] - 2025-08-11