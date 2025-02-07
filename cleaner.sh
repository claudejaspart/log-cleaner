#!/bin/bash

##############################################################
#    log cleaner utility                                     #
#                                                            #
#    Author  : Claude Jaspart 						         #
#    Contact : claude.a.jaspart at gmail.com                 #
#    Version : 0.99                                          #
#    Fil rouge M2I - Formation consultant DevOps             #
#                                                            #
##############################################################


###############################################################
# PARAMETERS                                                  #
# -c : Configure the cleaner 								  #
# -r : Restore files  			      						  #
# -d : Delete files                 						  #
# -v : Verbose mode                                           #
# -h : Help                                                   #
###############################################################

###############################################################
# EXIT CODES                                                  #
#  1 : Invalid command										  #
#  2 : Trying to restore and delete at the same time 	      #
#  3 : Unable to clear the content of a file                  #
###############################################################

###############################################################
# TODO                                                        #
# Display errors and success with color and cross/checkmark   #
# Review error codes and  									  #
###############################################################


# helper functions
##################

# display banner
display_banner()
{
	echo "-------------------------------------"
	echo "LOG CLEANER - V0.99  (use-h for help)"
	echo "-------------------------------------"
	banner_displayed="TRUE"
}

# display the help
display_help()
{
	echo "###############################################################"
	echo "# AVAILABLE OPTIONS                                           #"
	echo "# -c : Config wizard                                          #"
	echo "# -l : List filter settings and stashed files                 #"
	echo "# -s : Stash filtered log files                               #"
	echo "# -r : Restore files, using comma, no whitespaces, no path    #"
	echo "#      Example 1 : ./cleaner.sh -r file1,file2,file3          #"
	echo "#      Example 2 : ./cleaner.sh -r all   (restore all)        #" 							
	echo "# -d : Delete files, using comma, no whitespaces, no path     #"
	echo "#      Example 1 : ./cleaner.sh -d file1,file2,file3          #"
	echo "#      Example 2 : ./cleaner.sh -d all   (delete all)         #" 
	echo "# -u : Uninstall cleaner                                      #"
	echo "# -h : Help                                                   #"
	echo "###############################################################"
	exit 0
}

list_data()
{
	display_settings
	display_stashed_files
}

# display the current settings in verbose mode
display_settings()
{
	echo ""
	echo "Current settings :"
	echo ""
	echo "Log directory..............${logs}"
	echo "Min age (days).............${day_old}"
	echo "Min file size (Mb).........${min_size_mb}"
	echo ""
}

# display the stashed files
display_stashed_files()
{
	echo ""
	echo "Stashed files :"
	echo ""
	list=$(cat "$main_file" | awk 'NR > 2 { print $0}' )
	echo "${list[@]}"
	echo "" 
	echo $(sed -n '2p' $main_file)
	echo ""
	exit
}

# display an empty line
display_empty_line()
{
	if [[ ${verbose} == "TRUE" ]]
	then
		echo ""
	fi
}

# saving the config file
save_config()
{
	result=$(echo "$logs:$day_old:$min_size_mb" > "$config_file")
	# rw for user and group
	chmod 0660 "$config_file"
	return $result
}


# config wizard
config_wizard()
{
	display_banner
	echo ""
	echo "******************************"
	echo "* Configuration wizard start *"
	echo "******************************"
	echo ""
	
	# check if history file is empty
	if [[ -f "${main_file}" && -s "${main_file}" ]]
	then
		echo "A previous instance of the cleaner has been detected."
		until [[ ${ans} == "y" || ${ans} == "n" ]]
		do
			read -p "The wizard will reset it. Are you sure (y/n) ? " ans
		done
		
		if [[ ${ans} == "n" ]]
		then
			echo "Exiting the program."
			exit 0
		else
			# deleting the content of the history
			> "$main_file"
			if [[ $? -gt 0 ]]
			then
				echo -e "\e[31m\xE2\x9C\x98\e[0m Unable to clear ${main_file}."
				echo "Exiting the program."
				exit 3
			else
				echo -e "\e[32m\xE2\x9C\x94\e[0m ${main_file} has been cleared."
				# deleting the stash directory
				res=$(rm -r ${stash} 2>/dev/null)				
				if [[ "$res" -gt 0 ]]
				then
					echo -e "\e[31m\xE2\x9C\x98\e[0m Unable to delete ${stash}."
					echo "Exiting the program."
					exit 3
				else
					echo -e "\e[32m\xE2\x9C\x94\e[0m ${stash} was removed."
				fi
			fi
			echo "The instance was succesfully reset."
		fi
	fi
	
	# Editing the conf
	read -p "Absolute path to the logs to monitor : " logs

	day_old=""
	until [[ $day_old -gt 0 ]]
	do
		read -p "Remove log files older than (in days) : " day_old
		if ! test "$day_old" -eq "$day_old" 2>/dev/null
		then
			echo -e "\e[31m\xE2\x9C\x98\e[0m Incorrect value. Must be an integer."
		fi
	done
	
	min_size_mb=""
	until [[ $min_size_mb -gt 0 ]]
	do
		read -p "Remove log files larger than (in Mb) : " min_size_mb
		if ! test "$min_size_mb" -eq "$min_size_mb" 2>/dev/null
		then
			echo -e "\e[31m\xE2\x9C\x98\e[0m Incorrect value. Must be an integer."
		fi
	done
	
	# saving the conf
	res=save_config
	if [[ "$res" -gt 0 ]]
	then
		echo -e "\e[31m\xE2\x9C\x98\e[0m Unable to save config to ${config_file}."
		echo "Exiting the program."
		exit 3
	else
		echo -e "\e[32m\xE2\x9C\x94\e[0m ${config_file} was successfully saved."
	fi
	
	echo ""
	echo "******************************"
	echo "* Configuration wizard end   *"
	echo "******************************"
	echo ""
}

uninstall()
{
	echo "Uninstalling the cleaner..."
	rm -f "$main_file" 2>/dev/null
	rm -f "$config_file" 2>/dev/null
	rm -rf "$stash" 2>/dev/null
	delete_crontab_entry
	echo "Cleaner successfully removed from the system."
	exit 0
}

# job will launch everyday at midnight (0 0 * * *)
add_crontab_entry()
{
	script_path=$(pwd)
	sync="0 0 * * * $script_path/cleaner.sh -s"
	crontab -l > tmp_crontab
	echo "$sync" >> tmp_crontab
	crontab tmp_crontab
	rm -f tmp_crontab 2>/dev/null
}

delete_crontab_entry()
{
	crontab -l | grep -v "cleaner.sh" > tmp_crontab
	crontab tmp_crontab
	rm -f tmp_crontab 2>/dev/null
}


# Get the new sorted filtered files
get_log_files() 
{
	log_files=$(find "${logs}" -maxdepth 1 -type f \( -atime +${day_old} -o -size +${min_size_mb}M \)  | sed "s|$logs\/|$space|g" | sort ) 
	# if only contains whitespace or newline
	if [[ $log_files =~  ^[[:space:]]*$ ]]
	then
		nb_log_files=0
	else		
		nb_log_files=$( echo "${log_files[@]}" | wc -l )
	fi
}

# Get the disk space used by the new files
get_new_disk_space() 
{
	 total_diskspace=0
	 filtered_array=($filtered_files)
	 
	 # loop through all files
	 for (( index = 0 ; index < ${new_entries} ; index++ ))
	 do
	 {
	 	if [ ${verbose} == "TRUE" ]
		then
			file_data=$( du -m "${filtered_array[$index]}" )
			echo "$file_data"
		fi

	 	tmp=$( du -m "${filtered_array[$index]}" | awk '{print $1}' )
	 	total_diskspace=$(( $total_diskspace + $tmp )) 
	 } 
	 
	 done 
}

# updates the report in main file 
stashed_report()
{
	# calculate new size
	stashed_files=$(find "${stash}" -maxdepth 1 -type f   | sort | xargs du -m)
	total=$(echo "$stashed_files" | awk '{ sum += $1} END{ print sum}')
	echo -e "$main_file_title $total" > tmp
	echo "$stashed_files" | sed "s|$stash\/|$space|g" >> tmp
	
	# save to main file
	cat tmp > "$main_file"
	rm tmp
}

# stash the files 
stash_files()
{
 	# intro
	display_banner
	echo "Stashing files ..."
	
	# retrieve the list of filtered files
	get_log_files 
	
	# add timestamp
	space=""
	t_log_files=$(echo "$log_files" | sed "s|$logs\/|$space|g" | awk '{ t=srand(); print (t+NR)"-"$1;}')
	
	# move files from logs to stash
	for file in $log_files
	do
		new_filename=$(echo "$t_log_files" | grep "$file" )
		mv "$logs/$file" "$stash/$new_filename" 
	done
	
	# create the stash report in main file
	stashed_report
	
	# finish message
	echo "$nb_log_files were stashed."
	echo "Use ./cleaner.sh -l to see all stashed files."
	
	exit
}

# restore files todo
restore_files()
{
	display_banner
	echo "Restoring files"
	
	# get list of all files
	if [[ "$filenames" == "all" ]]
	then
		filenames=$(find $stash -type f | awk -F "-" '{ print $2}' )
	else
		filenames=$(echo $filenames | tr "," " ")
	fi
	
	
	for file in $(echo "${filenames}")
	do
		long_namefile=$(ls $stash/*$file*)
		namefile=$(echo $long_namefile  | awk -F "-" '{ print $2 }')
		echo "==========================================================="
		found=$(ls $stash/*$file* | wc -l)
		if [[ $found -gt 1 ]]
		then
			echo "Skipping : a file with the same name exists in $stash".
		else
			if [[ -e "$logs/$namefile" ]]
			then
			echo "Skipping : a file with the same name exists in $logs".
			else
				mv $long_namefile $logs/$namefile
				echo "File restored."
			fi
		fi
	done
	
	# new report
	stashed_report
	
	exit
}

# delete the files
delete_files()
{
	display_banner
	echo "Deleting files ..."
	
	if [[ "$filenames" == "all" ]]
	then
		# deleting all files : parse all files as list with comma separated
		filenames=$(awk 'NR>2{list=list $2","} END{print substr(list,0,length(list)-1)}' "$main_file" )
		echo "$main_file_tile 0" > "${main_file}"
		# deleting all files
		rm -f "$stash/*" 2>/dev/null
	else
		# deleting selected files
		for file in $(echo $filenames | tr "," " ")
		do		
			# deleting file
			rm -f "$stash/$file" 2>/dev/null
			
			# deleting entry in data file
			grep -v "$file" "$main_file" >> tmp
			cat tmp > "$main_file"
			
			# calculate new size
			total=$(awk 'NR>2 { sum += $1} END{ print sum}' "$main_file")
			echo -e "$main_file_title $total" > tmp
			grep -v "Total" "$main_file" >> tmp
			cat tmp > "$main_file"
			
			# clean files
			rm tmp 2>/dev/null 
		done
	fi
	
	echo "The files have been deleted."
	exit
}



# MAIN
######

# Init
USERHOME="$HOME" 
main_file="${USERHOME}/.cleaner.data"
config_file="${USERHOME}/.cleaner.conf"
logs="$HOME/logs"
stash="${logs}/stash"
day_old="30"
min_size_mb="100"
verbose="FALSE"
filenames=""
banner_displayed="FALSE"
cleaner_installed="FALSE"
total_diskspace=0
nb_log_files=0
log_files=""
main_file_title="Cleaner V0.99 data file\nTotal used disk space (Mb) : "

# Parsing the options
while getopts ":r:d:lhcsu" OPTION; do
   
   case "$OPTION" in
      d) 
         filenames=$OPTARG
         delete_files
         #echo "Delete files : ${delete_files}"
         ;;
      r) 
         filenames=$OPTARG
         restore_files
         #echo "Restore files : ${restore_files}"
         ;;
      c) 
      	config_wizard
         #echo "Config wizard"
         ;; 
      h) 
      	display_help
         #echo "Display help menu"
         ;;
      u) 
         #echo "Uninstall files"
         uninstall
         ;;
      l) 
 			list_data
         #echo "List mode"
         ;;
      s) 
     		stash_files
         #echo "Stash files mode"
         exit 0
         ;;
      *) 
         echo -e "\e[31m\xE2\x9C\x98\e[0m Invalid command. Please use help (-h)"
         exit 1
         ;;
   esac
done



# Cannot restore and delete at the same time
if [[ -n ${delete_files}  ]] && [[ -n ${restore_files} ]]
then
	echo -e "\e[31m\xE2\x9C\x98\e[0m Not possible to delete and restore files at the same time."
	echo "Exiting ..."
	exit 2
fi


# Intro banner
if [[ ${banner_displayed} == "FALSE" ]]
then
	display_banner
fi


# Used options displayed in verbose mode
if [ ${verbose} == "TRUE" ]
then
	display_settings
fi

# first install : create the data file and add the cron job
if [[ ! -f "${main_file}" ]]
then
	echo "First run of the script : installing files and cron job."
	# creating the file
	echo -e "$main_file_title 0" > "${main_file}"
	# creating the stash dir
	mkdir "$stash"
	# create the crontab entry
	add_crontab_entry
else
	cleaner_installed="TRUE"
fi

# Check if config file exists, create it otherwise
if [[ -f "${config_file}" ]]
then
	content=$(grep ":" "${config_file}")
	if [[ "$content" == "" ]]
	then
		# save config
		save_config
	else
		# load config
		logs=$(cut -d ":" -f1 "$config_file")
		day_old=$(cut -d ":" -f2 "$config_file")
		min_size_mb=$(cut -d ":" -f3 "$config_file")
	fi
else
	# save default config
	save_config
fi

if [[ "${cleaner_installed}" == "TRUE" ]]
then
	echo "Cleaner is already installed."
	echo "Use -h to see available options"
fi