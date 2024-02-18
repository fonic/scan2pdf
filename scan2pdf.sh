#!/usr/bin/env bash

# ------------------------------------------------------------------------------
#                                                                              -
#  Scan to PDF (scan2pdf)                                                      -
#                                                                              -
#  Created by Fonic <https://github.com/fonic>                                 -
#  Date: 04/17/21 - 02/18/24                                                   -
#                                                                              -
#  Inspired by:                                                                -
#  https://gist.github.com/mludvig/936678                                      -
#                                                                              -
# ------------------------------------------------------------------------------

# --------------------------------------
#                                      -
#  Early Tasks                         -
#                                      -
# --------------------------------------

# Check if running Bash and required version (check does not rely on any
# Bashisms to ensure it works on any POSIX-compliant shell)
if [ -z "${BASH_VERSION}" ] || [ "${BASH_VERSION%%.*}" -lt 4 ]; then
	echo "Error: this script requires Bash >= v4.0 to run"
	exit 1
fi


# --------------------------------------
#                                      -
#  Globals                             -
#                                      -
# --------------------------------------

# Script information
SCRIPT_FILE="$(basename -- "$0")"
SCRIPT_PATH="$(realpath -- "$0")"
SCRIPT_CONF="${SCRIPT_PATH%.*}.conf"
SCRIPT_TITLE="Scan to PDF (scan2pdf)"
SCRIPT_VERSION="2.6 (02/18/24)"

# Usage information
# NOTE:
# Tokens '%{...}' are replaced with dynamically generated contents; Variable
# expansion is deferred until printing (to account for sourced configuration)
USAGE_INFO="\e[1mUsage:\e[0m \${SCRIPT_FILE} [OPTIONS] OUTFILE

\e[1m\${SCRIPT_TITLE} v\${SCRIPT_VERSION}\e[0m
Scan documents directly to PDF files.

\e[1mOptions:\e[0m
  -d, --device STRING           Scanner device ['\${DEVICE_DEFAULT}']
  -m, --mode STRING             Color mode ['\${MODE_DEFAULT}']
                                %{COLOR_MODES}
  -r, --resolution VALUE        Scan resolution in dpi [\${RESOLUTION_DEFAULT}]
                                %{SCAN_RESOLUTIONS}
  -s, --source STRING           Scan source ['\${SOURCE_DEFAULT}']
                                %{SCAN_SOURCES}

  -b, --brightness VALUE        Brightness in percent (\${BRIGHTNESS_MIN}..\${BRIGHTNESS_MAX}) [\${BRIGHTNESS_DEFAULT}]
                                (only applied if supported by color mode)
  -c, --contrast VALUE          Contrast in percent (\${CONTRAST_MIN}..\${CONTRAST_MAX}) [\${CONTRAST_DEFAULT}]
                                (only applied if supported by color mode)

  -x, --topleftx VALUE          Top left x offset of scan area in mm (\${TOPLEFTX_MIN}..\${TOPLEFTX_MAX}) [\${TOPLEFTX_DEFAULT}]
  -y, --toplefty VALUE          Top left y offset of scan area in mm (\${TOPLEFTY_MIN}..\${TOPLEFTY_MAX}) [\${TOPLEFTY_DEFAULT}]
  -w, --width VALUE             Width of scan area in mm (\${WIDTH_MIN}..\${WIDTH_MAX}) [\${WIDTH_DEFAULT}]
  -e, --height VALUE            Height of scan area in mm (\${HEIGHT_MIN}..\${HEIGHT_MAX}) [\${HEIGHT_DEFAULT}]

  -u, --manual-duplex           Scan odd pages, prompt, scan even pages, interleave
                                odd and even pages to produce combined output [\${MANUAL_DUPLEX_DEFAULT}]

  -a, --batch-mode              Scan multiple documents, prompt in between documents
                                (makes option '-p/--outfile-pattern' mandatory) [\${BATCH_MODE_DEFAULT}]
  -p, --outfile-pattern         Interpret OUTFILE argument as printf-style pattern,
                                determine next output file by incrementing integer
                                token (e.g. '~/Documents/Scan_%05d.pdf') [\${OUTFILE_PATTERN_DEFAULT}]

  -i, --initial-prompt          Prompt before first scan operation (e.g. before odd
                                pages for manual duplex or before first document in
                                batch mode) [\${INITIAL_PROMPT_DEFAULT}]
  -t, --prompt-timeout VALUE    Timeout for prompts in seconds (0 == no timeout) [\${PROMPT_TIMEOUT_DEFAULT}]
                                Allows duplex- and/or batch-scanning without having
                                to press ENTER to continue when being prompted

  -k, --keep-temp               Keep temporary directory on exit [\${KEEP_TEMP_DEFAULT}]

  -h, --help                    Print usage information

\e[1mNOTE:\e[0m
Strings/values in square brackets show current defaults."

# Indent of option descriptions in usage information (used to properly align
# dynamically generated contents, i.e. when replacing '%{...}' tokens)
USAGE_INDENT=32

# Upper limit for index used to determine next available output file based
# on output file pattern (1M documents in one folder should be more than
# enough)
MAX_INDEX=1000000


# --------------------------------------
#                                      -
#  Default Configuration               -
#                                      -
# --------------------------------------

# NOTE:
# Turn scanner on and run 'scanimage --help' to get detailed information
# on supported parameters and/or valid values for scan-related settings

# Default scanner device (string)
#DEVICE_DEFAULT="brother3:net1;dev0"
DEVICE_DEFAULT="brother4:net1;dev0"

# Supported color modes (array of strings), default color mode (string)
MODE_CHOICES=(
	"Black & White"
	"Gray[Error Diffusion]"
	"True Gray"
	"24bit Color"
	"24bit Color[Fast]"
)
MODE_DEFAULT="${MODE_CHOICES[3]}"

# Supported scan resolutions (array of integers, in dpi), default scan
# resolution (integer, in dpi)
RESOLUTION_CHOICES=(100 150 200 300 400 600 1200 2400 4800 9600)
RESOLUTION_DEFAULT=${RESOLUTION_CHOICES[3]}

# Supported scan sources (array of strings), default scan source (string)
SOURCE_CHOICES=(
	"FlatBed"
	"Automatic Document Feeder(left aligned)"
	"Automatic Document Feeder(left aligned,Duplex)"
	"Automatic Document Feeder(centrally aligned)"
	"Automatic Document Feeder(centrally aligned,Duplex)"
)
SOURCE_DEFAULT="${SOURCE_CHOICES[1]}"

# Brightness min/max/default value (integer, in %), color modes that
# support brightness control (array of strings; see MODE_CHOICES above)
BRIGHTNESS_MIN=-50
BRIGHTNESS_MAX=50
BRIGHTNESS_DEFAULT=0
BRIGHTNESS_MODES=(
	"Gray[Error Diffusion]"
	"True Gray"
)

# Contrast min/max/default value (integer, in %), color modes that
# support contrast control (array of strings; see MODE_CHOICES above)
CONTRAST_MIN=-50
CONTRAST_MAX=50
CONTRAST_DEFAULT=0
CONTRAST_MODES=(
	"Gray[Error Diffusion]"
	"True Gray"
)

# Scan geometry min/max/default values (integer, in mm)
TOPLEFTX_MIN=0
TOPLEFTX_MAX=216
TOPLEFTX_DEFAULT=0
TOPLEFTY_MIN=0
TOPLEFTY_MAX=356
TOPLEFTY_DEFAULT=0
WIDTH_MIN=0
WIDTH_MAX=216
HEIGHT_MIN=0
HEIGHT_MAX=356
#WIDTH_DEFAULT=210                                          # DIN A4 (210.0 mm /  8.3 in)
#HEIGHT_DEFAULT=297                                         # DIN A4 (297.0 mm / 11.7 in)
#WIDTH_DEFAULT=216                                          # Legal  (215.9 mm /  8.5 in)
#HEIGHT_DEFAULT=356                                         # Legal  (355.6 mm / 14.0 in)
WIDTH_DEFAULT=216                                           # Letter (215.9 mm /  8.5 in)
HEIGHT_DEFAULT=279                                          # Letter (279.4 mm / 11.0 in)

# Options passed to 'scanimage' (array of strings)
#SCANIMAGE_OPTS=("--progress" "--verbose")                  # Display scan progress, produce verbose output
#SCANIMAGE_OPTS=("--progress" "--batch-prompt")             # Display scan progress, prompt before each page
SCANIMAGE_OPTS=("--progress")                               # Display scan progress

# Options passed to 'convert' (array of strings)
# NOTE: uses separate options for INPUT and OUTPUT
CONVERT_INPUT_OPTS=()                                       # No input options
#CONVERT_OUTPUT_OPTS=("-compress" "zip")                    # Use ZIP compression (lossless, higher quality, larger PDF file)
CONVERT_OUTPUT_OPTS=("-compress" "jpeg" "-quality" "95")    # Use JPEG compression (quality 95) (lossy, lower quality, smaller PDF file)

# Options passed to 'tiffcp' (array of strings)
# NOTE: only used if 'convert' is not available
TIFFCP_OPTS=("-c" "lzw")                                    # Use LZW compression (fast, lossless)

# Options passed to 'tiff2pdf' (array of strings)
# NOTE: only used if 'convert' is not available
#TIFF2PDF_OPTS=("-z")                                       # Use ZIP compression (lossless, higher quality, larger PDF file)
TIFF2PDF_OPTS=("-j" "-q" "95")                              # Use JPEG compression (quality 95) (lossy, lower quality, smaller PDF file)

# Manual duplex scan by default: scan odd pages, prompt, scan even
# pages, interleave odd and even pages to produce combined output
# (string, 'yes'/'no')
MANUAL_DUPLEX_DEFAULT="no"

# Batch mode by default: scan multiple documents, prompt in between
# documents (string, 'yes'/'no')
BATCH_MODE_DEFAULT="no"

# Interpret OUTFILE command line argument as printf-style pattern by
# default and determine next output file automatically by incrementing
# integer token of pattern (string, 'yes'/'no')
# Example:
# Pattern '~/Documents/Scan_%05d.pdf' -> '~/Documents/Scan_00001.pdf',
# '~/Documents/Scan_00002.pdf', '~/Documents/Scan_00003.pdf', ...
OUTFILE_PATTERN_DEFAULT="no"

# Prompt before first scan operation by default (e.g. before odd pages
# for manual duplex or before first document in batch mode) (string,
# 'yes'/'no')
INITIAL_PROMPT_DEFAULT="no"

# Default timeout for prompts (integer, in seconds; 0 == no timeout)
PROMPT_TIMEOUT_DEFAULT=0

# Keep temporary directory on exit by default (string, 'yes'/'no')
KEEP_TEMP_DEFAULT="no"


# --------------------------------------
#                                      -
#  Functions                           -
#                                      -
# --------------------------------------

# Print normal/hilite/good/warn/error message [$*: message]
function printn() { echo -e "$*"; }
function printh() { echo -e "\e[1m$*\e[0m"; }
function printg() { echo -e "\e[1;32m$*\e[0m"; }
function printw() { echo -e "\e[1;33m$*\e[0m" >&2; }
function printe() { echo -e "\e[1;31m$*\e[0m" >&2; }

# Print command [$1: command, $2..$n: arguments]
# NOTE:
# This focuses on the most common argument syntax ('--option=value'),
# other argument formats (e.g. 'dd') might not get displayed correctly
function print_cmd() {
	local output="Command:" arg
	for arg; do
		output+=" "
		if [[ "${arg}" =~ ^(--.+)=(.+)$ ]]; then
			output+="${BASH_REMATCH[1]}="
			arg="${BASH_REMATCH[2]}"
		fi
		if [[ "${arg}" == *[[:space:]]* || "${arg}" == *"$"* || "${arg}" == *";"* || "${arg}" == *"&"* || \
		      "${arg}" == *"\`"*        || "${arg}" == *"~"* || "${arg}" == *"{"* || "${arg}" == *"}"* || \
		      "${arg}" == *"\""*        || "${arg}" == *"#"* || "${arg}" == *"("* || "${arg}" == *")"* || \
		      "${arg}" == *"\\"*        || "${arg}" == *"'"* || "${arg}" == *"<"* || "${arg}" == *">"* ]]; then
			arg="${arg//\\/\\\\}"; arg="${arg//\$/\\\$}" # need to be escaped as those still
			arg="${arg//\"/\\\"}"; arg="${arg//\`/\\\`}" # have special meaning within "..."
			output+="\"${arg}\""
		else
			output+="${arg}"
		fi
	done
	printn "${output}"
}

# Print error message and exit [$1: error message (optional), $2: exit code
# (optional, defaults to 1)]
function die() {
	set +e; trap - ERR
	[[ -n "${1+set}" ]] && printe "$1"
	exit ${2:-1}
}

# Check if array contains item [$1: item, $2: array name]
function in_array() {
	local _needle="$1" _item
	local -n _haystack="$2"
	for _item in "${_haystack[@]}"; do
		[[ "${_item}" == "${_needle}" ]] && return 0
	done
	return 1
}

# Get next argument(s) [$1..$n: target variable name]
# Get next option(s) [$1..$n: target variable name]
# NOTE:
# By default, getarg() will not fetch arguments starting with '-'. Prefix
# target variable names with '-' to override, e.g. 'getarg -name1 name2'.
# getopt() is a convenience wrapper that prefixes all target variable names
# with '-', thus e.g. 'while getopt option' may be used instead of an ugly
# and error-prone 'while getarg -option'
_ARGS=("$@"); _ARGI=0
function getarg() {
	while (( $# > 0 )); do
		(( ${_ARGI} >= ${#_ARGS[@]} )) && return 1
		[[ "${_ARGS[_ARGI]}" == "-"* ]] && [[ "$1" != "-"* ]] && return 1
		local -n _dstvar="${1/#-/}"
		_dstvar="${_ARGS[_ARGI]}"
		_ARGI=$((_ARGI + 1))
		shift
	done
	return 0
}
function getopt() {
	getarg "${@/#/-}"
	return $?
}

# Check if command is available [$1: command]
function is_cmd_avail() {
	command -v "$1" &>/dev/null
	return $?
}

# Check if argument is integer value [$1: argument, $2: min value (optional),
# $3: max value (optional)]; Return values: 0 = integer within range, 1 = not
# an integer, 2 = integer out of range
# NOTE:
# min/max arguments are not type-checked and assumed to be provided correctly
function is_integer() {
	[[ "${1/#-/}" == "" || "${1/#-/}" == *[!0-9]* ]] && return 1
	[[ -n "${2+set}" && -n "$2" ]] && (( $1 < $2 )) && return 2
	[[ -n "${3+set}" && -n "$3" ]] && (( $1 > $3 )) && return 2
	return 0
}

# Check if argument is floating point value [$1: argument]
function is_float() {
	[[ "$1" =~ ^[0-9]+$ || "$1" =~ ^[0-9]+[.][0-9]+$ ]] && return 0
	return 1
}

# Prompt user [$1: prompt message, $2: timeout in seconds (0 == no timeout)]
# NOTE:
# read returns 1 for CTRL+D (EOF) and >128 on timeout (according to man pages)
function prompt_user() {
	local msg="$1" timeout="$2" opts=("-s") result
	(( 10#${timeout} > 0 )) && opts+=("-t" "${timeout}")
	printw "${msg}"
	read "${opts[@]}" && result=$? || result=$?
	(( ${result} == 0 || ${result} > 128 )) && return 0
	return 1
}


# --------------------------------------
#                                      -
#  Main                                -
#                                      -
# --------------------------------------

# Set up error handling (exit on unbound variables and on unhandled errors)
set -ueE; trap "printe \"Error: an unhandled error occurred on line \${LINENO}, aborting\"; exit 1" ERR

# Set up trap to handle CTRL+C/SIGINT
trap "set +e; trap - ERR; echo -en \"\r\e[2K\"; printn; printw \"Aborting per user request (CTRL+C/SIGINT).\"; exit 130" INT

# Source configuration
if ! source "${SCRIPT_CONF}"; then
	printe "Error: failed to read configuration file '${SCRIPT_CONF}', aborting"
	exit 1
fi

# Display usage information if requested
if (( $# == 0 )) || in_array "-h" _ARGS || in_array "--help" _ARGS; then
	# Add dynamic contents to usage information (replaces '%{...}' tokens)
	modes=""; resolutions=""; sources=""
	for ((i=0; i < ${#MODE_CHOICES[@]}; i++)); do
		printf -v line "%${modes:+${USAGE_INDENT}}s%s${MODE_CHOICES[i+1]+\n}" "" "'${MODE_CHOICES[i]}'${MODE_CHOICES[i+1]+,}"
		modes+="${line}"
	done
	for item in "${RESOLUTION_CHOICES[@]}"; do
		resolutions+="${resolutions:+, }${item}"
	done
	for ((i=0; i < ${#SOURCE_CHOICES[@]}; i++)); do
		printf -v line "%${sources:+${USAGE_INDENT}}s%s${SOURCE_CHOICES[i+1]+\n}" "" "'${SOURCE_CHOICES[i]}'${SOURCE_CHOICES[i+1]+,}"
		sources+="${line}"
	done
	USAGE_INFO="${USAGE_INFO/"%{COLOR_MODES}"/"${modes}"}"
	USAGE_INFO="${USAGE_INFO/"%{SCAN_RESOLUTIONS}"/"${resolutions}"}"
	USAGE_INFO="${USAGE_INFO/"%{SCAN_SOURCES}"/"${sources}"}"

	# Display usage information (with variables expanded) and exit
	# CAUTION: uses eval (!)
	eval "printn \"${USAGE_INFO}\""
	exit 0
fi

# Print title, set up cosmetic exit trap (will be replaced later)
printn
printh "--==[ ${SCRIPT_TITLE} v${SCRIPT_VERSION} ]==--"
printn
trap "printn" EXIT

# Initialize settings with defaults
for item in device mode resolution source brightness contrast topleftx toplefty width height manual_duplex batch_mode outfile_pattern initial_prompt prompt_timeout keep_temp; do
	declare -n setvar="${item}"
	declare -n defvar="${item^^}_DEFAULT"
	setvar="${defvar}"
done

# Process command line
result=0
while getopt option; do
	case "${option}" in
		-d|--device)
			getarg device || { printe "Error: option '${option}' requires an argument"; result=1; continue; }
			[[ -n "${device}" ]] || { printe "Error: invalid device string '${device}'"; result=1; continue; }
			;;
		-m|--mode)
			getarg mode || { printe "Error: option '${option}' requires an argument"; result=1; continue; }
			in_array "${mode}" MODE_CHOICES || { printe "Error: invalid mode string '${mode}'"; result=1; continue; }
			;;
		-r|--resolution)
			getarg resolution || { printe "Error: option '${option}' requires an argument"; result=1; continue; }
			in_array "${resolution}" RESOLUTION_CHOICES || { printe "Error: invalid resolution value '${resolution}'"; result=1; continue; }
			;;
		-s|--source)
			getarg source || { printe "Error: option '${option}' requires an argument"; result=1; continue; }
			in_array "${source}" SOURCE_CHOICES || { printe "Error: invalid source string '${source}'"; result=1; continue; }
			;;
		-b|--brightness)
			getarg -brightness || { printe "Error: option '${option}' requires an argument"; result=1; continue; }
			is_integer "${brightness}" ${BRIGHTNESS_MIN} ${BRIGHTNESS_MAX} || { printe "Error: invalid brightness value '${brightness}'"; result=1; continue; }
			;;
		-c|--contrast)
			getarg -contrast || { printe "Error: option '${option}' requires an argument"; result=1; continue; }
			is_integer "${contrast}" ${CONTRAST_MIN} ${CONTRAST_MAX} || { printe "Error: invalid contrast value '${contrast}'"; result=1; continue; }
			;;
		-x|--topleftx)
			getarg topleftx || { printe "Error: option '${option}' requires an argument"; result=1; continue; }
			is_integer "${topleftx}" ${TOPLEFTX_MIN} ${TOPLEFTX_MAX} || { printe "Error: invalid top left x value '${topleftx}'"; result=1; continue; }
			;;
		-y|--toplefty)
			getarg toplefty || { printe "Error: option '${option}' requires an argument"; result=1; continue; }
			is_integer "${toplefty}" ${TOPLEFTY_MIN} ${TOPLEFTY_MAX} || { printe "Error: invalid top left y value '${toplefty}'"; result=1; continue; }
			;;
		-w|--width)
			getarg width || { printe "Error: option '${option}' requires an argument"; result=1; continue; }
			is_integer "${width}" ${WIDTH_MIN} ${WIDTH_MAX} || { printe "Error: invalid width value '${width}'"; result=1; continue; }
			;;
		-e|--height)
			getarg height || { printe "Error: option '${option}' requires an argument"; result=1; continue; }
			is_integer "${height}" ${HEIGHT_MIN} ${HEIGHT_MAX} || { printe "Error: invalid height value '${height}'"; result=1; continue; }
			;;
		-u|--manual-duplex)
			manual_duplex="yes"
			;;
		-a|--batch-mode)
			batch_mode="yes"
			;;
		-p|--outfile-pattern)
			outfile_pattern="yes"
			;;
		-i|--initial-prompt)
			initial_prompt="yes"
			;;
		-t|--prompt-timeout)
			getarg prompt_timeout || { printe "Error: option '${option}' requires an argument"; result=1; continue; }
			is_integer "${prompt_timeout}" || { printe "Error: invalid prompt timeout value '${prompt_timeout}'"; result=1; continue; }
			;;
		-k|--keep-temp)
			keep_temp="yes"
			;;
		-h|--help)
			# already handled above
			;;
		-*)
			printe "Error: unknown option '${option}'"
			result=1
			;;
		*)
			[[ -z "${outfile+set}" ]] || { printe "Error: superfluous positional argument '${option}'"; result=1; continue; }
			outfile="${option}"
			;;
	esac
done
[[ "${batch_mode}" == "yes" && "${outfile_pattern}" != "yes" ]] && { printe "Error: option '-a/--batch-mode' requires option '-p/--outfile-pattern'"; result=1; }
if [[ "${outfile_pattern}" == "yes" ]]; then
	if [[ -n "${outfile+set}" ]]; then
		[[ "${outfile}" =~ %[0-9]*d ]] || { printe "Error: invalid output file pattern '${outfile}' (integer token missing)"; result=1; }
	else
		 printe "Error: no output file pattern specified"; result=1
	fi
else
	if [[ -n "${outfile+set}" ]]; then
		[[ -e "${outfile}" ]] && { printe "Error: output file '${outfile}' already exists"; result=1; }
	else
		 printe "Error: no output file specified"; result=1
	fi
fi
(( ${result} == 0 )) || { printe "Error: invalid command line, use '--help' to display usage information"; exit 2; }

# Check command availability
result=0
is_cmd_avail "scanimage" || { printe "Error: command 'scanimage' is not available"; result=1; }
if ! is_cmd_avail "convert"; then
	if ! is_cmd_avail "tiffcp" || ! is_cmd_avail "tiff2pdf"; then
		printe "Error: neither command 'convert' nor 'tiffcp'/'tiff2pdf' is available"; result=1
	fi
fi
(( ${result} == 0 )) || { printe "Error: missing required command(s), check dependencies"; exit 1; }

# Print scan settings/parameters
printh "Scan settings/parameters:"
printn "Scanner device:          ${device}"
printn "Color mode:              ${mode}"
printn "Scan resolution:         ${resolution} dpi"
printn "Scan source:             ${source}"
in_array "${mode}" BRIGHTNESS_MODES && printn "Brightness:              ${brightness}%"
in_array "${mode}" CONTRAST_MODES && printn "Contrast:                ${contrast}%"
printn "Area top left x:         ${topleftx} mm"
printn "Area top left y:         ${toplefty} mm"
printn "Area width:              ${width} mm"
printn "Area height:             ${height} mm"
printn "Manual duplex:           ${manual_duplex}"
printn "Batch mode:              ${batch_mode}"
printn "Initial prompt:          ${initial_prompt}"
printn "Prompt timeout:          ${prompt_timeout}"
printn "Keep temp directory:     ${keep_temp}"
if [[ "${outfile_pattern}" != "yes" ]]; then
	printn "Output file:             ${outfile}"
else
	printn "Output file pattern:     ${outfile}"
fi
printn "Scanimage options:       ${SCANIMAGE_OPTS[@]-"(none)"}"
if is_cmd_avail "convert"; then
	printn "Convert input options:   ${CONVERT_INPUT_OPTS[@]-"(none)"}"
	printn "Convert output options:  ${CONVERT_OUTPUT_OPTS[@]-"(none)"}"
else
	printn "Tiffcp options:          ${TIFFCP_OPTS[@]-"(none)"}"
	printn "Tiff2pdf options:        ${TIFF2PDF_OPTS[@]-"(none)"}"
fi
printn

# Create temporary directory, set up exit trap for cleanup (replaces pre-
# viously set up cosmetic exit trap)
printh "Creating temporary directory..."
tempdir="$(mktemp -d)" || { printe "Error: failed to create temporary directory, aborting"; exit 1; }
trap "set +e; trap - ERR; if [[ \"${keep_temp}\" == \"yes\" ]]; then printn; printw \"Keeping temporary directory '${tempdir}'.\"; else rm -rf -- \"${tempdir}\"; fi; printn" EXIT
printn "Path: ${tempdir}"
printn

# --- TESTING mask commands for dry run TESTING ---
function scanimage() { return 0; }
function convert()   { return 0; }
function tiffcp()    { return 0; }
function tiff2pdf()  { return 0; }
# --- TESTING mask commands for dry run TESTING ---

# Scan loop (executed only once if not in batch mode)
result=0; prompt="${initial_prompt}"
index=0; pattern="${outfile}"
while true; do

	# Prompt user to insert/prepare next scan item?
	# Enable prompt for upcoming iterations afterwards
	if [[ "${prompt}" == "yes" ]]; then
		if [[ "${manual_duplex}" == "yes" && "${batch_mode}" == "yes" ]]; then
			prompt_user "Prepare odd pages of next document and hit ENTER to continue (hit CTRL+D to exit)" ${prompt_timeout} || break
		elif [[ "${manual_duplex}" == "yes" ]]; then
			prompt_user "Prepare odd pages of document and hit ENTER to continue (hit CTRL+D to exit)" ${prompt_timeout} || break
			printn
		elif [[ "${batch_mode}" == "yes" ]]; then
			prompt_user "Prepare next document and hit ENTER to continue (hit CTRL+D to exit)" ${prompt_timeout} || break
			printn
		else
			prompt_user "Prepare document and hit ENTER to continue (hit CTRL+D to exit)" ${prompt_timeout} || break
			printn
		fi
	fi
	prompt="yes"

	# Determine next available output file based on output file pattern?
	if [[ "${outfile_pattern}" == "yes" ]]; then
		printh "Determining next output file..."
		for ((index++; index <= ${MAX_INDEX}; index++)); do
			printf -v outfile "${pattern}" "${index}"
			[[ -e "${outfile}" ]] || break
		done
		if (( ${index} > ${MAX_INDEX} )) || [[ -e "${outfile}" ]]; then
			printe "Error: failed to determine next output file (last candidate: ${outfile}), aborting"; result=1; break
		fi
		printn "Output file: ${outfile}"
	fi

	# Determine file name of output file (without leading path and extension)
	# NOTE:
	# Used to name TIFF files in temporary directory to avoid name clashing
	# while still having recognizable file names if user chooses to inspect
	# contents (using option '-k/--keep-temp')
	outfile_name="${outfile##*/}"; outfile_name="${outfile_name%.*}"

	# Perform manual duplex scan?
	if [[ "${manual_duplex}" == "yes" ]]; then
		# Scan odd pages (creates one TIFF file per page)
		# NOTE:
		# Using file name template '_page_%05d.tiff', starting with index 1
		# and incrementing by 2 after each page to leave gaps for even pages
		printh "Scanning odd pages..."
		opts=()
		opts+=("--device-name=${device}")
		opts+=("--mode=${mode}")
		opts+=("--resolution=${resolution}")
		opts+=("--source=${source}")
		in_array "${mode}" BRIGHTNESS_MODES && opts+=("--brightness=${brightness}")
		in_array "${mode}" CONTRAST_MODES && opts+=("--contrast=${contrast}")
		opts+=("-l" "${topleftx}")
		opts+=("-t" "${toplefty}")
		opts+=("-x" "${width}")
		opts+=("-y" "${height}")
		opts+=("--format=tiff")
		opts+=("--batch=${tempdir}/${outfile_name}_page_%05d.tiff")
		opts+=("--batch-start=1")
		opts+=("--batch-increment=2")
		opts+=("${SCANIMAGE_OPTS[@]}")
		print_cmd "scanimage" "${opts[@]}"
		scanimage "${opts[@]}" || { printe "Error: call to 'scanimage' failed (exit code: $?), aborting"; result=1; break; }

		# Prompt user to insert/prepare even pages of document
		if [[ "${batch_mode}" == "yes" ]]; then
			prompt_user "Prepare even pages of current document and hit ENTER to continue (hit CTRL+D to exit)" ${prompt_timeout} || break
		else
			printn
			prompt_user "Prepare even pages of document and hit ENTER to continue (hit CTRL+D to exit)" ${prompt_timeout} || break
			printn
		fi

		# Scan even pages (creates one TIFF file per page)
		# NOTE:
		# Using file name template '_page_%05d.tiff', starting with index 2
		# and incrementing by 2 after each page to fill the gaps in between
		# odd pages
		printh "Scanning even pages..."
		opts=()
		opts+=("--device-name=${device}")
		opts+=("--mode=${mode}")
		opts+=("--resolution=${resolution}")
		opts+=("--source=${source}")
		in_array "${mode}" BRIGHTNESS_MODES && opts+=("--brightness=${brightness}")
		in_array "${mode}" CONTRAST_MODES && opts+=("--contrast=${contrast}")
		opts+=("-l" "${topleftx}")
		opts+=("-t" "${toplefty}")
		opts+=("-x" "${width}")
		opts+=("-y" "${height}")
		opts+=("--format=tiff")
		opts+=("--batch=${tempdir}/${outfile_name}_page_%05d.tiff")
		opts+=("--batch-start=2")
		opts+=("--batch-increment=2")
		opts+=("${SCANIMAGE_OPTS[@]}")
		print_cmd "scanimage" "${opts[@]}"
		scanimage "${opts[@]}" || { printe "Error: call to 'scanimage' failed (exit code: $?), aborting"; result=1; break; }
	else
		# Scan pages (creates one TIFF file per page)
		# NOTE:
		# Using file name template '_page_%05d.tiff' (i.e. '_page_00001.tiff',
		# '_page_00002.tiff', etc.) to maintain correct page order when passing
		# files to 'tiffcp' using '_page_*.tiff' below
		printh "Scanning pages..."
		opts=()
		opts+=("--device-name=${device}")
		opts+=("--mode=${mode}")
		opts+=("--resolution=${resolution}")
		opts+=("--source=${source}")
		in_array "${mode}" BRIGHTNESS_MODES && opts+=("--brightness=${brightness}")
		in_array "${mode}" CONTRAST_MODES && opts+=("--contrast=${contrast}")
		opts+=("-l" "${topleftx}")
		opts+=("-t" "${toplefty}")
		opts+=("-x" "${width}")
		opts+=("-y" "${height}")
		opts+=("--format=tiff")
		opts+=("--batch=${tempdir}/${outfile_name}_page_%05d.tiff")
		opts+=("--batch-start=1")
		opts+=("--batch-increment=1")
		opts+=("${SCANIMAGE_OPTS[@]}")
		print_cmd "scanimage" "${opts[@]}"
		scanimage "${opts[@]}" || { printe "Error: call to 'scanimage' failed (exit code: $?), aborting"; result=1; break; }
	fi

	# Prefer using 'convert' (which is able to create PDF files directly from
	# separate TIFF files), fall back to 'tiffcp'/'tiff2pdf' if not available
	if is_cmd_avail "convert"; then
		# Create PDF file (from separate TIFF files)
		printh "Creating PDF file..."
		opts=()
		opts+=("${CONVERT_INPUT_OPTS[@]}")
		opts+=("${tempdir}/${outfile_name}_page_"*.tiff)
		opts+=("${CONVERT_OUTPUT_OPTS[@]}")
		opts+=("${outfile}")
		print_cmd "convert" "${opts[@]}"
		convert "${opts[@]}" || { printe "Error: call to 'convert' failed (exit code: $?), aborting"; result=1; break; }
	else
		# Merge pages (creates single multipage TIFF file from separate TIFF
		# files)
		printh "Merging pages..."
		opts=()
		opts+=("${TIFFCP_OPTS[@]}")
		opts+=("--")
		opts+=("${tempdir}/${outfile_name}_page_"*.tiff)
		opts+=("${tempdir}/${outfile_name}_multipage.tiff")
		print_cmd "tiffcp" "${opts[@]}"
		tiffcp "${opts[@]}" || { printe "Error: call to 'tiffcp' failed (exit code: $?), aborting"; result=1; break; }

		# Create PDF file (from multipage TIFF file)
		printh "Creating PDF file..."
		opts=()
		opts+=("${TIFF2PDF_OPTS[@]}")
		opts+=("-o" "${outfile}")
		opts+=("--")
		opts+=("${tempdir}/${outfile_name}_multipage.tiff")
		print_cmd "tiff2pdf" "${opts[@]}"
		tiff2pdf "${opts[@]}" || { printe "Error: call to 'tiff2pdf' failed (exit code: $?), aborting"; result=1; break; }
	fi

	# Break loop now if not in batch mode
	[[ "${batch_mode}" != "yes" ]] && break

	# Make some room
	printn

done

# Return result
exit ${result}
