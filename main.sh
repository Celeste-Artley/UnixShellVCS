#!/bin/bash

#todo

# Create version number for commit or another command for version number (done)
# Create version folders with current code after each commit. (done)
# Create new diff log for each version of commit seqentually. (done)

#currently working on -------
# Create a request for Username before commiting 

# Create a check-out and check-in method to make certain files avalable and not for editing. (currently it's just based on your project folder.) 
# ^ this kind of works but there could be a permitions like CHMOD or -rwxr--rw- done to the files to make them uneditable until checked out. that might be what they are looking for.

#longterm todo - 
# Create multiple repos possible (this will interfear with the programs ablility to know if the repo has been created.)
# Implement robust input validation (started already)
# More complex file management such as file creation and secure deletion (Do this with the touch command in code to be able to log and track the new files created)

#Debug
# Check to see if you add files from subdirectories. Might need to list all files in all directories lower with an exception for the repo folder.

current_repo=""

create_repository() {
  if [ ! -d "staging" ]; then
    # Create a new directory for the repository
    mkdir "$1"
    # Create a sub-directory for the repository to keep committed changes
    mkdir "$1/repo"
    # Create a staging area for uncommitted changes
    mkdir "$1/staging"

    mkdir "$1/editing"
    #stores in a text file what the current repo's path is.
    current_repo="$1"
    echo -e "\nRepo suscessfully create."
  else
    echo -e "\nRepo already Created"
  fi
}

select_repository(){
  #show all repos
  echo -e "\nAvailable repositories: "
  for dir in */; do
    if [ -d "$dir" ]; then
      echo "$dir"
    fi
  done

  echo -e "\n"

  #get repo name
  read -p "Enter the name of the repository you want to work with" repo_name
  if [ -d "$repo_name" ]; then
    #set current_repo to selected
    current_repo="$repo_name"
    echo -e "\nRepository selected: $current_repo"
  else
    echo -e "\nRepository does not exist."
  fi
}

add_files() {
  # checks current repo
  if [ -z "$current_repo" ]; then
    echo "No repository selected. Please select a repository first."
    return
  fi
  
  # List files in the repository directory
  echo -e "\nFiles in repository:"
  ls "$current_repo/"
  
  # Read user input for file selection
  read -p "Enter the name of the file you want to add: " selected_file

  # Check if the selected file exists in the repository using the find property
  if [ -f "$current_repo/$selected_file" ]; then
    # Add selected file to staging area
    mv "$current_repo/$selected_file" "$current_repo/editing/"
    echo -e "\nFile $selected_file has been added to editing area."
  else
    echo -e "\nFile does not exist."
  fi
}

checkout() {
  # checks current repo
  if [ -z "$current_repo" ]; then
    echo "No repository selected. Please select a repository first."
    return
  fi

  # Get the most recent commit number (next commit - 1)
  next_commit=$(get_next_commit_number)
  latest_commit=$((next_commit - 1))
  latest_commit_dir="$current_repo/repo/$latest_commit"

  # Check if the latest commit directory exists
  if [ ! -d "$latest_commit_dir" ]; then
    echo "No commits available to check out."
    return 1  # Exit the function with an error status
  fi

  # List all files in the most recent commit
  echo "Files in the most recent commit ($latest_commit):"
  ls "$latest_commit_dir"

  # Prompt the user to enter a file name to check out
  read -p "Enter file name to check out: " file_name

  file_path="$latest_commit_dir/$file_name"

  #allow editing of file
  chmod +w $file_path

  # Check if the selected file exists in the latest commit
  if [ ! -f "$file_path" ]; then
    echo "File $file_name does not exist in the most recent commit."
    return 1  # Exit the function with an error status
  fi

  # Copy the selected file to the working directory
  cp "$file_path" "$current_repo/editing"  # Assuming you want to copy to the current directory
}



checkin(){
  # checks current repo
  if [ -z "$current_repo" ]; then
    echo "No repository selected. Please select a repository first."
    return
  fi

  #show all files in editing
  echo -e "\nFiles in editing: "
  ls "$current_repo/editing"

  read -p "Enter file to checkin: " file_to_checkin

  #move editing to staging
  if [ -f "$current_repo/editing/$file_to_checkin" ]; then
    mv "$current_repo/editing/$file_to_checkin" "$current_repo/staging/"
    chmod -w $current_repo/staging/$file_to_checkin
    echo -e "\nFile checked in"
  else 
    echo -e "\nFile does not exist"
  fi
}

commit() {
  # checks current repo
  if [ -z "$current_repo" ]; then
    echo "No repository selected. Please select a repository first."
    return
  fi
  
  # Get the next commit number
  commit_number=$(get_next_commit_number)
  
  # Create a new directory for this commit
  commit_dir="$current_repo/repo/$commit_number"
  mkdir -p "$commit_dir"

  # Move files from staging area to this commit's directory
  mv "$current_repo/staging/"* "$commit_dir/"

  # Delete all files in the staging area
  rm -f "$current_repo/staging/"*

  #Prompt for getting username
  read -p "Enter username: " username

  # Prompt for a commit message
  read -p "Enter a commit message: " commit_message

  # Log the commit message with the time
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  log_entry="$commit_number: $timestamp: User: $username , Commit message: $commit_message"
  write_log "$log_entry"
  mv "$current_repo"/changelog.txt "$current_repo"/repo/"$commit_number"
}


get_next_commit_number(){
  # checks current repo
  if [ -z "$current_repo" ]; then
    echo "No repository selected. Please select a repository first."
    return
  fi
  if [ -f "$current_repo/log.txt" ]; then
    last_line=$(tail -n 1 "$current_repo/log.txt")
    number=$(echo "$last_line" | awk -F':' '{print $1}')
    let "number++"
    echo $number
  else
    echo "1"
  fi
}

check_differences() {
  # checks current repo
  if [ -z "$current_repo" ]; then
    echo "No repository selected. Please select a repository first."
    return
  fi
  
  # Loop through each file in the staging area
  for file in staging/*; do
    # Get the file name from the path (note, basename deletes any prefix that ends with a / used for the diff  output)
    file_name=$(basename "$file")

    # Check if this file exists in the repo
    if [ -f "$current_repo/repo/$file_name" ]; then
      # Run diff command to compare the files and store that into the diff_output
      diff_output=$(diff "$file" "$current_repo/repo/$file_name")
      
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
  # checks current repo
  if [ -z "$current_repo" ]; then
    echo "No repository selected. Please select a repository first."
    return
  fi
  # code to write log
  echo "$1" >> "$current_repo/log.txt"
}
write_diff_log() {
  # Writes to difference log
  echo "$1" >> diff_log.txt
}

track_changes() {
  # checks current repo
  if [ -z "$current_repo" ]; then
    echo "No repository selected. Please select a repository first."
    return
  fi
  
  next_commit=$(get_next_commit_number)
  last_commit=$((next_commit - 1))

  staging_dir="$current_repo/staging"
  
  # Check if the staging area exists and is not empty
  if [ -z "$(ls -A "$staging_dir")" ]; then
    echo "No files in staging."
    return  # Exit the function
  fi
  
  # Loop through each file in the staging area
  for file in "$staging_dir"/*; do
    file_name=$(basename "$file")
    
    # Check if this file exists in the last commit
    if [ -f "$current_repo/repo/$last_commit/$file_name" ]; then
      # Run diff command to compare the files and store that into diff_output
      diff_output=$(diff "$file" "$current_repo/repo/$last_commit/$file_name")
      
      # Check if diff_output is empty (i.e., the files are identical)
      if [ -z "$diff_output" ]; then
        log_entry="No differences in $file_name"
      else
        # Log the differences
        log_entry="Differences found in $file_name: $diff_output"
      fi
    else
      # File is new, so log that
      log_entry="New file $file_name added"
    fi
    
    # Write the log entry to changelog.txt in the repository root
    echo "$log_entry" >> "$current_repo/changelog.txt"
  done
}



while true; do
    echo "1: Initialize a new repository"
    if [ -z "$current_repo" ]; then
      echo "2: Select current repository (no repo selected)"
    else
      echo "2: Select current repository (currently: $current_repo )"
    fi
    echo "3: Add files to repo to edit"
    echo "4: Commit files to repository"
    echo "5: Check out file for edit"
    echo "6: Check in file"
    echo -e "7: Exit\n"

    read -p "Enter your choice: " choice

    clear

    case $choice in
    1)
        read -p "Enter the name of the new repository: " repo_name
        create_repository "$repo_name"
        clear
        ;;
    2)
        select_repository
        ;;
    3)
        add_files
        clear
        ;;
    4)
        track_changes
        commit
        ;;
    5)
        checkout
        ;;
    6)
        checkin
        ;;
    7)
      echo -e "\nExiting..."
      break
      ;;
    *)
        echo -e "\nInvalid choice."
        ;;
    esac
done