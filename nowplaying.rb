require 'rubygems'
require 'librmpd'


def np(data, buffer, command)
   mpd = MPD.new 'localhost', 6600
   mpd.connect
   mpd.password "mpdpassword"
   current = Weechat.current_buffer
   song = mpd.current_song
   if song != nil
      time = mpd.status['time'].split(":")
      string = formatString song["title"], song["artist"], time
      Weechat.print("#{current}", "#{string}")
   else
      Weechat.print("", "nowplaying.rb: no song playing, or mpd not connected, or...")
   end
   return Weechat::WEECHAT_RC_OK
   mpd.disconnect
end

def formatString(title, artist, time)
   seconds, total = time[0].to_i, time[1].to_i
   currentMin, currentSec = seconds / 60, seconds % 60
   totalMin, totalSec = total / 60, total % 60
   if currentSec < 10
      currentSec = "0" + currentSec.to_s
   end
   if totalSec < 10
      totalSec = "0" + totalSec.to_s
   end
   "np: #{title} :: #{artist} :: [#{currentMin}:#{currentSec}/#{totalMin}:#{totalSec}]"
end

def weechat_init
   Weechat.register("nowplaying.rb", "Now Playing", "1.0", "GPL3", "Takes 'now playing' data from MPD and outputs it in current channel.", "", "")
   Weechat.hook_command("np", "a", "b", "c", "d", "np", "")
   return Weechat::WEECHAT_RC_OK
end

