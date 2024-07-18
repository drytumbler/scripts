#!/usr/bin/env bash


###########################################
#############    BACKUP SCRIPT   ##########
###########  - v0.0.1-1beta -  ############
#########   @drytumbler  ##################
###########################################

# Author: Dev Niklobuskrut Schmickl
# E-mail: schmickl@dev.org
# License: Send me money, pls -thx•Bye

# DISCLAIMER: 'This script comes with no warranty, run at your own risk!'

# Version:
VERSION="0.0.1-1beta"

### TODO ###

# COMMIT :)  --- DONE


# Should take arguments --- TODO
# SOURCE should not contain DESTINATION! --- TODO
# set/check dependencies, color stuff etc --- TODO
# expand/compose filenames correctly so $BACKUP_DIR/ represents root/ --- TODO
# Don't exit loop on first error, log and continue --- TODO
# refactor the loop --- TODO
# check if files are actually created or don't increment, failed is printed, but files are counted as created
# Ensure foolproof/safety!!! runs as root --- TODO
# Implement -v --verbose -d --dry-run options --- TODO
# other usefull options? new only, existing only, check all/only existing in BACKUP_DIR ... --- TODO 
# register backup attempt  --- TODO
# exclude pattern --- TODO

# Unimplemented - do NOT use
EXCLUDE=""

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Destination to store backup files
BACKUP_DIR="/mnt/BACKUP"
# Files or directories to backup
SOURCE_DIRS=( "docs" ".bashrc" "garblegob" )

# File to log messages
BACKUP_LOG_FILE="$HOME/.backup.log"

# Color definitions
RED=$(printf "\033[31m")
GREEN=$(printf "\033[32m")
YELLOW=$(printf "\033[33m")
NC='\033[0m' # No Color => resets changes

# Check output directory
if [[ ! -d ${BACKUP_DIR} ]]; then
	echo -e "$RED error: '${BACKUP_DIR}' is not a valid directory $NC"
	exit 1
fi

for entry in ${SOURCE_DIRS[@]}; do
    TOTAL_DIRS=$(echo $([[ -d ${entry} ]] && echo $((TOTAL_DIRS + 1)) || echo "${TOTAL_DIRS}"))
    TOTAL_FILES=$(echo $(($(echo $((find ${entry} -type f -exec ls -l {} +) | wc -l) + TOTAL_FILES))))
done

echo TOTAL_DIRS FOUND: "${TOTAL_DIRS}"
echo TOTAL_FILES FOUND: "${TOTAL_FILES}"

echo
echo -e "${RED}PROGRAM LIVE AS ROOT: PROCEED WITH CAUTION!${NC}"
echo "DISCLAIMER: 'This script comes with no warranty, run at your own risk!' "
echo -n "> Backup files to '${BACKUP_DIR}'? [y/N] "
read -r response

if ! [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
	echo -e "$RED error: aborted by user $NC"
	exit 2
fi
echo

echo -e "Backup $0-v${VERSION} process ${$} ${GREEN}started${NC} at: $(date)" | tee -a $BACKUP_LOG_FILE

COUNTER=0
FAILED=0
CREATED=0
SKIPPED=0

while IFS= read -r line; do
    # find the file in the backup directory
    #  |
    #   ---> compare the modification date
    #            |
    #             ---> skip if not older
    # copy the file
    
    BACKUP_FILE="${BACKUP_DIR}/${line}"

    # test 1: are we receiving valid data?
    if ! [[ -f ${line} ]]; then
	echo -e "${RED} error: input error${NC}"
	echo -e "${line}"
	exit 3
    fi

    # test 2: is the file modified since last backup
    if [[ ${line} -nt ${BACKUP_FILE} ]]; then # true if file is modified or destination not present

	# test 3: if destination not present, create and log NEEDS UPDATE !!!
	# TODO test if creation failed
	if ! [[ -f ${BACKUP_FILE}  ]]; then
	    echo -ne "Creating new file '${BACKUP_FILE}': " | tee -a $BACKUP_LOG_FILE
	    touch -d "" "${BACKUP_FILE}"
	    CREATED=$((CREATED+1))
	else # destination is present but needs update
	    echo -ne "Updating file '${BACKUP_FILE}': " | tee -a $BACKUP_LOG_FILE
	fi

	# copy the modified file to destination
	cp --parents "${line}" "${BACKUP_DIR}"

	# check outcome
	if [[ $? -ne 0 ]]; then
	    echo -e "${RED}failed!${NC}" | tee -a $BACKUP_LOG_FILE
	    FAILED=$((FAILED+1))
	else
	    echo -e "${GREEN}done!${NC}" | tee -a $BACKUP_LOG_FILE
	    COUNTER=$((COUNTER+1))
	fi
    else # backup is up-to-date

	# TODO: this and previous repeated statements should be more concise
	echo -e "Updating file '${BACKUP_FILE}': ${YELLOW}up-to-date${NC}" | tee -a $BACKUP_LOG_FILE
	SKIPPED=$((SKIPPED+1))
    fi
       
done < <(/usr/bin/find "${SOURCE_DIRS[@]}" -type f | sort -h) # eat it and beat it!

# getting the archaic syntax right
SUBJECT=$([[ $COUNTER == 1 ]] && echo "operation" || echo "operations")
echo   --- "${COUNTER}" "${SUBJECT}" succeeded. | tee -a $BACKUP_LOG_FILE
SUBJECT=$([[ $SKIPPED == 1 ]] && echo "operation" || echo "operations")
echo   --- "${SKIPPED}" "${SUBJECT}" skipped. | tee -a $BACKUP_LOG_FILE
SUBJECT=$([[ $FAILED == 1 ]] && echo "operation" || echo "operations")
echo   --- "${FAILED}" "${SUBJECT}" failed. | tee -a $BACKUP_LOG_FILE
SUBJECT=$([[ $CREATED == 1 ]] && echo "new file" || echo "new files")
echo   --- "${CREATED}" "${SUBJECT}" created. | tee -a $BACKUP_LOG_FILE

cp "${BACKUP_LOG_FILE}" "${BACKUP_DIR}"

echo -e "Backup $0-v${VERSION} process ${$} ${GREEN}completed${NC} at: $(date)" | tee -a $BACKUP_LOG_FILE

# Now or never ...

# All done!
echo done
