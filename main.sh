#!/bin/bash

create_repository() {
  if [ ! -d "staging" ]; then
    # Create a new directory for the repository
    mkdir "$1"
    # Create a sub-directory for the repository to keep committed changes
    mkdir "$1/repo"
    # Create a staging area for uncommitted changes
    mkdir "staging"
    #stores in a text file what the current repo's path is.
    write_repo_path "$1"
  else
    echo "Repo already Created"
  fi
}

add_files() {
  # pulls the repo path from stored info in local file.
  repo_dir=$(read_repo_path)
  
  # List files in the repository directory
  echo "Files in repository:"
  ls "$repo_dir/"
  
  # Read user input for file selection
  read -p "Enter the name of the file you want to add: " selected_file

  # Check if the selected file exists in the repository using the find property
  if [ -f "$repo_dir/$selected_file" ]; then
    # Add selected file to staging area
    cp "$repo_dir/$selected_file" "staging/"
    echo "File $selected_file has been added to staging area."
  else
    echo "File does not exist."
  fi
}

commit() {
  repo_dir=$(read_repo_path)  
  # Move files from staging area to repository
  mv "staging/"* "$repo_dir/repo/"

  # Delete all files in the staging area
  rm -f "staging/"*

  # Prompt for a commit message
  read -p "Enter a commit message: " commit_message

  # Log the commit message with the time 
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  log_entry="$timestamp Commit message: $commit_message"
  write_log "$log_entry"
}

write_log() {
  # code to write log
  echo "$1" >> log.txt
}

write_repo_path() {
  # Write the repo path to a file
  echo "$1" > repo_path.txt
}

read_repo_path() {
  # Read the repo path from a file
  cat repo_path.txt
}
while true; do
    echo "1: initialize a new repository"
    echo "2: Add files to be checked in"
    echo "3: Commit files to repository"
    echo "4: Exit"

    read -p "Enter your choice: " choice

    case $choice in
    1)
        read -p "Enter the name of the new repository: " repo_name
        create_repository "$repo_name"
        ;;
    2)
        add_files
        ;;
    3)
        commit
        ;;
    4)
      echo "Exiting..."
      break
      ;;
    *)
        echo "Invalid choice."
        ;;
    esac
done