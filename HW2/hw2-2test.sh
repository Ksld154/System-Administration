#!/usr/local/bin/bash
# utilitymenu.sh - A sample shell script to display menus on screen
# Store menu options selected by the user
INPUT=/tmp/menu.sh.$$

# Storage file for displaying cal and date command output
OUTPUT=/tmp/output.sh.$$

# get text editor or fall back to vi_editor
vi_editor=${EDITOR-vi}
export EDITOR="ee" 
# trap and delete temp files
trap "exit 1" SIGHUP SIGINT SIGTERM


function show_cpu(){
	cpu_model="CPU Model: $(sysctl hw.model | cut -d ' ' -f 2-)"
	cpu_machine="CPU Machine: $(sysctl hw.machine | cut -d ' ' -f 2-)"
	cpu_core="CPU Core: $(sysctl hw.ncpu | cut -d ' ' -f 2-)"
	dialog --title "CPU Info" --clear --msgbox "\n\n$cpu_model\n\n$cpu_machine \n\n$cpu_core" 30 100
}




function show_network(){
	ipList=$(ifconfig -l | tr " " "\n" | awk '{print $1 " ."}')
	# exec 3>&1
	
	option=$(dialog --clear --title "Network Interface" --menu "Choose a network interface: " 30 100 25 $ipList 2>&1 > /dev/tty)
	ok=$?

	echo $option
	
	# select ok
	if [ $ok -eq 0 ]; then

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
	file_size_accurate=$1
	file_unit_cnt=0
	file_unit="B"

	while [ ${file_size} -gt 1024 ]; do
		file_unit_cnt=$((${file_unit_cnt}+1))
        	file_size_accurate=$(echo "$file_size_accurate" | awk '{printf "%.4f \n", $1/1024}')
        	file_size=$(echo "$file_size" | awk '{printf "%d \n", $1/1024}')
		#echo ${file_size_accurate}
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
	
	#printf "%4.4f %s\n" ${file_size_accurate} ${file_unit}
	echo ${file_size_accurate}" "${file_unit}

	return 0
}



function show_mem(){

	
	# IFS=
	while true; do

	  	

		phy_mem=$(sysctl -n hw.physmem)
		avail_mem=$(vmstat -H | tail -n 1 | awk '{printf "%d\n", $5*1024}')
		used_mem=$(echo "$phy_mem $avail_mem" | awk '{printf "%d \n", $1-$2}')				
		mem_usage=$(echo "$phy_mem $avail_mem" | awk '{printf "%d \n", (1-($2/$1))*100}')
		
		phy_mem_unit=$( readable_unit ${phy_mem})
		avail_mem_unit=$( readable_unit ${avail_mem})
		used_mem_unit=$( readable_unit ${used_mem})

		output_msg=$( echo -e "\n\nTotal: "$phy_mem_unit
	 		echo -e "Used:  "$avail_mem_unit
			echo -e "Free:  "$used_mem_unit
		)

		# dialog --title "Memory Info and Usage" --gauge "${output_msg}" 20 70 ${mem_usage}
		(sleep 1) | dialog --title "Memory Info and Usage" --gauge "${output_msg}" 30 100 ${mem_usage}
		
		#read -t 3 -r 1 -N 1 key_input
		read -s -t 3		
		if [ $? -eq 0 ]; then
			break
		fi
	done
	
	sys_info
}

function file_browser(){
	current_path=$(pwd | awk '{print "Current path: " $1}')
	# fileList=$(ls -alh | tail -n +2 | awk '{printf("%s ", $9); system("file --mime-type -b " $9)}')
	# fileList=$(ls -alh | tail -n +2 | awk '{print $9 " +"}')
	fileList=$(ls -alh | tail -n +2 | awk '{print $9}' | xargs file --mime-type | tr ":" " ")
	
	option=$(dialog --clear --title "File Browser" --menu "${current_path}" 30 100 30 ${fileList} 2>&1 > /dev/tty)
	
	if [ $? -eq 1 ]; then
		sys_info
	fi
	echo ${option}

	if [ -f ${option} ]; then
		echo ${option}" is a file."
		file_info ${option}
	elif [ -d ${option} ]; then
		echo ${option}" is a folder."
		cd ${option}
		file_browser
	fi
}

function file_info(){
	filename=$1
	filetitle="$(echo "<File Info>: "$1)"
	fileinfo="$(file -b ${filename})"
	filesize=$(stat -l ${filename} | awk '{print $5}')
	filesize_readable="$(readable_unit ${filesize})"


	output_msg=$( echo -e "<File Name>: "${filename}
 		echo -e "<File Info>: "${fileinfo}
		echo -e "<File Size>: "${filesize_readable}
	)
		

	
	# contains text as a sub string
	if [[ ${fileinfo} =~ "text" ]]; then
		# echo ${option}" is a text file."
		
		# show info with editor option
		dialog --title "File Info" --yes-label "OK" --no-label "EDIT" --yesno "${output_msg}"  30 100

		# Get exit status
		# 0 means user hit [yes] button.
		# 1 means user hit [no] button.
		response=$?
		case ${response} in
		   0) file_browser;;
		   1) ${EDITOR} ${filename};;
		esac
	else 
		dialog --title "File Info" --clear --msgbox "${output_msg}" 30 100
	fi	
	file_browser
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
			2) show_mem;;
			3) show_network;;
			4) file_browser;;
		esac

	done

}


# main function
sys_info





echo "$?"
# if temp files found, delete em
[ -f $OUTPUT ] && rm $OUTPUT
[ -f $INPUT ] && rm $INPUT
