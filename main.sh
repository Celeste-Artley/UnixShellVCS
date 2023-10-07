#!/bin/bash
echo "1: initialize a new repository"
echo "2: Add files to be checked in"
echo "3: Commit files to repository"

read -p "Enter your choice: " choice

create_repository() {
  # Create a new directory for the repository
  mkdir "$1"
  # Create a sub-directory for the repository to keep committed changes
  mkdir "$1/repo"
  # Create a staging area for uncommitted changes
  mkdir "$1/staging"
}

add_files() {
  # pulls the repo path from stored info in local file.  
  repo_dir=$(read_repo_path)
  # code to add files to be commited
  cp "$1" "$repo_dir/staging/"
}

commit() {
  repo_dir=$(read_repo_path)  
  # Move files from staging area to repository
  mv "$repo_dir/staging/"* "$repo_dir/repo/"

  # Prompt for a commit message
  read -p "Enter a commit message: " commit_message

  # Log the commit message
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  log_entry="$timestamp - File checked in: $1. Commit message: $commit_message"
  write_log "$log_entry"
}

remove_files() {
  # code to copy file out for editing
  cp $1 $2
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

case $choice in
  1)
    read -p "Enter the name of the new repository: " repo_name
    create_repository "$repo_name"
    ;;
  2)
    read -p "Enter the source file: " source
    add_files "$source"
    ;;
  3)
    commit
    ;;
  *)
    echo "Invalid choice."
    ;;
esac