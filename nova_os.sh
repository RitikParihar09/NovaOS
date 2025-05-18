#!/bin/bash

# Nova OS Shell Simulator
# This script simulates a simple OS that uses a real folder for storage

# Set up variables
STORAGE_DIR="storage"
CURRENT_DIR="/"
LOGGED_IN=false
USERNAME=""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to display the banner
show_banner() {
    clear
    echo "+------------------------+"
    echo "|      NOVA OS v1.0      |"
    echo "|   Alpha Coders Team    |"
    echo "+------------------------+"
}

# Function to handle login
login() {
    show_banner
    echo ""
    echo "NOVA OS LOGIN"
    echo ""
    
    read -p "Username: " input_username
    read -s -p "Password: " input_password
    echo ""
    
    # Simple authentication (in a real system, this would be more secure)
    if [ "$input_username" == "admin" ] && [ "$input_password" == "password" ]; then
        echo -e "${GREEN}Login successful! Welcome to Nova OS.${NC}"
        sleep 1
        USERNAME=$input_username
        LOGGED_IN=true
        return 0
    else
        echo -e "${RED}Invalid username or password. Please try again.${NC}"
        sleep 2
        return 1
    fi
}

# Function to convert OS path to storage path
get_storage_path() {
    local os_path=$1
    
    # Handle root directory
    if [ "$os_path" == "/" ]; then
        echo "$STORAGE_DIR"
        return
    fi
    
    # Remove leading slash and append to storage dir
    os_path="${os_path#/}"
    echo "$STORAGE_DIR/$os_path"
}

# Function to convert storage path to OS path
get_os_path() {
    local storage_path=$1
    
    # Remove storage dir prefix
    os_path="${storage_path#$STORAGE_DIR}"
    
    # If empty, it's the root
    if [ -z "$os_path" ]; then
        echo "/"
        return
    fi
    
    # Ensure leading slash
    if [[ "$os_path" != /* ]]; then
        os_path="/$os_path"
    fi
    
    echo "$os_path"
}

# Function to list files and directories
list_directory() {
    local storage_path=$(get_storage_path "$CURRENT_DIR")
    
    echo -e "${BLUE}Contents of $CURRENT_DIR:${NC}"
    
    # List directories first
    for dir in "$storage_path"/*/; do
        if [ -d "$dir" ]; then
            dir_name=$(basename "$dir")
            echo -e "${YELLOW}[DIR]  $dir_name${NC}"
        fi
    done
    
    # Then list files
    for file in "$storage_path"/*; do
        if [ -f "$file" ]; then
            file_name=$(basename "$file")
            echo -e "[FILE] $file_name"
        fi
    done
}

# Function to change directory
change_directory() {
    local target_dir=$1
    
    # Handle empty input
    if [ -z "$target_dir" ]; then
        echo "Usage: cd <directory>"
        return 1
    fi
    
    # Handle special cases
    if [ "$target_dir" == "/" ]; then
        CURRENT_DIR="/"
        return 0
    fi
    
    # Handle parent directory
    if [ "$target_dir" == ".." ]; then
        if [ "$CURRENT_DIR" == "/" ]; then
            return 0
        fi
        
        # Remove trailing slash if present
        CURRENT_DIR="${CURRENT_DIR%/}"
        
        # Remove last directory component
        CURRENT_DIR=$(dirname "$CURRENT_DIR")
        
        # Ensure root directory has just a slash
        if [ "$CURRENT_DIR" == "." ]; then
            CURRENT_DIR="/"
        fi
        
        return 0
    fi
    
    # Handle absolute paths
    if [[ "$target_dir" == /* ]]; then
        local storage_path=$(get_storage_path "$target_dir")
        
        if [ -d "$storage_path" ]; then
            CURRENT_DIR="$target_dir"
            return 0
        else
            echo -e "${RED}Directory not found: $target_dir${NC}"
            return 1
        fi
    fi
    
    # Handle relative paths
    local new_dir
    if [ "$CURRENT_DIR" == "/" ]; then
        new_dir="/$target_dir"
    else
        new_dir="$CURRENT_DIR/$target_dir"
    fi
    
    local storage_path=$(get_storage_path "$new_dir")
    
    if [ -d "$storage_path" ]; then
        CURRENT_DIR="$new_dir"
        return 0
    else
        echo -e "${RED}Directory not found: $target_dir${NC}"
        return 1
    fi
}

# Function to display file contents
cat_file() {
    local filename=$1
    
    # Handle empty input
    if [ -z "$filename" ]; then
        echo "Usage: cat <filename>"
        return 1
    fi
    
    # Handle absolute paths
    if [[ "$filename" == /* ]]; then
        local storage_path=$(get_storage_path "$filename")
        
        if [ -f "$storage_path" ]; then
            echo -e "${BLUE}Contents of $filename:${NC}"
            cat "$storage_path"
            return 0
        else
            echo -e "${RED}File not found: $filename${NC}"
            return 1
        fi
    fi
    
    # Handle relative paths
    local file_path
    if [ "$CURRENT_DIR" == "/" ]; then
        file_path="/$filename"
    else
        file_path="$CURRENT_DIR/$filename"
    fi
    
    local storage_path=$(get_storage_path "$file_path")
    
    if [ -f "$storage_path" ]; then
        echo -e "${BLUE}Contents of $filename:${NC}"
        cat "$storage_path"
        return 0
    else
        echo -e "${RED}File not found: $filename${NC}"
        return 1
    fi
}

# Function to create a directory
make_directory() {
    local dirname=$1
    
    # Handle empty input
    if [ -z "$dirname" ]; then
        echo "Usage: mkdir <directory>"
        return 1
    fi
    
    # Handle absolute paths
    if [[ "$dirname" == /* ]]; then
        local storage_path=$(get_storage_path "$dirname")
        
        if [ -e "$storage_path" ]; then
            echo -e "${RED}Error: $dirname already exists${NC}"
            return 1
        else
            mkdir -p "$storage_path"
            echo "Directory created: $dirname"
            return 0
        fi
    fi
    
    # Handle relative paths
    local dir_path
    if [ "$CURRENT_DIR" == "/" ]; then
        dir_path="/$dirname"
    else
        dir_path="$CURRENT_DIR/$dirname"
    fi
    
    local storage_path=$(get_storage_path "$dir_path")
    
    if [ -e "$storage_path" ]; then
        echo -e "${RED}Error: $dirname already exists${NC}"
        return 1
    else
        mkdir -p "$storage_path"
        echo "Directory created: $dirname"
        return 0
    fi
}

# Function to create an empty file
touch_file() {
    local filename=$1
    
    # Handle empty input
    if [ -z "$filename" ]; then
        echo "Usage: touch <filename>"
        return 1
    fi
    
    # Handle absolute paths
    if [[ "$filename" == /* ]]; then
        local storage_path=$(get_storage_path "$filename")
        
        if [ -e "$storage_path" ]; then
            echo -e "${RED}Error: $filename already exists${NC}"
            return 1
        else
            touch "$storage_path"
            echo "File created: $filename"
            return 0
        fi
    fi
    
    # Handle relative paths
    local file_path
    if [ "$CURRENT_DIR" == "/" ]; then
        file_path="/$filename"
    else
        file_path="$CURRENT_DIR/$filename"
    fi
    
    local storage_path=$(get_storage_path "$file_path")
    
    if [ -e "$storage_path" ]; then
        echo -e "${RED}Error: $filename already exists${NC}"
        return 1
    else
        touch "$storage_path"
        echo "File created: $filename"
        return 0
    fi
}

# Function to remove a file or directory
remove_item() {
    local item=$1
    
    # Handle empty input
    if [ -z "$item" ]; then
        echo "Usage: rm <file/directory>"
        return 1
    fi
    
    # Handle absolute paths
    if [[ "$item" == /* ]]; then
        local storage_path=$(get_storage_path "$item")
        
        if [ ! -e "$storage_path" ]; then
            echo -e "${RED}Error: $item does not exist${NC}"
            return 1
        else
            rm -rf "$storage_path"
            echo "Removed: $item"
            return 0
        fi
    fi
    
    # Handle relative paths
    local item_path
    if [ "$CURRENT_DIR" == "/" ]; then
        item_path="/$item"
    else
        item_path="$CURRENT_DIR/$item"
    fi
    
    local storage_path=$(get_storage_path "$item_path")
    
    if [ ! -e "$storage_path" ]; then
        echo -e "${RED}Error: $item does not exist${NC}"
        return 1
    else
        rm -rf "$storage_path"
        echo "Removed: $item"
        return 0
    fi
}

# Function to print working directory
print_working_directory() {
    echo "$CURRENT_DIR"
}

# Function to write to a file
write_to_file() {
    local filename=$1
    
    # Handle empty input
    if [ -z "$filename" ]; then
        echo "Usage: write <filename>"
        return 1
    fi
    
    # Determine file path
    local file_path
    if [[ "$filename" == /* ]]; then
        file_path="$filename"
    else
        if [ "$CURRENT_DIR" == "/" ]; then
            file_path="/$filename"
        else
            file_path="$CURRENT_DIR/$filename"
        fi
    fi
    
    local storage_path=$(get_storage_path "$file_path")
    
    echo "Enter file content (type 'EOF' on a new line to finish):"
    local content=""
    local line=""
    
    while true; do
        read line
        if [ "$line" == "EOF" ]; then
            break
        fi
        content="$content$line"$'\n'
    done
    
    echo -n "$content" > "$storage_path"
    echo "File written: $filename"
}

# Function to echo text to the screen
echo_text() {
    echo "$@"
}

# Function to copy a file
copy_file() {
    local source=$1
    local destination=$2
    
    # Handle empty input
    if [ -z "$source" ] || [ -z "$destination" ]; then
        echo "Usage: cp <source> <destination>"
        return 1
    fi
    
    # Handle absolute paths for source
    local source_path
    if [[ "$source" == /* ]]; then
        source_path=$(get_storage_path "$source")
    else
        if [ "$CURRENT_DIR" == "/" ]; then
            source_path=$(get_storage_path "/$source")
        else
            source_path=$(get_storage_path "$CURRENT_DIR/$source")
        fi
    fi
    
    # Check if source exists
    if [ ! -f "$source_path" ]; then
        echo -e "${RED}Error: Source file not found: $source${NC}"
        return 1
    fi
    
    # Handle absolute paths for destination
    local dest_path
    if [[ "$destination" == /* ]]; then
        dest_path=$(get_storage_path "$destination")
    else
        if [ "$CURRENT_DIR" == "/" ]; then
            dest_path=$(get_storage_path "/$destination")
        else
            dest_path=$(get_storage_path "$CURRENT_DIR/$destination")
        fi
    fi
    
    # If destination is a directory, copy the file into that directory
    if [ -d "$dest_path" ]; then
        local source_filename=$(basename "$source")
        dest_path="$dest_path/$source_filename"
    fi
    
    # Copy the file
    cp "$source_path" "$dest_path"
    echo "File copied: $source -> $destination"
    return 0
}

# Function to display version information
show_version() {
    echo -e "${BLUE}Nova OS v1.0${NC}"
    echo "Developed by Alpha Coders Team"
    echo "Copyright © 2023"
}

# Function to display current date and time
show_date() {
    echo -e "${BLUE}Current System Date and Time:${NC}"
    date
}

# Function to simulate reboot
reboot_system() {
    echo "Rebooting Nova OS..."
    sleep 1
    echo "Shutting down services..."
    sleep 1
    echo "Restarting system..."
    sleep 2
    
    # Clear screen and restart the OS (simulated by restarting the script)
    clear
    exec "$0"
}

# Function to display help
show_help() {
    echo -e "${BLUE}Available commands:${NC}"
    echo "  help     - Display this help message"
    echo "  ls       - List files and directories"
    echo "  cd       - Change directory"
    echo "  pwd      - Print working directory"
    echo "  cat      - Display file contents"
    echo "  mkdir    - Create a directory"
    echo "  touch    - Create an empty file"
    echo "  write    - Write content to a file"
    echo "  rm       - Remove a file or directory"
    echo "  echo     - Display a line of text"
    echo "  cp       - Copy a file to another location"
    echo "  version  - Display OS version and author information"
    echo "  date     - Display current system date and time"
    echo "  reboot   - Reboot the system"
    echo "  clear    - Clear the screen"
    echo "  logout   - Log out"
    echo "  shutdown - Exit the OS"
}

# Main function
main() {
    # Ensure storage directory exists
    if [ ! -d "$STORAGE_DIR" ]; then
        mkdir -p "$STORAGE_DIR"
        mkdir -p "$STORAGE_DIR/bin"
        mkdir -p "$STORAGE_DIR/home"
        mkdir -p "$STORAGE_DIR/home/admin"
        echo "Welcome to Nova OS!" > "$STORAGE_DIR/home/admin/welcome.txt"
    fi
    
    # Show banner and login
    while ! $LOGGED_IN; do
        login
    done
    
    # Main OS loop
    clear
    echo "+------------------------+"
    echo "|      NOVA OS v1.0      |"
    echo "|   Alpha Coders Team    |"
    echo "+------------------------+"
    echo "successful login to novaos"
    echo -e "${GREEN}Welcome to Nova OS v1.0${NC}"
    
    while true; do
        echo -ne "novaos> "
        read -e command args
        
        case "$command" in
            "help")
                show_help
                ;;
            "ls")
                list_directory
                ;;
            "cd")
                change_directory "$args"
                ;;
            "pwd")
                print_working_directory
                ;;
            "cat")
                cat_file "$args"
                ;;
            "mkdir")
                make_directory "$args"
                ;;
            "touch")
                touch_file "$args"
                ;;
            "write")
                write_to_file "$args"
                ;;
            "rm")
                remove_item "$args"
                ;;
            "echo")
                echo_text $args
                ;;
            "cp")
                # Split args into source and destination
                read -r src dest <<< "$args"
                copy_file "$src" "$dest"
                ;;
            "version")
                show_version
                ;;
            "date")
                show_date
                ;;
            "reboot")
                reboot_system
                ;;
            "clear")
                clear
                echo -e "${GREEN}Welcome to Nova OS v1.0${NC}"
                ;;
            "logout")
                LOGGED_IN=false
                USERNAME=""
                echo "Logging out..."
                sleep 1
                while ! $LOGGED_IN; do
                    login
                done
                clear
                echo "+------------------------+"
                echo "|      NOVA OS v1.0      |"
                echo "|   Alpha Coders Team    |"
                echo "+------------------------+"
                echo "successful login to novaos"
                echo -e "${GREEN}Welcome to Nova OS v1.0${NC}"
                ;;
            "shutdown")
                echo "Shutting down Nova OS..."
                sleep 1
                exit 0
                ;;
            "")
                # Do nothing for empty command
                ;;
            *)
                echo -e "${RED}Unknown command: $command${NC}"
                echo "Type 'help' for available commands."
                ;;
        esac
    done
}

# Start the OS
main