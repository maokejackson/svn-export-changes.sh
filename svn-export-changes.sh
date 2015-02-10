#!/bin/bash

if [ ! $1 ]; then
    echo "Please enter an SVN repository location"
    exit 1
fi

if [ ! $2 ]; then
    echo "Please enter an older directory in SVN"
    exit 1
fi

if [ ! $3 ]; then
    echo "Please enter a newer directory in SVN"
    exit 1
fi

# set up nice names for the incoming parameters to make the script more readable
repository=$1
dir_from=$2
dir_to=$3
target_directory=$4
change_log=$5

: ${target_directory:="export"}
: ${change_log:="change.log"}

path_from=$repository/$dir_from
path_to=$repository/$dir_to
path_log=$target_directory/$change_log

# the grep is needed so we only get added/modified files and not the deleted ones or anything else
# if it's a modified directory it's " M" so won't show with this command (good)
# if it's an added directory it's still "A" so will show with this command (not so good)

# clear out directory first
rm -R $target_directory

echo "\033[38;5;148mCleaning export directory\033[39m"

# Begin export
echo "\033[00;31mExporting files revised between $path_from and $path_to to /$target_directory\033[39m"

for line in `svn diff --summarize -r HEAD --old=$path_from --new=$path_to | grep "^[AM]"`
do
    # each line in the above command in the for loop is split into two:
    # 1) the status line (containing A, M, AM, D etc)
    # 2) the full repository and filename string
    # so only export the file when it's not the status line
    if [ $line != "A" ] && [ $line != "AM" ] && [ $line != "M" ]; then
        # replace with new location because svn diff shows the changes of old location
        repo_path=`echo "$line" |sed "s|$path_from|$path_to|g"`
        # use sed to remove the repository from the full repo and filename
        filename=`echo "$repo_path" | sed "s|$path_to||g"`
        # don't export if it's a directory we've already created
        file_path=`echo $target_directory$filename | sed "s|%20| |g"` # replace %20 with space
        if [ ! -d "$file_path" ]; then
            directory=`dirname "$filename" | sed "s|%20| |g"` # replace %20 with space
            mkdir -p "$target_directory$directory"
            echo "$filename"
            svn export -qr HEAD $repo_path "$file_path"
        fi
    fi
done

# create a change log indicating which files are added/modified/deleted
svn diff --summarize -r HEAD --old=$path_from --new=$path_to | sed "s|$path_from/||g" | sed 's/%20/ /g' > $path_log
echo "\033[38;5;148mChange log has been created at $path_log\033[39m"
