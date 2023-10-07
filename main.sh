#!/bin/bash

#todo

# Create version number for commit or another command for version number
# Create version folders with current code after each commit.
# Create new diff log for each version of commit seqentually.
# Create a request for Username before commiting 

# Create a check-out and check-in method to make certain files avalable and not for editing. (currently it's just based on your project folder.) * the log-in is suppoed to log in should change the diff.log

#longterm todo - 
# Create multiple repos possible (this will interfear with the programs ablility to know if the repo has been created.)
# Implement robust input validation (started already)
# More complex file management such as file creation and secure deletion (Do this with the touch command in code to be able to log and track the new files created)

#Debug
# Check to see if you add files from subdirectories. Might need to list all files in all directories lower with an exception for the repo folder.

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
  # pulls the repo path from stored info in local file.
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

check_differences() {
  # pulls the repo path from stored info in local file.
  repo_dir=$(read_repo_path)
  
  # Loop through each file in the staging area
  for file in staging/*; do
    # Get the file name from the path (note, basename deletes any prefix that ends with a / used for the diff  output)
    file_name=$(basename "$file")

    # Check if this file exists in the repo
    if [ -f "$repo_dir/repo/$file_name" ]; then
      # Run diff command to compare the files and store that into the diff_output
      diff_output=$(diff "$file" "$repo_dir/repo/$file_name")
      
      # Check if diff_output is empty (i.e., the files are identical)
      if [ -z "$diff_output" ]; then
        log_entry="No differences in $file_name"
        # Write that there were no diffrences in the file
        write_diff_log "$log_entry"
      else
        # Write the diffrences found in the log about what was changed
        log_entry="Differences found in $file_name: $diff_output"
        write_diff_log "$log_entry"
      fi
    else
      #this catches a situation where the file has not been commited yet
      log_entry="$file_name exists in staging but not in repository."
      write_diff_log "$log_entry"
    fi
  done
}

write_log() {
  # code to write log
  echo "$1" >> log.txt
}
write_diff_log() {
  # Writes to difference log
  echo "$1" >> diff_log.txt
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
        check_differences
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