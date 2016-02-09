# enable blowfish encryption in channel
set blowfish_(enabled) "1"

# Drftpd or glftpd bot nick
set upbotnick "xxx"

set isy_(log_chan) "#autoup"

# Announce url with passkey
set isy_(ann_url) "http://example.com/announce.php"

set isy_(torrent_output) "/home/eggbots/torrent-dir"

set isy_(dir_path) "/jail/glftpd/site"

set isy_(filesdblink) "/home/eggbots/files-db"
set isy_(emptynfo) "/home/eggbots/islander.nfo"

set isy_(skip1) ".message"
set isy_(skip2) ".imdb"
set isy_(skip3) ".*"

bind bot - COMPLETE completeme
bind bot - GETDELETE deleteme

bind pub - !delete isy:deletetorrent
bind pub - !complete isy:createtorrent

if { $blowfish_(enabled) == "1" } {
	bind pub - +OK cmdencryptedincominghandler
}

# blowcrypt code by poci modified by Islander
# Make sute u change the channel name and fishkey in the getfishkey function

proc getfishkey { chan } {
	
	array set channelkeys {
			"#autoup" 		"xxx"
	}
	
    foreach {channel blowkey} [array get channelkeys] {
        if {[string equal -nocase $channel $chan]} {
			return $blowkey
		} 
    }
}

proc cmdputblow {text {option ""}} {
	global blowfish_
	
	if {$option==""} {
	
		if {[lindex $text 0]=="PRIVMSG" && $blowfish_(enabled) == 1} {
			
			set blowfishkey [getfishkey [string tolower [lindex $text 1]]]
			
			if { $blowfishkey != "" } {
				putquick "PRIVMSG [lindex $text 1] :+OK [encrypt $blowfishkey [string trimleft [join [lrange $text 2 end]] :]]"
			}
		
		} else {
			putquick $text
		}
		
	} else {
	
	  	if {[lindex $text 0]=="PRIVMSG" && $blowfish_(enabled) == 1} {
			
			set blowfishkey [getfishkey [string tolower [lindex $text 1]]]
			
			if { $blowfishkey != "" } {
				putquick "PRIVMSG [lindex $text 1] :+OK [encrypt $blowfishkey [string trimleft [join [lrange $text 2 end]] :]]" $option
			}
		
		} else {
			putquick $text $option
		}
		
	}
	
}

proc cmdencryptedincominghandler {nick host hand chan arg} {
	global isy_
	
	if { $chan != $isy_(log_chan) } {return}
	
	set blowfishkey [getfishkey [string tolower $chan]]
	
	if { $blowfishkey == "" } {return}
	
	set tmp [decrypt $blowfishkey $arg]
	set tmp [stripcodes bc $tmp]
	
	foreach item [binds pub] {
	
		if {[lindex $item 2]=="+OK"} {continue}
		
		if {[lindex $item 1]!="-|-"} {
			if {![matchattr $hand [lindex $item 1] $chan]} {continue}
		}
		
		if {[lindex $item 2]==[lindex $tmp 0]} {
			[lindex $item 4] $nick $host $hand $chan [string trim [lrange $tmp 1 end]]
		}
	
	}
	
}

# blowcrypt code by poci modified by Islander END

# piece function for mktorrent-borg
proc isy:piece_sizeold {len} {

	set p 256
	
	if {$len >= 4000000} {
		set p 4096
	} elseif {$len >= 2000000} {
		set p 2048
	} elseif {$len >= 1000000} {
		set p 1024
	} elseif {$len >= 100000} {
		set p 512
	}
	
	return $p
	
}

# Pieces function for mktorrent 1.0
# 18 = 256kb , 19 = 512kb , 20 = 1MB , 21 = 2MB , 22 = 4MB , 23 = 8MB
proc isy:piece_size {len} {

	set p 21
	
	if {$len >= 8000000} {
		set p 22
	} elseif {$len >= 4000000} {
		set p 22
	} elseif {$len >= 2000000} {
		set p 22
	} elseif {$len >= 1000000} {
		set p 22
	} elseif {$len >= 500000} {
		set p 21
	} elseif {$len >= 250000} {
		set p 21
	} elseif {$len >= 100000} {
		set p 21
	} elseif {$len >= 50000} {
		set p 20
	} elseif {$len >= 25000} {
		set p 20
	} elseif {$len >= 10000} {
		set p 20
	} elseif {$len >= 5000} {
		set p 19
	} elseif {$len >= 1000} {
		set p 19
	}
	
	return $p
	
}

proc deleteme {bot com args} {
	
	set nick "Islander"
	set host "Islander@owner.example.com"
	set hand "*"
	set chan "#autoup"
	
	set arg [lindex [lindex $args 0]]
	
	return [isy:deletetorrent $nick $host $hand $chan $arg]

}

# run every hour
#bind time - "00 * * * *" isy:deletetorrent

proc isy:deletetorrent {nick host hand chan arg} {
 global isy_ 
	
	set rlsname [string trim [lindex $arg 1]]
	set catmain [string trim [lindex $arg 0]]
	set category [string trim [lindex [string trim [split $catmain "/"]] 0]]
	
	if { $category == "0DAY" || $category == "MP3" || $category == "XXX-0DAY" || $category == "FLAC" } {
	
		set subcat [string trim [lindex [string trim [split $catmain "/"]] 1]]
		
		set torrents [glob -nocomplain -directory $isy_(torrent_output)/$catmain *]
		
		foreach thistorrent $torrents {
		
			set thisrelease [string trim [lindex [string trim [split $thistorrent "/"]] end]]
			
			if { [file isdirectory $isy_(filesdblink)/$thisrelease] } {
				exec rm $isy_(filesdblink)/$thisrelease
			}
			
			cmdputblow "PRIVMSG $isy_(log_chan) :!seedingdelete $thisrelease"
			
		}
		
		if { [file isdirectory $isy_(torrent_output)/$catmain] } {
			exec rm -rf $isy_(torrent_output)/$catmain
		}
	
	} else {
	
		if { [file isdirectory $isy_(filesdblink)/$rlsname] } {
			exec rm -rf $isy_(filesdblink)/$rlsname
		}
		
		if { [file exists $isy_(torrent_output)/$catmain/$rlsname.torrent] } {
			exec rm $isy_(torrent_output)/$catmain/$rlsname.torrent
		}
		
		cmdputblow "PRIVMSG $isy_(log_chan) :!seedingdelete $rlsname"
	
	}
	
}

proc completeme {bot com args} {
	
	set nick "Islander"
	set host "Islander@owner.example.com"
	set hand "*"
	set chan "#autoup"
	
	set arg [lindex [lindex $args 0]]
	
	return [isy:createtorrent $nick $host $hand $chan $arg]

}

proc isy:createtorrent {nick host hand chan arg} {
 global isy_ 
	
	set a [clock seconds]
	set release [string trim [lindex $arg 1]]
	set category [string trim [lindex $arg 0]]
	set genre [string trim [lindex $arg 2]]
	
	if { $category == "" || $release == "" } {
	
		cmdputblow "PRIVMSG $isy_(log_chan) :\0034\002\Release Name or Category Empty !!\002\003"
		return
		
	}
	
	if { $category == "0DAY" || $category == "MP3" || $category == "XXX-0DAY" || $category == "FLAC" } {
		
		set whatjoin [clock format [clock seconds] -format %m%d]
		
		if { ![file isdirectory $isy_(torrent_output)/$category] } {
			exec mkdir $isy_(torrent_output)/$category
		}
		
		if { ![file isdirectory $isy_(torrent_output)/$category/$whatjoin] } {
			exec mkdir $isy_(torrent_output)/$category/$whatjoin
		}
		
		set category $category/$whatjoin
	
	} elseif { ![file isdirectory $isy_(torrent_output)/$category] } {

		exec mkdir $isy_(torrent_output)/$category
	}
	
	if { [file exists $isy_(torrent_output)/$category/$release.torrent] } {
	
		cmdputblow "PRIVMSG $isy_(log_chan) :\0032\002$release\002\003 Torrent already exists"
		return
		
	}

	set ndir $isy_(dir_path)/$category/$release
	
	if { ![file isdirectory $ndir] } {
	
		cmdputblow "PRIVMSG $isy_(log_chan) :\0032\002$release\002\003 N0T F0UND !!"
		return
		
    }
	
	set dirsize [string trim [lindex [exec du -c $ndir] 0]]
	
	set psize [isy:piece_size $dirsize]
	
	# mktorrent 1.0
	catch { exec mktorrent -a $isy_(ann_url) -p -l $psize -o $isy_(torrent_output)/$category/$release.torrent $ndir } data
	
	# mktorrent-borg
	# catch { exec mktorrent -bs $psize -a $isy_(ann_url) -ig $isy_(skip1) -ig $isy_(skip2) -o $isy_(torrent_output)/$category/$release.torrent $ndir } data
	
	set b [expr [clock seconds] - $a]
	
	set status [string trim [lindex $data end]]
	
	if { $status == "done." } {
	
		set size [filesize [file size $isy_(torrent_output)/$category/$release.torrent]]
		set dsize [filesize $dirsize]
		
		set var [glob -directory $ndir *.nfo]
		set nfo [string trim [lindex [split $var "/"] end]]
		
		cmdputblow "PRIVMSG $isy_(log_chan) :!upload $category $release $nfo $genre"
		cmdputblow "PRIVMSG $isy_(log_chan) :\0033\002$release\002\003 \[$dsize\] Torrent Successfully Created in $b seconds with $size . Sending Upload command..."
		
		exec ln -s $ndir $isy_(filesdblink)
		return
	
	} elseif { $status == "wrong..." } {
		
		exec rm $isy_(torrent_output)/$category/$release.torrent
		
		cmdputblow "PRIVMSG $isy_(log_chan) :\0034\002$release\002 Torrent Creation FAiLED !!\003 Error: $status \0033Timer Activated for 5 seconds\003"
		
		set nick "Islander"
		set host "Islander@owner.example.com"
		set hand "*"
		set chan "#autoup"
		
		set sendargs [join [list $category $release $genre]]
	
		utimer 5 [list isy:createtorrent $nick $host $hand $chan $sendargs]
		
	} else {
		
		exec rm $isy_(torrent_output)/$category/$release.torrent
		
		cmdputblow "PRIVMSG $isy_(log_chan) :\0034\002$release\002 Torrent Creation FAiLED !!\003 Error: $status"
		
		return
		
	}
	

}

proc filesize { zzzsize } {
	set size [lindex $zzzsize 0]
	
	set sized "0 kB"
	
	if {[expr $size / 1073741824] >= 1} {
	
		set sized "[string range "[expr $size / 1073741824.0]" 0 [expr [string length "[expr $size / 1073741824]"]+ 2] ] GB"
	
	} elseif {[expr $size / 1048576] >= 1} {
	
		set sized "[string range "[expr $size / 1048576.0]" 0 [expr [string length "[expr $size / 1048576]"]+ 2] ] MB"
		
	} elseif {[expr $size / 1024] >= 1} {
	
		set sized "[string range "[expr $size / 1024.0]" 0 [expr [string length "[expr $size / 1024]"]+ 2] ] KB"
		
	}
	
	return $sized
}

putlog "AutoUpload v1.74 By Islander -> Loaded Successfully."