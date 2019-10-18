sysctl hw.model hw.machine hw.ncpu

ifconfig -s | sed -n '1!p' | awk '{print $1}'

CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)



# em0 *
# lo0 *
ipString=$(ifconfig -l)
ipList=($ipString)
ipListOption=("${ipList[@]/%/ "*"}")
printf '%s\n' "${ipListOption[@]}"

awk '{a[$7]=$7} 
	END 
	{for(i in a)
		printf i" "a[i]" "
	}'

awk '{a[$7]=$7} 
	END 
	{
		for(i in a)
			printf i" "a[i]" "
	}'



iptr=$(ifconfig -l | tr " " "\n" | awk '{a[$1]=$1} END {for(i in a)printf i" "a[i]" "}')
echo ${iptr}



iptr=$(ifconfig -l | tr " " "\n")
IFS=' ' read -ra interfaces <<< echo ${iptr} 
for i in "${interfaces[@]}"; do
    echo "$i"
done



var=$(ifconfig -l | tr " " "\n" | awk '{print v++,$0}')



ipString=$(ifconfig -l)
ipList=($ipString)
for ((i=0; i<${#ipList[@]}; i++));
do
	ipList[$i]=${i}" "${ipList[$i]}
done
echo ${ipList[1]}


# ramsize=$(expr $hwmemsize / $((1024**3)))

phy_mem=$(sysctl -n hw.physmem)

SIZE_FORMAT="B"
KB=$((1024**1))
MB=$((1024**2))
GB=$((1024**3))
TB=$((1024**4))

if [ $phy_mem -gt $GB ]; then
	SIZE_FORMAT="GB"
	avail_mem="$(dmesg | grep memory | sed -n 2p | awk '{print $4}')"
	
	phy_mem=$(echo "$phy_mem $GB" | awk '{printf "%.2f \n", $1/$2}')
	avail_mem=$(echo "$avail_mem $GB" | awk '{printf "%.2f \n", $1/$2}')
	used_mem=$(echo "$phy_mem $avail_mem" | awk '{printf "%.2f \n", $1-$2}')

fi
echo $phy_mem$SIZE_FORMAT
echo $used_mem$SIZE_FORMAT
echo $avail_mem$SIZE_FORMAT


phy_mem=$(sysctl -n hw.physmem)
avail_mem="$(dmesg | grep memory | sed -n 2p | awk '{print $4}')"
mem_usage=$(echo "$phy_mem $avail_mem" | awk '{printf "%d \n", (1-($2/$1))*100}')
echo $mem_usage


GB=$((1024**3))
SIZE_FORMAT="GB"
phy_mem=$(echo "$phy_mem $GB" | awk '{printf "%.2f \n", $1/$2}')
echo $phy_mem$SIZE_FORMAT
avail_mem=$(echo "$avail_mem $GB" | awk '{printf "%.2f \n", $1/$2}')
used_mem=$(echo "$phy_mem $avail_mem" | awk '{printf "%.2f \n", $1-$2}')
echo $avail_mem$SIZE_FORMAT




ifconfig em0 | grep 'inet' | awk '{print "ipv4:    "$2}'
ifconfig em0 | grep 'netmask' | awk '{print "Netmask: "$4}'
ifconfig em0 | grep 'ether' | awk '{print "Mac:     "$2}'