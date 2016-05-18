#Audiomator

Ruby automation script that uses FFmpeg to compress WAV files down to MP3 files.

This script is useful if you regularly use a USB flash drive to record conversations, and need to compress them in order to save space.

To use it, simply alter the file paths to reflect your desired input and output directories.

###Dependencies
* Mac OSX (any version)
* iTerm
* tmux
* FFmpeg

###Input Directory Naming Conventions
* Name first file in a series as date (ex `16-05-18.WAV`)
* Name other files in series with a `_` and number (ex `16-05-18_02.WAV`)

###Automation Workflow
* Fetches filenames from input directory
* Filters out filenames containing `_`
* Slices out date from file path string
* Creates a `.txt` file to perform FFmpeg concatenation
* Uses and osascript method to run AppleScript commands to:
	* Connect to current tmux session
	* Create new tmux window for each date sequence
	* Execute bash FFmpeg command
