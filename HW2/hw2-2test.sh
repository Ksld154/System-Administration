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

function readable_unit(){
	file_size=$1
	file_unit_cnt=0
	file_unit="B"

	while [ ${file_size} -gt 1024 ]; do
		file_unit_cnt=$((${file_unit_cnt}+1))
        file_size=$(echo "$file_size" | awk '{printf "%.3f \n", $1/1024}')
	done

	case ${file_unit_cnt} in
		0) file_unit="B";;
		1) file_unit="KB";;
		2) file_unit="MB";;
		3) file_unit="GB";;
		4) file_unit="TB";;
		5) file_unit="PB";;
		*) file_unit="B";;
	esac

	echo ${file_size}" "${file_unit}

	return 0
}



function mem_info(){

	SIZE_FORMAT="B"
	KB=$((1024**1))
	GB=$((1024**3))
	
	# phy_mem=$(sysctl -n hw.physmem)
	# avail_mem=$(sysctl -n hw.usermem)	
	# mem_usage=$(echo "$phy_mem $avail_mem" | awk '{printf "%d \n", (1-($2/$1))*100}')
	
	(
		#while
		while true; do
			phy_mem=$(sysctl -n hw.physmem)
			avail_mem=$(sysctl -n hw.usermem)
			used_mem=$(echo "$phy_mem $avail_mem" | awk '{printf "%d \n", $1-$2}')				
			mem_usage=$(echo "$phy_mem $avail_mem" | awk '{printf "%d \n", (1-($2/$1))*100}')
			
			phy_mem_unit=$(readable_unit ${phy_mem})
			avail_mem_unit=$(readable_unit ${avail_mem})
			used_mem_unit=$(readable_unit ${used_mem})

			# echo "XXX"
			# 	echo "Memory Info and Usage\n\n"
			# 	echo "Total: "$phy_mem2$SIZE_FORMAT
			# 	echo "Used:  "$used_mem2$SIZE_FORMAT
			# 	echo "Free:  "$avail_mem2$SIZE_FORMAT
			# echo "XXX"

			echo mem_usage
			sleep 1
		done
	) | dialog --title "Memory Info and Usage" --gauge "Memory Info and Usage" 20 70 ${mem_usage}

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
