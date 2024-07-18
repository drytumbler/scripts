#!/usr/bin/env bash
VERSION="0.0.1-1beta"
SOURCE_DIRS=( "docs" ".bashrc" "garblegob")

BACKUP_DIR="/mnt/BACKUP"
BACKUP_LOG_FILE="$HOME/.backup.log"

# Define the red color and reset color
RED=$(printf "\033[31m")
GREEN=$(printf "\033[32m")
YELLOW=$(printf "\033[33m")
NC='\033[0m' # No Color (std)

# SOURCE should not contain DESTINATION! --- TODO

# expand/compose filenames correctly so $BACKUP_DIR/ represents /root

# Don't exit loop on first error, log and continue --- TODO

# check if files are realy created or don't increment, failed is printed, but files are counted as created

# Ensure safety!!! runs as root

# Implement -v --verbose -d --dry-run options

# other usefull options? new only, existing only, check all/only existing in BACKUP_DIR ...

# register backup attempt  --- TODO
touch $BACKUP_LOG_FILE

# exclude pattern --- TODO
EXCLUDE=""

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi


# check output directory
if [[ ! -d ${BACKUP_DIR} ]]; then
	echo -e "$RED error: '${BACKUP_DIR}' is not a valid directory $NC"
	exit 2
fi

TOTAL_FILES=0
TOTAL_DIRS=0

for entry in ${SOURCE_DIRS[@]}; do
    TOTAL_DIRS=$(echo $([[ -d ${entry} ]] && echo $((TOTAL_DIRS + 1)) || echo "${TOTAL_DIRS}"))
    TOTAL_FILES=$(echo $(($(echo $((find ${entry} -type f -exec ls -l {} +) | wc -l) + TOTAL_FILES))))
done

echo TOTAL_DIRS FOUND: "${TOTAL_DIRS}"
echo TOTAL_FILES FOUND: "${TOTAL_FILES}"
echo
echo -e "${RED}PROGRAM LIVE: PROCEED WITH CAUTION!${NC}"
echo
echo -n "> Backup files to '${BACKUP_DIR}'? [y/N] "
read -r response

if ! [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
	echo -e "$RED error: aborted by user $NC"
	exit 0
fi


echo 
echo -e "Backup $0-v${VERSION} process ${$} ${GREEN}started${NC} at: $(date)" | tee -a $BACKUP_LOG_FILE

COUNTER=0
FAILED=0
CREATED=0
SKIPPED=0

### begin array elements loop

while IFS= read -r line; do
    # find the file in the backup directory
    #  |
    #   ---> compare the modification date
    #            |
    #             ---> skip if not older
    # copy the file
    
    BACKUP_FILE="${BACKUP_DIR}/${line}"
    if ! [[ -f ${line} ]]; then
	echo -e "${RED} error: input error${NC}"
	echo -e "${line}"
	exit 3
    fi
    
    if [[ ${line} -nt ${BACKUP_FILE} ]]; then
	if ! [[ -f ${BACKUP_FILE}  ]]; then
	    echo -ne "Creating new file '${BACKUP_FILE}': " | tee -a $BACKUP_LOG_FILE
	    touch -d "" "${BACKUP_FILE}"
	    CREATED=$((CREATED+1))
	else
	    echo -ne "Updating file '${BACKUP_FILE}': " | tee -a $BACKUP_LOG_FILE
	fi
	cp --parents "${line}" "${BACKUP_DIR}"
	if [[ $? -ne 0 ]]; then
	    echo -e "${RED}failed!${NC}" | tee -a $BACKUP_LOG_FILE
	    FAILED=$((FAILED+1))
	else
	    echo -e "${GREEN}done!${NC}" | tee -a $BACKUP_LOG_FILE
	    COUNTER=$((COUNTER+1))
	fi
    else
	echo -e "Updating file '${BACKUP_FILE}': ${YELLOW}up-to-date${NC}" | tee -a $BACKUP_LOG_FILE
	SKIPPED=$((SKIPPED+1))
    fi
       
done < <(/usr/bin/find "${SOURCE_DIRS[@]}" -type f | sort -h)

### end array elements loop

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
echo done
