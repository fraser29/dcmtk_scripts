#!/bin/bash

###############################################################################
# DICOM File Modifier Script
###############################################################################

# Script Overview:
# The script recursively modifies DICOM files found within a specified root directory (given as first argument).
# It replaces UID tags with generated UIDs for the entire study and replaces tags from a supplied list with empty values.
# NOTE: Expects to anonymise only a single study

# Functions:
#   generate_uid():

#       Generates a new UID using DCMTK's dcmuid tool.

#   modify_dicom_files(directory, empty_tags_list):

#       Recursively modifies DICOM files within the specified directory.
#       Replaces UID tags (0020,000d) and (0020,000e) with generated UIDs for the entire study.
#       Replaces tags listed in empty_tags_list with empty values.

#   Main Script:
#       Specifies the root directory containing DICOM files (root_directory).
#       Specifies the path to the list of tags to be emptied (empty_tags_list).
#       Calls the modify_dicom_files function with the specified arguments to begin the modification process.

# Usage:
#   Replace "/path/to/your/root/directory" with the path to the root directory containing DICOM files.
#   Replace "/path/to/your/empty_tags_list.txt" with the path to a text file containing the list of tags to be emptied. Each tag should be specified in DICOM tag format (e.g., (0010,0010)).
#   Ensure DCMTK is installed and available in your system's PATH for the script to work correctly. Additionally, grant executable permissions to the script using chmod +x anonymisation.sh.

# Recursively loop through dicoms found under 


is_dicom_file() {
    local file="$1"
    dcmdump "$file" >/dev/null 2>&1
    return $?
}

# Function to recursively modify DICOM files
modify_dicom_files() {
    local directory="$1"
    local study_uid_tag="$2"
    local empty_tags_list="$3"

    # Loop through DICOM files in the directory
    seriesUID=$(uuidgen)
    for file in "$directory"/*; do

        if [ -f "$file" ]; then

            if is_dicom_file "$file"; then

                echo "$file"
                # Replace UID tags with generated UID for the entire study
                new_SOPI_UID=$(uuidgen)
                dcmodify -i "(0020,000d)=$study_uid_tag" -i "(0020,000e)=$seriesUID" -i "(0008,0018)=$new_SOPI_UID" "$file"

                # # Replace tags from the supplied list with empty values
                # for tag in "${empty_tags_list[@]}"; do
                #     dcmodify -i "$tag=" "$file"
                # done
            fi
        fi
    done

    # Recursively call the function for subdirectories
    # for subdir in "$directory"/*/; do
    #     modify_dicom_files "$subdir" "$study_uid_tag" "$empty_tags_list"
    # done
}

###############################################################################
# MAIN Script
###############################################################################

# Check if the root directory is provided as an argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <root_directory>"
    exit 1
fi
# Specify the root directory
root_directory="$1"

# Specify the list of tags to replace with empty values
empty_tags_list=(
    "(0010,0010)"
    "(0010,0020)"
    "(0010,0030)"
    # Add more tags as needed
)

# Call the function to recursively modify DICOM files
modify_dicom_files "$root_directory" $(uuidgen) "$empty_tags_list"
