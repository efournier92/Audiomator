require 'pry'

def directory_exists?(directory)
  File.directory?(directory)
end

audio_files = Dir["/Volumes/RECORD/RECORD/VOICE/*"]
file_string = '/Volumes/RECORD/RECORD/VOICE/'
stop = 29

unless audio_files.any?
  audio_files = Dir["/Volumes/RECORD/RECORD/*"]
  file_string = '/Volumes/RECORD/RECORD/'
  stop = 23
end

filtered = audio_files.select do |file|
  file !~ /_/
end

dates = filtered.each do |name|
  name.slice!(0, stop)
  name.slice!(8, 12)
end

def rubybash(script)
  system 'osascript', *script.split(/\n/).map { |line| ['-e', line] }.flatten
end

dates.each do |date|
  i = 2
  out_file = File.new("/Volumes/M_EXTENDED/REC/ls/#{date}.txt", "w")
  out_file.puts("file #{file_string}#{date}.WAV'")

  while i <= 9 do
    out_file.puts("file #{file_string}#{date}_0#{i}.WAV'")
    i+=2
  end
  out_file.close
end

dates.each do |date|
  rubybash <<-END
      tell application "iTerm"
      run
      tell the current window
        activate current session
        delay 0.2
        tell application "System Events" to keystroke "a" using control down
        delay 0.2
        tell application "System Events" to keystroke "c"
        delay 1.5
        tell the current session
          write text "ffmpeg -f concat -i /Volumes/M_EXTENDED/REC/ls/#{date}.txt -ac 1 -q:a 15 /Volumes/M_EXTENDED/REC/ARC/#{date}.mp3"
        end tell
      end tell
    end tell
  END
end

