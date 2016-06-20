audio_files = Dir["/Volumes/RECORD/RECORD/VOICE/*"]

filtered = audio_files.select do |file|
	file !~ /_/
end

dates = filtered.each do |name|
	name.slice!(0,29)
	name.slice!(8,12)
end

def rubybash(script)
	system 'osascript', *script.split(/\n/).map { |line| ['-e', line] }.flatten
end

dates.each do |date|
	out_file = File.new("/Volumes/M_EXTENDED/REC/ls/#{date}.txt", "w")
	out_file.puts("file '/Volumes/RECORD/RECORD/VOICE/#{date}.WAV'")
	out_file.puts("file '/Volumes/RECORD/RECORD/VOICE/#{date}_02.WAV'")
	out_file.puts("file '/Volumes/RECORD/RECORD/VOICE/#{date}_03.WAV'")
	out_file.puts("file '/Volumes/RECORD/RECORD/VOICE/#{date}_04.WAV'")
	out_file.puts("file '/Volumes/RECORD/RECORD/VOICE/#{date}_05.WAV'")
	out_file.puts("file '/Volumes/RECORD/RECORD/VOICE/#{date}_06.WAV'")
	out_file.puts("file '/Volumes/RECORD/RECORD/VOICE/#{date}_07.WAV'")
	out_file.puts("file '/Volumes/RECORD/RECORD/VOICE/#{date}_08.WAV'")
	out_file.puts("file '/Volumes/RECORD/RECORD/VOICE/#{date}_09.WAV'")
	out_file.close
end

dates.each do |date|
	rubybash <<-END
	tell application "iTerm"
		tell i term application "iTerm" to run
			tell the current terminal
				activate current session
				delay 0.2
				tell i term application "System Events" to keystroke "a" using control down
				delay 0.2
				tell i term application "System Events" to keystroke "c"
				delay 1.5
				tell the last session
					write text "ffmpeg -f concat -i /Volumes/M_EXTENDED/REC/ls/#{date}.txt -ac 1 -q:a 15 /Volumes/M_EXTENDED/REC/ARC/#{date}.mp3"
			end tell
		end tell
	end tell
	END
end
