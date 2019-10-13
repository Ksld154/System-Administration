#!/usr/local/bin/bash
# utilitymenu.sh - A sample shell script to display menus on screen
# Store menu options selected by the user
INPUT=/tmp/menu.sh.$$

# Storage file for displaying cal and date command output
OUTPUT=/tmp/output.sh.$$

# get text editor or fall back to vi_editor
vi_editor=${EDITOR-vi}

# trap and delete temp files
trap "exit 1" SIGHUP SIGINT SIGTERM

#
# Purpose - display output using msgbox 
#  $1 -> set msgbox height
#  $2 -> set msgbox width
#  $3 -> set msgbox title
#
function display_output(){
	local h=${1-10}			# box height default 10
	local w=${2-41} 		# box width default 41
	local t=${3-Output} 		# box title 
	dialog --backtitle "Linux Shell Script Tutorial" --title "${t}" --clear --msgbox "$(<$OUTPUT)" ${h} ${w}
}
#
# Purpose - display current system date & time
#
function show_date(){
	echo "Today is $(date) @ $(hostname -f)." >$OUTPUT
    	display_output 6 60 "Date and Time"
}
#
# Purpose - display a calendar
#
function show_calendar(){
	cal >$OUTPUT
	display_output 13 25 "Calendar"
}


function show_cpu(){
	cpu_model="CPU Model: $(sysctl hw.model | cut -d ' ' -f 2-)"
	cpu_machine="CPU Machine: $(sysctl hw.machine | cut -d ' ' -f 2-)"
	cpu_core="CPU Core: $(sysctl hw.ncpu | cut -d ' ' -f 2-)"
	dialog --title "CPU Info" --clear --msgbox "\n\n$cpu_model\n\n$cpu_machine \n\n$cpu_core" 30 100
}




function show_network(){
	ipList=$(ifconfig -l | tr " " "\n" | awk '{print $1 " +"}')
	# exec 3>&1
	
	option=$(dialog --clear --title "Network Interface" --menu "Choose a network interface: " 30 100 25 $ipList 2>&1 > /dev/tty)
	ok=$?

	echo $option
	
	# select ok
	if [ $ok -eq 0 ]; then
		# interface_name="Interface Name: $option"

		interface_name="Interface Name: $option"
		ipv4_addr="$(ifconfig $option | grep 'inet ' | awk '{print "Ipv4 Addr: "$2}')"
		netmask="$(ifconfig $option | grep 'netmask ' | awk '{print "Netmask:   "$4}')"
		mac_addr="$(ifconfig $option | grep 'ether ' | awk '{print "Mac Addr:  "$2}')"
		
		dialog --title "Network Interface Info" --clear --msgbox "\n\n$interface_name\n\n\n\n$ipv4_addr\n\n$netmask \n\n$mac_addr" 30 100
		ok=$?
		echo $ok
		if [ $ok -eq 0 ]; then
			show_network
		fi		
	
	elif [ $ok -eq 1 ]; then
		sys_info		
	fi		
		
}

function mem_info(){
	DIALOG=${DIALOG=dialog}
	phy_mem=$(sysctl -n hw.physmem)
	avail_mem="$(dmesg | grep memory | sed -n 2p | awk '{print $4}')"
	mem_usage=$(echo "$phy_mem $avail_mem" | awk '{printf "%d \n", (1-($2/$1))*100}')

	SIZE_FORMAT="B"
	KB=$((1024**1))
	MB=$((1024**2))
	GB=$((1024**3))
	TB=$((1024**4))
	
	#mem_usage=0

	COUNT=10
	(
		#while



		while test $COUNT != 110
		do
			
			if [ $phy_mem -gt $GB ]; then
				SIZE_FORMAT="GB"
				avail_mem="$(dmesg | grep memory | sed -n 2p | awk '{print $4}')"
				mem_usage=$(echo "$phy_mem $avail_mem" | awk '{printf "%d \n", (1-($2/$1))*100}')
				
				echo $mem_usage
				echo "XXX"
				avail_mem=$(echo "$avail_mem $GB" | awk '{printf "%d \n", $1/$2}')
				phy_mem2=$(echo "$phy_mem2 $GB" | awk '{printf "%d \n", $1/$2}')
				used_mem=$(echo "$phy_mem $avail_mem" | awk '{printf "%d \n", $1-$2}')
				echo "XXX"

				

			fi
			echo $phy_mem2$SIZE_FORMAT
			echo $used_mem$SIZE_FORMAT
			echo $avail_mem$SIZE_FORMAT
			
			sleep 1
		done
	) |
	$DIALOG --title "My Gauge" --gauge "Hi, this is a gauge widget" 20 70 0

}

#
# set infinite loop
#
function sys_info(){

	while true
	do

		### display main menu ###
		sys_menu=$(dialog --clear  \
		--title "SYSTEM INFO" \
		--menu "Choose a TASK" 30 100 25 \
		1 "CPU INFO" \
		2 "MEMORY INFO" \
		3 "NETWORK INFO" \
		4 "FILE BROWSER" 2>&1 >/dev/tty)
		
		if [ $? -eq 1 ]
		then
			echo "Bye"
			exit 0
		fi
		
		#menuitem=$(<"${INPUT}")

		# make decsion 
		case $sys_menu in
			1) show_cpu;;
			2) mem_info;;
			3) show_network;;
			4) show_calendar;;
		esac

	done

}


# main function
sys_info





echo "$?"
# if temp files found, delete em
[ -f $OUTPUT ] && rm $OUTPUT
[ -f $INPUT ] && rm $INPUT
