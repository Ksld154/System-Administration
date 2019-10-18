#!/usr/local/bin/bash

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
	
	option=$(dialog --clear --title "Network Interface" --menu "Choose a network interface: " 30 100 25 $ipList 2>&1 > /dev/tty)
	ok=$?
	
	# select ok
	if [ $ok -eq 0 ]; then

		interface_name="Interface Name: $option"
		ipv4_addr="$(ifconfig $option | grep 'inet ' | awk '{print $2}')"
		netmask="$(ifconfig $option | grep 'netmask ' | awk '{print $4}')"
		mac_addr="$(ifconfig $option | grep 'ether ' | awk '{print $2}')"

		output_msg=$( 
			echo -e "\nIpv4 Addr: "${ipv4_addr}
	 		echo -e "\nNetmask:   "${netmask}
			echo -e "\nMac Addr:  "${mac_addr}
		)		

		dialog --title "Network Interface Info" --clear --msgbox "${output_msg}" 30 100
		
		ok=$?
		if [ $ok -eq 0 ]; then
			show_network
		fi		

	# go back to sys menu
	elif [ $ok -eq 1 ]; then
		sys_info		
	fi				
}


function readable_unit(){
	file_size=$1
	file_size_accurate=$1
	file_unit_cnt=0
	file_unit="B"

	file_size_accurate=$(echo "$file_size_accurate" | awk '{printf "%.4f \n", $1/1}')
	file_size=$(echo "$file_size" | awk '{printf "%d \n", $1/1}')

	while [ ${file_size} -gt 1024 ]; do
		file_unit_cnt=$((${file_unit_cnt}+1))
        	file_size_accurate=$(echo "$file_size_accurate" | awk '{printf "%.4f \n", $1/1024}')
        	file_size=$(echo "$file_size" | awk '{printf "%d \n", $1/1024}')
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
	
	echo ${file_size_accurate}" "${file_unit}

	return 0
}



function show_mem(){

	while true; do

		phy_mem=$(sysctl -n hw.physmem)
		avail_mem=$(vmstat -H | tail -n 1 | awk '{printf "%d\n", $5*1024}')
		used_mem=$(echo "$phy_mem $avail_mem" | awk '{printf "%d \n", $1-$2}')				
		mem_usage=$(echo "$phy_mem $avail_mem" | awk '{printf "%d \n", (1-($2/$1))*100}')
		
		phy_mem_unit=$( readable_unit ${phy_mem})
		avail_mem_unit=$( readable_unit ${avail_mem})
		used_mem_unit=$( readable_unit ${used_mem})

		output_msg=$( 
			echo -e "\n\nTotal: "$phy_mem_unit
	 		echo -e "Used:  "$avail_mem_unit
			echo -e "Free:  "$used_mem_unit
		)

		# dialog --title "Memory Info and Usage" --gauge "${output_msg}" 20 70 ${mem_usage}
		(sleep 1) | dialog --title "Memory Info and Usage" --gauge "${output_msg}" 30 100 ${mem_usage}
		
		#read -t 3 -r 1 -N 1 key_input
		read -s -t 3.1		
		if [ $? -eq 0 ]; then
			break
		fi
	done
	
	sys_info
}

function file_browser(){
	current_path=$(pwd | awk '{print "Current path: " $1}')
	fileList=$(ls -alh | tail -n +2 | awk '{print $9}' | xargs file --mime-type | tr ":" " ")
	
	option=$(dialog --clear --title "File Browser" --menu "${current_path}" 30 100 30 ${fileList} 2>&1 > /dev/tty)
	
	if [ $? -eq 1 ]; then
		sys_info
	fi

	# is a file
	if [ -f ${option} ]; then
		file_info ${option}
	# is a folder
	elif [ -d ${option} ]; then
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
		response=$?

		# Get exit status
		# 0 means user hit [OK] button.
		# 1 means user hit [EDIT] button.
		case ${response} in
		   0) file_browser;;
		   1) ${EDITOR} ${filename};;
		esac
	else 
		dialog --title "File Info" --clear --msgbox "${output_msg}" 30 100
	fi	
	file_browser
}

function cpu_loading(){
	while true; do

		each_cpu_info=$(top -P -n | grep "^CPU" | awk '{print $1 $2 " USER: " $3 " SYST: " $7 " IDLE: " $11}')
		cpu_idle=$(top -n 1 | grep "^CPU" | awk '{print $10}')
		cpu_usage=$(echo "${cpu_idle}" | awk '{printf "%d \n", (100-$1)}')
	  	

		(sleep 1) | dialog --title "CPU Loading" --gauge "${each_cpu_info}" 30 100 ${cpu_usage}
		
		
		 read -s -t 5		
		 if [ $? -eq 0 ]; then
			break
		 fi
	done
	
}

function cpu_new(){
	(while true; do
		each_cpu_info=$(top -P -n | grep "^CPU" | awk '{print $1 $2 " USER: " $3 " SYST: " $7 " IDLE: " $11}')
		cpu_idle=$(top -n 1 | grep "^CPU" | awk '{print $10}')
		cpu_usage=$(echo "${cpu_idle}" | awk '{printf "%d \n", (100-$1)}')
	  	


		echo "XXX"
		echo ${cpu_usage}
		echo ${each_cpu_info}
		echo "XXX"
		
		keyborad_input="q"
		read -s -n 1 -t 0.1 keyborad_input
		if [ $? -eq 0 ] && [ "${keyborad_input}" == $"\r" ]; then
			return
		fi
	done) |  dialog --title "CPU Loading" --gauge "${each_cpu_info}" 30 100 ${cpu_usage}	
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
		4 "FILE BROWSER" \
		5 "CPU LOADING" 2>&1 >/dev/tty)
		
		if [ $? -eq 1 ]
		then
			echo "Bye"
			exit 0
		fi
		

		# make decsion 
		case $sys_menu in
			1) show_cpu;;
			2) show_mem;;
			3) show_network;;
			4) file_browser;;
			5) cpu_loading;;
		esac

	done

}


# main function
sys_info


echo "$?"

