#####VARIABLE SETUP######
#########################
##RESTART WARNING TIME###
#WARNINGS are in minutes
#FINAL is in seconds
#FIRST WARNING###########
FIRST=30
#SECOND WARNING##########
SECOND=10
#THIRD WARNING###########
THIRD=2
#SECONDS BEFORE RESTART##
FINAL_WARNING_TIME=10
#TRACKER FILE VARIABLES##
##TRACKER FILE NAME
TRACKER_FILE_NAME="tracker.txt"
##TRACKER FILE PATH
TRACKER_FILE_DIR="/root/minecraft-backups/da-boyz-backup/$TRACKER_FILE_NAME"
#WORLD FILE SAVE#########
##WORLD_NAME#############
WORLD_NAME="da-boyz-"
##SPLIT_CHAR#############
SPLITCHAR="-"
##BACKUP SAVE DIR########
BACKUP_DIR_PATH="/root/minecraft-backups/da-boyz-backup/"
#####DOCKER INFO#########
##DOCKER CONTAINER NAME##
DOCKER_NAME="minecraft-da-boyz"

warning_message(){
    local TIME=$1
    local MsgTime=$2
    docker exec ${DOCKER_NAME} rcon-cli say Server Restarting in ${MsgTime} Minutes
    SLEEP_TIME=$((TIME * 60))
sleep ${SLEEP_TIME}
}
# Calculate actual times
F=$((FIRST - SECOND - THIRD))
S=$((SECOND - THIRD))
T=${THIRD}  # Direct assignment, as THIRD is already a single value
# Send the warning messages
#first warning
warning_message ${F} ${FIRST}
#second warning
warning_message ${S} ${SECOND}
#third warning
warning_message ${T} ${THIRD}

# sudo systemctl stop my-server.service
docker exec ${DOCKER_NAME} rcon-cli say Server Restarting in ${WARNING_TIME} seconds...
sleep ${WARNING_TIME}

docker exec minecraft-da-boyz rcon-cli stop
sleep 10

#Function to delete the 8th file from the tracker
#used to save storage space
delete_eighth_file() {
    # Check if the tracker file exists
    if [[ ! -f "$TRACKER_FILE" ]]; then
        echo "Tracker file does not exist."
        return 1
    fi

    # Read the 8th line of the tracker file
    FILE_TO_DELETE=$(sed -n '8p' "$TRACKER_FILE")

    # Check if the file was actually found
    if [[ -z "$FILE_TO_DELETE" ]]; then
        echo "No 8th file to delete or file list is shorter than 8."
        return 1
    fi

    # Full path to the file
    FULL_PATH_TO_DELETE="${FILE_TO_DELETE}"

    # Delete the file if it exists
    if [[ -f "$FULL_PATH_TO_DELETE" ]]; then
        rm "$FULL_PATH_TO_DELETE"
        echo "Deleted: $FULL_PATH_TO_DELETE"
    else
        echo "File to delete not found: $FULL_PATH_TO_DELETE"
        return 1
    fi

    # Remove the 8th line from the tracker file
    sed -i '8d' "$TRACKER_FILE"
    echo "Removed 8th entry from tracker file."
}


#add a world backup area 
# Backup the world folder - adjust the internal path as necessary


TIMESTAMP=$(date +"%d$SPLITCHAR%m$SPLITCHAR%Y_%H-%M")

# Define the full path for the backup
BACKUP="${BACKUP_DIR_PATH}${WORLD_NAME}${TIMESTAMP}"

# Copy the Minecraft world data to the backup directory
docker cp ${DOCKER_NAME}:/data/world $BACKUP

# Create a tar file of the world
tar -czvf "${BACKUP}.tar.gz" -C "${BACKUP_DIR_PATH}" "${WORLD_NAME}${TIMESTAMP}"

# Remove the copied world folder after backup
rm -rf "$BACKUP"

# Manage tracking of backups
TRACKER_FILE="${BACKUP_DIR_PATH}tracker.txt"
touch "$TRACKER_FILE"

# Prepend the backup log to the tracker file
echo "${BACKUP}.tar.gz"$'\n'"$(cat "$TRACKER_FILE")" > "$TRACKER_FILE"


#delete the 8th file
delete_eighth_file

sleep 5
