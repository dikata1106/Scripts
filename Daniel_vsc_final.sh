#!/bin/bash

# https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html

# Usage instructions
USAGE_TEXT="Usage: -w <workspace directory> -k <kernel directory> -o <out directory>"
# Helper text separator and delimeter character markers
L0="0"
L1="4"
L2="8"
L3="12"
L4="16"
L5="20"
SEP=" "
DELIM=","
# Preestablished variables
PREFIX="\${workspaceFolder}"
KCONF=".config"
VSC_OUT_FILENAME="c_cpp_properties.json"
VSC_OUT_DIRNAME=".vscode"
CCFOLDER="prebuilts/clang/host/linux-x86"
# Variables to be initialized later
VSC_OUT_FILE=""
CCPATH=""
WS=""
KDIR=""
OUT=""
SRCROOT=""
KOBJ=""

# Arrays to be filled with config data
declare -a KERN_INCLUDES
declare -a KCONF_PARSED
declare -a PROJ_SOURCES
declare -a FORCED_INCLUDES
declare -a PROJ_CONFIGS

# COMMON FUNCTIONS
# ################

function check() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: check: $? 'Message'"
        return 0
    else
        if [[ "$1" -ne 0 ]]; then
            echo "Error: $2"
            return "$1"
        fi
    fi
}

function check_args_num() {
    if [[ $# -ne 2 ]]; then
        check -1 "check_args_num: requires 2 arguments!"
    fi
    if [[ "$1" -ne "$2" ]]; then
        check -1 "check_args_num: has detected an argument mismatch!"
    fi
}

function verify_file() {
    check_args_num $# 1
    filen="$1"

    if [[ ! -e "${filen}" || ! -f "${filen}" ]]; then
        check -1 "verify_file: error locating ${filen} argument!"
    fi
}

function verify_folder() {
    check_args_num $# 1
    foldn="$1"

    if [[ ! -e "${foldn}" || ! -d "${foldn}" ]]; then
        check -1 "verify_folder: error locating ${foldn} argument!"
    fi
}

# ARGS PARSE AND VERIFY FUNCTIONS
# ###############################

function getopt_args() {
    while getopts "k:w:o:" opt; do
        case "${opt}" in
        k)
            KDIR="${OPTARG}"
            ;;
        w)
            WS="${OPTARG}"
            ;;
        o)
            OUT="${OPTARG}"
            ;;
        *)
            echo "Unrecognized option!"
            check -1 "${USAGE_TEXT}"
            ;;
        esac
    done
    shift $((OPTIND - 1))
}

function verify_args() {
    verify_folder "${KDIR}"
    verify_folder "${WS}"
    verify_folder "${OUT}"
}

# WRITE JSON HELPER FUNCTIONS
# ###########################

function write_delimiter() {
    check_args_num $# 3
    delim="$1"
    file_desc="$2"
    end_line="$3"

    if [[ -z "$file_desc" ]]; then
        if [ ! -z "$delim" ]; then printf "%s" "${delim}"; fi
        if [ ! -z "$end_line" ]; then printf "\n"; fi
    else
        if [ ! -z "$delim" ]; then printf "%s" "${delim}" >>"$file_desc"; fi
        if [ ! -z "$end_line" ]; then printf "\n" >>"$file_desc"; fi
    fi
}

function write_tabulated() {
    check_args_num $# 6

    sep="$1%.0s"
    start_ind="0"
    end_ind="$2"
    text="$3"
    file_desc="$4"
    delim="$5"
    line_end="$6"

    # First level has no space indentation
    if [[ "$end_ind" -ne 0 ]]; then
        start_ind="1"
    fi

    if [[ -z "$file_desc" ]]; then
        printf "${sep}" $(seq "$start_ind" "$end_ind")
        printf "%s" "$text"
        write_delimiter "$delim" "" "${line_end}"
    else
        printf "${sep}" $(seq "$start_ind" "$end_ind") >>"$file_desc"
        printf "%s" "$text" >>"$file_desc"
        write_delimiter "$delim" "$file_desc" "${line_end}"
    fi
}

function write_array() {
    check_args_num $# 4

    prefix="$1"
    local -n arr="$2"
    tablevel="$3"
    file="$4"

    iter=0
    let "upper=${#arr[@]} - 1"

    while [[ "$iter" -lt ${#arr[@]} ]]; do
        if [[ "$iter" -eq "$upper" ]]; then
            write_tabulated "${SEP}" "$tablevel" "${prefix}${arr[$iter]}" "${file}" "" "y"
        else
            write_tabulated "${SEP}" "$tablevel" "${prefix}${arr[$iter]}" "${file}" "${DELIM}" "y"
        fi
        let "iter=$iter+1"
    done
}

# PARSE JSON DATA FUNCTION
# ########################

function parse_data() {
    # Parse needes folders
    SRCROOT="${OUT}/../../../.."
    KOBJ="${OUT}/obj/KERNEL_OBJ"
    VSC_OUT_FILE="${WS}/${VSC_OUT_DIRNAME}/${VSC_OUT_FILENAME}"

    # Basic main project source composition
    PROJ_SOURCES+=("\"${PREFIX}\"")
    PROJ_SOURCES+=("\"${PREFIX}/include\"")
    PROJ_SOURCES+=("\"${KDIR}\"")

    # Parse the project and the kernel include files
    KERN_INCLUDES+=("\"${PREFIX}/**\"")
    KERN_INCLUDES+=("\"${PREFIX}/include\"")
    KERN_INCLUDES+=("\"${KDIR}/include\"")
    KERN_INCLUDES+=("\"${KDIR}/include/uapi\"")
    KERN_INCLUDES+=("\"${KDIR}/arch/arm64/include\"")
    KERN_INCLUDES+=("\"${KDIR}/arch/arm64/include/uapi\"")
    KERN_INCLUDES+=("\"${KOBJ}/include\"")
    KERN_INCLUDES+=("\"${KOBJ}/include/generated\"")
    KERN_INCLUDES+=("\"${KOBJ}/include/generated/uapi\"")
    KERN_INCLUDES+=("\"${KOBJ}/arch/arm64/include/generated\"")
    KERN_INCLUDES+=("\"${KOBJ}/arch/arm64/include/generated/uapi\"")

    # Parse the active kernel configs
    file="${KOBJ}/${KCONF}"
    verify_file "$file"
    for i in $(cat ${file} | grep "=y" | cut -d "=" -f 1); do
        KCONF_PARSED+=("\"$i\"")
    done

    # Parse list of forced include files and folders
    FORCED_INCLUDES+=("\"\${default}\"")
    FORCED_INCLUDES+=("\"${KDIR}/include/linux/kconfig.h\"")
    FORCED_INCLUDES+=("\"${KOBJ}/include/generated/autoconf.h\"")

    # Parse and load the project configuration
    PROJ_CONFIGS+=("\"limitSymbolsToIncludedHeaders\": true")
    PROJ_CONFIGS+=("\"databaseFilename\": \"\${default}\"")
    PROJ_CONFIGS+=("\"path\": [")

    # Parse the available clang compiler
    CCPATH=$(find ${SRCROOT}/${CCFOLDER} -name "clang" | grep bin | tail -n1)
    check $? "Error locating a compatible clang compiler!"
}

# COMPOSE JSON FUNCTION
# #####################

function compose_json() {
    # Compose the configuration file body
    write_tabulated "${SEP}" "$L0" "{" "${VSC_OUT_FILE}" "" "y"
    write_tabulated "${SEP}" "$L1" "\"env\": {" "${VSC_OUT_FILE}" "" "y"
    write_tabulated "${SEP}" "$L2" "\"myDefaultIncludePath\": [" "${VSC_OUT_FILE}" "" "y"
    write_array "" PROJ_SOURCES "$L3" "${VSC_OUT_FILE}"
    write_tabulated "${SEP}" "$L2" "]" "${VSC_OUT_FILE}" "${DELIM}" "y"
    write_tabulated "${SEP}" "$L2" "\"myCompilerPath\": \"/usr/bin/gcc\"" "${VSC_OUT_FILE}" "" "y"
    write_tabulated "${SEP}" "$L1" "}" "${VSC_OUT_FILE}" "${DELIM}" "y"

    # Compose list of main configurations entities
    write_tabulated "${SEP}" "$L1" "\"configurations\": [" "${VSC_OUT_FILE}" "" "y"
    write_tabulated "${SEP}" "$L2" "{" "${VSC_OUT_FILE}" "" "y"
    write_tabulated "${SEP}" "$L3" "\"name\": \"Linux\"" "${VSC_OUT_FILE}" "${DELIM}" "y"
    write_tabulated "${SEP}" "$L3" "\"includePath\": [" "${VSC_OUT_FILE}" "" "y"
    
    # Compose the project and kernel include files
    write_array "" KERN_INCLUDES "$L4" "${VSC_OUT_FILE}"
    write_tabulated "${SEP}" "$L3" "]" "${VSC_OUT_FILE}" "${DELIM}" "y"
    
    # Compose the kernel connfig
    write_tabulated "${SEP}" "$L3" "\"defines\": [" "${VSC_OUT_FILE}" "" "y"
    write_array "" KCONF_PARSED "$L4" "${VSC_OUT_FILE}"
    write_tabulated "${SEP}" "$L3" "]" "${VSC_OUT_FILE}" "${DELIM}" "y"
    
    # Build the actual forced include file contents
    write_tabulated "${SEP}" "$L3" "\"forcedInclude\": [" "${VSC_OUT_FILE}" "" "y"
    write_array "" FORCED_INCLUDES "$L4" "${VSC_OUT_FILE}"
    write_tabulated "${SEP}" "$L3" "]" "${VSC_OUT_FILE}" "${DELIM}" "y"
    
    # Compose the final project configuration
    write_tabulated "${SEP}" "$L3" "\"browse\": {" "${VSC_OUT_FILE}" "" "y"
    write_array "" PROJ_CONFIGS "$L4" "${VSC_OUT_FILE}"
    write_tabulated "${SEP}" "$L5" "\"\${workspaceFolder}\"" "${VSC_OUT_FILE}" "" "y"
    write_tabulated "${SEP}" "$L4" "]" "${VSC_OUT_FILE}" "" "y"
    write_tabulated "${SEP}" "$L3" "}" "${VSC_OUT_FILE}" "${DELIM}" "y"
    
    # Compose project compiler body
    write_tabulated "${SEP}" "$L3" "\"intelliSenseMode\": \"clang-x64\"" "${VSC_OUT_FILE}" "${DELIM}" "y"
    write_tabulated "${SEP}" "$L3" "\"cStandard\": \"c11\"" "${VSC_OUT_FILE}" "${DELIM}" "y"
    write_tabulated "${SEP}" "$L3" "\"cppStandard\": \"\${default}\"" "${VSC_OUT_FILE}" "${DELIM}" "y"
    write_tabulated "${SEP}" "$L3" "\"compilerPath\": \"${CCPATH}\"" "${VSC_OUT_FILE}" "" "y"
    write_tabulated "${SEP}" "$L2" "}" "${VSC_OUT_FILE}" "" "y"
    write_tabulated "${SEP}" "$L1" "]" "${VSC_OUT_FILE}" "${DELIM}" "y"
    write_tabulated "${SEP}" "$L1" "\"version\": 4" "${VSC_OUT_FILE}" "" "y"
    write_tabulated "${SEP}" "$L0" "}" "${VSC_OUT_FILE}" "" "y"
}

# CREATE AND CLEAN VS CONFIG FILE FUNCTIONS
# #########################################

function clean_vsconfig_file() {
    if [ -f "${VSC_OUT_FILE}" ]; then
        rm -f "${VSC_OUT_FILE}"
    fi
}

function create_vsconfig_file() {
    if [ ! -d "${WS}/${VSC_OUT_DIRNAME}" ]; then
        mkdir "${WS}/${VSC_OUT_DIRNAME}"
    fi
    touch "${VSC_OUT_FILE}"
}

# MAIN INEXATION FUNCTION
# #######################

function main_indexation() {

    # Exit immediately if a command exits with a non-zero status
    # set -e

    getopt_args $*
    verify_args
    parse_data
    clean_vsconfig_file
    create_vsconfig_file
    compose_json

    # Undo exit immediately if a command exits with a non-zero status (set -e)
    # set +e
}

# EXAMPLE USE:
# main_indexation -w $(pwd) -o /home/user/.../out/target/product/prodname -k /home/user/.../out/target/product/prodname/obj/KERNEL_OBJ/kernel-5.10







# #!/bin/bash

# # Workspace project entry
# WS=""
# # Android kernel baseline root directory
# KDIR=""
# # Android product out directory
# OUT=""
# # Usage instructions
# USAGE_TEXT="Usage: -w <workspace directory> -k <kernel directory>"

# # Debug enable toggle
# DBG=true

# # -------------------------------------------
# # Core helper functions follow below
# # -------------------------------------------

# # Used for basic error handling
# function check() {
#   if [[ $# -ne 2 ]]
#   then
#     echo "Usage: check: $? 'Message'"
#     return
#   else
#     if [[ "$1" -ne 0 ]]
#     then
#       echo "Error: $2"
#       exit -1
#     fi
#   fi
# }

# # TODO: refine the logic further and cleanup debug functions
# # Used for verbose message printing during debugging
# function debug_pr() {
#   if [[ ! -z "${DBG}" && "${DBG}" == "true" ]]
#   then
#     set -e
#     set -u
#     echo "$1"
#   fi
# }

# # Conditional tracing of executed command sequence
# function enable_verbose_dbg() {
#   if [[ "${DBG}" == "true" || "${DBG}" == "True" ]]
#   then
#     set -e
#   fi
# }

# # Used for explicit function argument verification
# function check_args_num() {
#   if [[ $# -ne 2 ]]
#   then
#     check -1 "check_args_num: requires 2 arguments!"
#   fi
#   if [[ "$1" -ne "$2" ]]
#   then
#     check -1 "check_args_num: has detected an argument mismatch!"
#   fi
# }

# # Used for checking file presence
# function verify_file() {
#   check_args_num $# 1
#   filen="$1"

#   if [[ ! -e "${filen}" || ! -f "${filen}" ]]
#   then
#     check -1 "verify_file: error locating ${filen} argument!"
#   fi
# }

# # Used for checking folder presence
# function verify_folder() {
#   check_args_num $# 1
#   foldn="$1"

#   if [[ ! -e "${foldn}" || ! -d "${foldn}" ]]
#   then
#     check -1 "verify_folder: error locating ${foldn} argument!"
#   fi
# }

# # Used for checking utility availability
# function verify_util() {
#   check_args_num $# 1
#   util="$1"

#   command -v "${util}" > /dev/null 2>&1
#   check $? "verify_util: error locating the ${util} program!"
# }

# # Self-explanatory and helper for range checking
# function exit_if_less_than_or_eq() {
#   check_args_num $# 2

#   if [[ -z "$1" || -z "$2" ]]
#   then
#     check -1 "exit_if_less_than_or_eq: empty string detected!"
#   fi
#   if [[ "$1" -le "$2" ]]
#   then
#     check -1 "exit_if_less_than_or_eq: $1 <= $2 is true!"
#   fi
# }

# # Self-explanatory and helper for range checking
# function exit_if_greater_than_or_eq() {
#   check_args_num $# 2

#   if [[ -z "$1" || -z "$2" ]]
#   then
#     check -1 "exit_if_less_than_or_eq: empty string detected!"
#   fi
#   if [[ "$1" -ge "$2" ]]
#   then
#     check -1 "exit_if_less_than_or_eq: $1 >= $2 is true!"
#   fi
# }

# # Used for checking whether an argument is within bounds.
# # Requres three arguments:
# # - arg to check whether it falls within (start, end)
# # - start of the range
# # - end of the range
# function verify_range() {
#   check_args_num $# 3
#   arg="$1"
#   start="$2"
#   end="$3"
#   err="verify_range: missing, zero or negative argument!"

#   # Ensure non-negativity for all range arguments
#   exit_if_less_than_or_eq "$arg" 0
#   exit_if_less_than_or_eq "$start" 0
#   exit_if_less_than_or_eq "$end" 0

#   # Ensure end of range is greater than start of the range
#   exit_if_less_than_or_eq "$end" "$start"

#   # Ensure argument is within the start and end bounds
#   exit_if_less_than_or_eq "$arg" "$start"
#   exit_if_greater_than_or_eq "$arg" "$end"
# }

# function getopt_parse() {
#   while getopts "k:w:o:" opt;
#   do
#     case "${opt}" in
#       k)
#         kdir="${OPTARG}"
#         ;;
#       w)
#         wdir="${OPTARG}"
#         ;;
#       o)
#         odir="${OPTARG}"
#         ;;
#       *)
#         echo "Unrecognized option!"
#         check -1 "${USAGE_TEXT}"
#         ;;
#     esac
#   done
#   shift $((OPTIND-1))
# }

# # Interrupt and terminate signal handler
# function exit_script() {
#   echo "SIGINT signal caught!"
#   echo "Number of items in child pid array: ${#PIDA[@]}"
#   echo "Sending kill signal to children with pids ${PIDA[@]}"
#   trap - INT SIGINT SIGTERM
#   kill -9 -- -$$
# }

# function parse_args() {
#   if [[ -z "${kdir}" || -z "${wdir}" || -z "${odir}" ]]
#   then
#     echo "${USAGE_TEXT}"
#     check -1 "Missing or empty required argument value!"
#   fi
#   KDIR="${kdir}"
#   WS="${wdir}"
#   OUT="${odir}"

#   # Validate script arguments
#   verify_folder "${KDIR}"
#   verify_folder "${WS}"
#   verify_folder "${OUT}"

#   debug_pr "Provided workspace directory is: ${WS}"
#   debug_pr "Provided kernel directory is: ${KDIR}"
#   debug_pr "Provided product output directory is: ${OUT}"
#   debug_pr "PID of the shell process is: $$"
# }

# # Parser functions follow below
# # Helper function to insert a delimiter character
# function write_delimiter() {
#     check_args_num $# 3
#     delim="$1"
#     file_desc="$2"
#     end_line="$3"

#     if [[ -z "$file_desc" ]]
#     then
#         if [ ! -z "$delim" ]; then printf "%s" "${delim}"; fi
#         if [ ! -z "$end_line" ]; then printf "\n"; fi
#     else
#         if [ ! -z "$delim" ]; then printf "%s" "${delim}" >> "$file_desc"; fi
#         if [ ! -z "$end_line" ]; then printf "\n" >> "$file_desc"; fi
#     fi
# }

# # Helper to write tabulated formatted output to the configuration file
# function write_tabulated() {
#     check_args_num $# 6

#     sep="$1%.0s"
#     start_ind="0"
#     end_ind="$2"
#     text="$3"
#     file_desc="$4"
#     delim="$5"
#     line_end="$6"

#     # First level has no space indentation
#     if [[ "$end_ind" -ne 0 ]]
#     then
#         start_ind="1"
#     fi

#     if [[ -z "$file_desc" ]]
#     then
#         printf "${sep}" $(seq "$start_ind" "$end_ind"); printf "%s" "$text";
#         write_delimiter "$delim" "" "${line_end}"
#     else
#         printf "${sep}" $(seq "$start_ind" "$end_ind")  >> "$file_desc"; printf "%s" "$text" >> "$file_desc"
#         write_delimiter "$delim" "$file_desc" "${line_end}"
#     fi
# }

# function write_array() {
#     check_args_num $# 4

#     prefix="$1"
#     local -n arr="$2"
#     tablevel="$3"
#     file="$4"

#     debug_pr "Length of array is: ${#arr[@]}"
#     iter=0
#     let "upper=${#arr[@]} - 1"

#     while [[ "$iter" -lt ${#arr[@]} ]]
#         do
#             if [[ "$iter" -eq "$upper" ]]
#             then
#                 write_tabulated "${SEP}" "$tablevel" "${prefix}${arr[$iter]}" "${file}" "" "y"
#             else
#                 write_tabulated "${SEP}" "$tablevel" "${prefix}${arr[$iter]}" "${file}" "," "y"
#             fi
#         let "iter=$iter+1"
#     done
# }







# #!/bin/sh

# # Helper text separator character markers
# L0="0"
# L1="4"
# L2="8"
# L3="12"
# L4="16"
# L5="20"

# # Text separator character
# SEP=" "
# # Text item delimiter character
# DELIM=","

# PREFIX="\${workspaceFolder}"
# KOBJ="${OUT}/obj/KERNEL_OBJ"
# KCONF=".config"
# VSC_OUT_FILE="./c_cpp_properties.json"
# SRCROOT="${OUT}/../../../.."
# CCFOLDER="prebuilts/clang/host/linux-x86"
# CCPATH=""

# declare -a KERN_INCLUDES
# declare -a KCONF_PARSED
# declare -a PROJ_SOURCES
# declare -a FORCED_INCLUDES
# declare -a PROJ_CONFIGS

# source ./common.sh
# set -e

# # Basic main project source composition function
# function parse_proj_body() {
#     PROJ_SOURCES+=("\"${PREFIX}\"")
#     PROJ_SOURCES+=("\"${PREFIX}/include\"")
#     PROJ_SOURCES+=("\"${KDIR}\"")
# }

# # Parse the project and the kernel include files
# function parse_proj_includes() {
#     KERN_INCLUDES+=("\"${PREFIX}/**\"")
#     KERN_INCLUDES+=("\"${PREFIX}/include\"")

#     KERN_INCLUDES+=("\"${KDIR}include\"")
#     KERN_INCLUDES+=("\"${KDIR}include/uapi\"")
#     KERN_INCLUDES+=("\"${KDIR}/arch/arm64/include\"")
#     KERN_INCLUDES+=("\"${KDIR}/arch/arm64/include/uapi\"")

#     KERN_INCLUDES+=("\"${KOBJ}/include\"")
#     KERN_INCLUDES+=("\"${KOBJ}/include/generated\"")
#     KERN_INCLUDES+=("\"${KOBJ}/include/generated/uapi\"")
#     KERN_INCLUDES+=("\"${KOBJ}/arch/arm64/include/generated\"")
#     KERN_INCLUDES+=("\"${KOBJ}/arch/arm64/include/generated/uapi\"")
# }

# # Parse the active kernel configs
# function parse_kernel_configs() {

#     file="${KOBJ}/${KCONF}"
#     verify_file "$file"

#     for i in `cat ${file} | grep "=y" | cut -d "=" -f 1 `
#     do
#         KCONF_PARSED+=("\"$i\"")
#     done
# }

# # Parse list of forced include files and folders
# function parse_forced_includes() {
#     FORCED_INCLUDES+=("\"\${default}\"")
#     FORCED_INCLUDES+=("\"${KDIR}/include/linux/kconfig.h\"")
#     FORCED_INCLUDES+=("\"${KOBJ}/include/generated/autoconf.h\"")
# }

# # Function to parse and load the project configuration
# function parse_proj_configs() {
#     PROJ_CONFIGS+=("\"limitSymbolsToIncludedHeaders\": true")
#     PROJ_CONFIGS+=("\"databaseFilename\": \"\${default}\"")
#     PROJ_CONFIGS+=("\"path\": [")
# }

# # Function to parse the available clang compiler
# # TODO: revisit if necessary
# function parse_clang_compiler() {
#     CCPATH=`find ${SRCROOT}/${CCFOLDER} -name "clang" | grep bin | tail -n1`
#     check $? "Error locating a compatible clang compiler!"
#     debug_pr "Found clang compiler chosen is: ${CCPATH}"
# }

# # Build the actual forced include file contents
# function compose_forced_includes() {
#     parse_forced_includes
#     write_tabulated "${SEP}" "$L3" "\"forcedInclude\": [" "${VSC_OUT_FILE}" "" "y"
#     write_array "" FORCED_INCLUDES "$L4" "${VSC_OUT_FILE}"
#     write_tabulated "${SEP}" "$L3" "]" "${VSC_OUT_FILE}" "," "y"
# }

# # Compose the configuration file body
# function compose_body() {
#     write_tabulated "${SEP}" "$L0" "{" "${VSC_OUT_FILE}" "" "y"
#     write_tabulated "${SEP}" "$L1" "\"env\": {" "${VSC_OUT_FILE}" "" "y"
#     write_tabulated "${SEP}" "$L2" "\"myDefaultIncludePath\": [" "${VSC_OUT_FILE}" "" "y"
#     parse_proj_body
#     write_array "" PROJ_SOURCES "$L3" "${VSC_OUT_FILE}"
#     write_tabulated "${SEP}" "$L2" "]" "${VSC_OUT_FILE}" "," "y"
#     write_tabulated "${SEP}" "$L2" "\"myCompilerPath\": \"/usr/bin/gcc\"" "${VSC_OUT_FILE}" "" "y"
#     write_tabulated "${SEP}" "$L1" "}" "${VSC_OUT_FILE}" "," "y"
# }

# # Compose the project and kernel include files
# function compose_includes() {
#     parse_proj_includes
#     write_array "" KERN_INCLUDES "$L4" "${VSC_OUT_FILE}"
#     write_tabulated "${SEP}" "$L3" "]" "${VSC_OUT_FILE}" "," "y"
# }

# # Compose the configuration file body
# function compose_kernel_config() {
#     parse_kernel_configs
#     write_tabulated "${SEP}" "$L3" "\"defines\": [" "${VSC_OUT_FILE}" "" "y"
#     write_array "" KCONF_PARSED "$L4" "${VSC_OUT_FILE}"
#     write_tabulated "${SEP}" "$L3" "]" "${VSC_OUT_FILE}" "," "y"
# }

# # Compose the final project configuration
# function compose_proj_configuration() {
#     parse_proj_configs
#     write_tabulated "${SEP}" "$L3" "\"browse\": {" "${VSC_OUT_FILE}" "" "y"
#     write_array "" PROJ_CONFIGS "$L4" "${VSC_OUT_FILE}"
#     write_tabulated "${SEP}" "$L5" "\"\${workspaceFolder}\"" "${VSC_OUT_FILE}" "" "y"
#     write_tabulated "${SEP}" "$L4" "]" "${VSC_OUT_FILE}" "" "y"
#     write_tabulated "${SEP}" "$L3" "}" "${VSC_OUT_FILE}" "," "y"
# }

# # Compose project compiler body
# function compose_body_closure() {
#     parse_clang_compiler
#     write_tabulated "${SEP}" "$L3" "\"intelliSenseMode\": \"clang-x64\"" "${VSC_OUT_FILE}" "," "y"
#     write_tabulated "${SEP}" "$L3" "\"cStandard\": \"c11\"" "${VSC_OUT_FILE}" "," "y"
#     write_tabulated "${SEP}" "$L3" "\"cppStandard\": \"\${default}\"" "${VSC_OUT_FILE}" "," "y"
#     write_tabulated "${SEP}" "$L3" "\"compilerPath\": \"${CCPATH}\"" "${VSC_OUT_FILE}" "" "y"
#     write_tabulated "${SEP}" "$L2" "}" "${VSC_OUT_FILE}" "" "y"
#     write_tabulated "${SEP}" "$L1" "]" "${VSC_OUT_FILE}" "," "y"
#     write_tabulated "${SEP}" "$L1" "\"version\": 4" "${VSC_OUT_FILE}" "" "y"
#     write_tabulated "${SEP}" "$L0" "}" "${VSC_OUT_FILE}" "" "y"
# }

# # Compose list of main configurations entities
# function compose_configuration() {
#     write_tabulated "${SEP}" "$L1" "\"configurations\": [" "${VSC_OUT_FILE}" "" "y"
#     write_tabulated "${SEP}" "$L2" "{" "${VSC_OUT_FILE}" "" "y"
#     write_tabulated "${SEP}" "$L3" "\"name\": \"Linux\"" "${VSC_OUT_FILE}" "," "y"
#     write_tabulated "${SEP}" "$L3" "\"includePath\": [" "${VSC_OUT_FILE}" "" "y"
#     compose_includes
#     compose_kernel_config
#     compose_forced_includes
#     compose_proj_configuration
#     compose_body_closure
# }



# function delete_vsconfig() {
#     rm -f "${VSC_OUT_FILE}"
# }

# # Main script argument parsing
# getopt_parse $*
# parse_args

# # Parse the kernel main configs
# parse_kernel_configs > /dev/null 2>&1
# check $? "Error parsing the built kernel configuration"

# # Cleaunp any leftover configuration file
# delete_vsconfig
# # Compose the configuration files
# compose_body
# # Compose configuration body
# compose_configuration
# check $? "Error writing the kernel configuration"