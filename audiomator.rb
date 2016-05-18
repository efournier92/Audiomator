require 'pry'

audio_files = Dir["/Volumes/RECORD/RECORD/*"]

filtered = audio_files.select do |file|
	file !~ /_/
end

dates = filtered.each do |name|
	name.slice!(0,23)
	name.slice!(8,12)
end

def rubybash(script)
	system 'osascript', *script.split(/\n/).map { |line| ['-e', line] }.flatten
end

dates.each do |date|
	out_file = File.new("/Volumes/M_EXTENDED/REC/ls/#{date}.txt", "w")
	out_file.puts("file '/Volumes/RECORD/RECORD/#{date}.WAV'")
	out_file.puts("file '/Volumes/RECORD/RECORD/#{date}_02.WAV'")
	out_file.puts("file '/Volumes/RECORD/RECORD/#{date}_03.WAV'")
	out_file.puts("file '/Volumes/RECORD/RECORD/#{date}_04.WAV'")
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
					write text "ffmpeg -i /Volumes/RECORD/RECORD/#{date}.WAV -q:a 15 /Volumes/M_EXTENDED/REC/ARC/#{date}.mp3"
			end tell
		end tell
	end tell
	END
end
