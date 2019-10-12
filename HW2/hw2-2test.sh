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
	ipString=$(ifconfig -l)
	ipList=($ipString)
	ipListOption=("${ipList[@]/%/" +"}")

	dialog --clear \
        --title "Network Interface" \
        --menu "Choose a network interface: " \
        30 100 25 \
	#"1" "Option1" "2" "Option2" \
       	#"${ipListOption[@]}" \
	${ipString}        
	2>&1 >/dev/tty
}

show_network_single(){
	interface_name="Interface Name: $1"
	ipv4_addr="$(ifconfig em0 | grep 'inet' | awk '{print "Ipv4 Addr: "$2}')"
	netmask="$(ifconfig em0 | grep 'netmask' | awk '{print "Netmask:   "$4}')"
	mac_addr="$(ifconfig em0 | grep 'ether' | awk '{print "Mac Addr:  "$2}')"
	
	dialog --title "Network Interface Info" --clear --msgbox "\n\n$interface_name\n\n\n\n$ipv4_addr\n\n$netmask \n\n$mac_addr" 30 100
}


#
# set infinite loop
#
while true
do

	### display main menu ###
	dialog --clear  \
	--title "SYSTEM INFO" \
	--menu "Choose a TASK" 30 100 25 \
	1 "CPU INFO" \
	2 "MEMORY INFO" \
	3 "NETWORK INFO" \
	4 "FILE BROWSER" 2>"${INPUT}"
	
	if [ "$?" = "1" ]
	then
		echo "Bye"
		exit 0
	fi
	
	menuitem=$(<"${INPUT}")

	# make decsion 
	case $menuitem in
		1) show_cpu;;
		2) show_calendar;;
		3) show_network_single;;
		4) show_calendar;;
	esac

done

echo "$?"
# if temp files found, delete em
[ -f $OUTPUT ] && rm $OUTPUT
[ -f $INPUT ] && rm $INPUT
