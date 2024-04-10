#!/bin/bash

# Function to extract DICOM tags
extract_tag() {
    local file="$1"
    local tag="$2"
    dcmdump "$file" | grep "$tag" | cut -d "[" -f 2 | cut -d "]" -f 1
}

is_dicom_file() {
    local file="$1"
    dcmdump "$file" >/dev/null 2>&1
    return $?
}

# Function to rename DICOM files
rename_dicom_files() {
    local directory="$1"
    local dest="$2"
    local SAFE=0

    # Loop through DICOM files in the directory
    for entry in "$directory"/*; do
        if [ -f "$entry" ]; then

            if is_dicom_file "$entry"; then
                # Extract DICOM tags
                patient_id=$(extract_tag "$entry" "0010,0020")
                patient_name=$(extract_tag "$entry" "0010,0010")
                if [ $SAFE -eq 1 ]; then
                    study_level=$(extract_tag "$entry" "0020,000d")
                    series_level=$(extract_tag "$entry" "0020,000e")
                    image_name=$(extract_tag "$entry" "0008,0018")
                else
                    study_id=$(extract_tag "$entry" "0020,0010")
                    study_date=$(extract_tag "$entry" "0008,0020")
                    series_desc=$(extract_tag "$entry" "0008,103e")
                    series_num=$(extract_tag "$entry" "0020,0011")
                    instance_num=$(extract_tag "$entry" "0020,0013")
                    #
                    study_level="$study_date-$study_id"
                    series_level="SE$series_num-$series_desc"
                    #
                    padded_senum=$(printf "%05d" "$series_num")
                    padded_inum=$(printf "%05d" "$instance_num")
                    image_name="IM-$padded_senum-$padded_inum"
                fi


                # Clean strings:
                patient_id="${patient_id// /_}"
                patient_id="${patient_id//^/_}"
                patient_name="${patient_name// /_}"
                patient_name="${patient_name//^/_}"
                study_level="${study_level// /_}"
                series_level="${series_level// /_}"
                image_name="${image_name// /_}"

                # Create directory structure
                top_level="$patient_id-$patient_name"
                mkdir -p "$dest/$top_level/$study_level/$series_level"

                # Rename DICOM file
                mv "$entry" "$dest/$top_level/$study_level/$series_level/$image_name.dcm"
            fi
        elif [ -d "$entry" ]; then
            echo "Processing directory: $entry"
            # Recursive call to loop_through_subdirectories for the subdirectory
            rename_dicom_files "$entry" "$dest" 
        
        fi

    done
}

# Main script starts here

# Check if the directory is provided as an argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <src_directory> <dest_directory>"
    exit 1
fi

# Specify the directory containing DICOM files
root_directory="$1"
dest_directory="$2"

# Call the function to rename DICOM files
rename_dicom_files "$root_directory" "$dest_directory"
