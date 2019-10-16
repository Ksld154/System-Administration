

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

file=2045
readable_unit ${file}