# Irssi-XChat to Weechat log converted

This is a script I wrote to convert IRC logs from the format that Irssi logs in to the default Weechat format. 

However, it converts from the format that *my* Irssi client used, which was some modified version based on the [xchat theme](http://irssi.org/themefiles/xchat.theme) ([picture](http://irssi.org/themefiles/xchat.png). Because Irssi is silly and saves logs that match what's displayed on screen (so themes affect the log format), it may be of questionable use to you.

## Usage

	ruby irssi2weechat.rb path/to/file1 path/to/file2 ...

The script will convert each file and output `file1.weechat_conv.log` etc. to the same directory the input file was from.
