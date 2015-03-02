DEBUG = 2

# get filenames fed to us via cmdline
# innate advantage: paths will always work!
logfiles = ARGV[0..-1]

puts "Converting #{logfiles.length} files" if DEBUG >=1 

logfiles.each { |filename| 
    File.open(filename, "r") do |file_handle|

        # irssilogs/network/#channel.YYYY-MM-DD.log
        filename =~ /(.*?)(#[^.]+)\.(\d\d\d\d-\d\d-\d\d)\.log$/
        path = $1
        channel_name = $2
        date = $3

        out_filename = "#{path}#{channel_name}.#{date}.weechat_conv.log"

        File.open(out_filename, File::RDWR|File::CREAT) do |out_file|

            # iterate lines in file
            file_handle.each_line do |line|
                # figure out which type of line it is and convert accordingly

                line.chomp!

                # Doesn't catch the user printout upon joining a channel
                # Doesn't catch topic changes (but we don't do that, lol)
		# Doesn't catch your own nick changes (logged as "You are now known...")
                # msg, action, join, part, quit, nick, mode

                timestamp = /^(\d\d):(\d\d)/
                re_nick = /([^ ]+)/
                channel = /(#[^ ]+)/
                # HH:MM <@    NNNNNNICK> | MSG
                msg = /#{timestamp} <([^ ]?)\s*(\S+)> \| (.*)$/

                # HH:MM                * | NICK MSG
                action = /#{timestamp}\s+\* \| #{re_nick}( .*)$/

                # HH:MM              --> | NICK [USER@HOST] has joined #channel
                join = /#{timestamp}\s+--> \| #{re_nick} \[([^\]]+)\] has joined #{channel}/

		# HH:MM              <-- | Nick [User@host.name] has left #channel ( "")
                part = /#{timestamp}\s+<-- \| #{re_nick} \[([^\]]+)\] has left #{channel} \( (.*?)\)/

		# HH:MM              <-- | Nick [User@host.name] has quit (Ping timeout: 121 seconds)
                quit = /#{timestamp}\s+<-- \| #{re_nick} \[([^\]]+)\] has quit \((.*?)\)/

		# HH:MM              --- | Nick is now known as OtherNick
                nick = /#{timestamp}\s+--- \| #{re_nick} is now known as #{re_nick}/

                # HH:MM              --- | ChanServ sets modes [#channel +qo Nick Nick]
                mode = /#{timestamp}\s+--- \| #{re_nick} sets modes \[#{channel} ([^\]]+)\]/

                # unfortunately we have no second information so we must make it up
		line =~ timestamp # match the timestamp
                # $1 is always the timestamp
                output = "#{date} #{$1}:#{$2}:00\t"
                case line
                when msg
                    # MSG: ["02", "35", "", "Nick", "sample message text"]
                    puts "MSG: #{$~.captures}" if DEBUG >= 5
                    # 2014-06-10 11:43:54     @Nick   sample message text
                    output += "#{$3}#{$4}\t#{$5}"
                when action
                    # ACTION: ["02", "36", "Nick", "sample action text"]
                    puts "ACTION: #{$~.captures}" if DEBUG >= 5
		    # 2014-06-10 12:20:09      *      Nick sample action text
                    output += " *\t#{$3}#{$4}"
                when join
                    # JOIN: ["21", "43", "Nick", "User@host.name", "#channel"]
                    puts "JOIN: #{$~.captures}"  if DEBUG >= 5
		    # 2014-06-10 00:00:57     -->     Nick (User@host.name) has joined #channel
                    output += "-->\t#{$3} (#{$4}) has joined #{$5}"
                when part
                    # PART: ["21", "34", "Nick", "User@host.name", "#channel", "part message"]
                    puts "PART: #{$~.captures}" if DEBUG >= 5
		    # 2014-06-10 21:32:40   <-- Nick (user@host.name) has left #channel ("WeeChat 1.0-dev")
                    output += "<--\t#{$3} (#{$4}) has left #{$5}"
                    output += " (#{$6})" if $6 != "" # add part message if it exists
                when quit
                    # QUIT: ["18", "30", "Nick", "User@host.name", "Quit message"]
                    puts "QUIT: #{$~.captures}" if DEBUG >= 5
		    # 2014-06-10 18:26:15 <-- Nick (User@host.name) has quit (Quit message)
                    output += "<--\t#{$3} (#{$4}) has quit (#{$5})"
                when nick
                    # NICK: ["15", "13", "Nick", "OtherNick"]
                    puts "NICK: #{$~.captures}" if DEBUG >= 5
		    # 2014-06-10 00:24:43     --      Nick is now known as OtherNick
                    output += "--\t#{$3} is now known as #{$4}"
                when mode
                    # MODE: ["15", "14", "ChanServ", "#channel", "+o Nick"]
                    puts "MODE: #{$~.captures}" if DEBUG >= 5
		    # 2014-06-10 11:40:38    --  Mode #channel [+o Nick] by ChanServ
                    output += "--\tMode #{$4} [#{$5}] by #{$3}"
                else
                    puts "MATCH FAILED FOR LINE: #{line}" if DEBUG >= 5
                    next # don't print this empty line
                end

                out_file.puts output
            end

            puts "Wrote #{out_filename}" if DEBUG >= 2 

        end
    end
}
