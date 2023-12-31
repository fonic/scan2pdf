#!/usr/bin/env bash

# -------------------------------------------------------------------------
#                                                                         -
#  Scan to PDF (scan2pdf)                                                 -
#                                                                         -
#  Created by Fonic <https://github.com/fonic>                            -
#  Date: 04/17/21 - 09/16/23                                              -
#                                                                         -
#  Based on:                                                              -
#  https://gist.github.com/mludvig/936678                                 -
#                                                                         -
# -------------------------------------------------------------------------

# --------------------------------------
#                                      -
#  Early Tasks                         -
#                                      -
# --------------------------------------

# Check if running Bash and required version (check does not rely on any
# Bashisms to ensure it works on any POSIX-compliant shell)
if [ -z "${BASH_VERSION}" ] || [ "${BASH_VERSION%%.*}" -lt 4 ]; then
	echo "This script requires Bash >= 4.0 to run."
	exit 1
fi


# --------------------------------------
#                                      -
#  Globals                             -
#                                      -
# --------------------------------------

# Script information
SCRIPT_FILE="$(basename "$0")"
SCRIPT_PATH="$(realpath "$0")"
SCRIPT_CONF="${SCRIPT_PATH%.*}.conf"
SCRIPT_TITLE="Scan to PDF (scan2pdf)"
SCRIPT_VERSION="2.1 (09/16/23)"

# Usage information
# NOTE:
# Tokens '%{...}' are replaced with dynamically generated contents; Variable
# expansion is deferred until printing (to account for sourced configuration)
USAGE_INFO="\e[1mUsage:\e[0m \${SCRIPT_FILE} [OPTIONS] OUTFILE

\e[1m\${SCRIPT_TITLE} v\${SCRIPT_VERSION}\e[0m
Scan documents directly to PDF file.

\e[1mOptions:\e[0m
  -d, --device STRING       Scanner device ['\${DEVICE_DEFAULT}']
  -m, --mode STRING         Color mode ['\${MODE_DEFAULT}']
                            %{COLOR_MODES}
  -r, --resolution VALUE    Scan resolution in dpi [\${RESOLUTION_DEFAULT}]
                            %{SCAN_RESOLUTIONS}
  -s, --source STRING       Scan source ['\${SOURCE_DEFAULT}']
                            %{SCAN_SOURCES}
  -b, --brightness VALUE    Brightness in percent (\${BRIGHTNESS_MIN}..\${BRIGHTNESS_MAX}) [\${BRIGHTNESS_DEFAULT}]
                            (only applied if supported by color mode)
  -c, --contrast VALUE      Contrast in percent (\${CONTRAST_MIN}..\${CONTRAST_MAX}) [\${CONTRAST_DEFAULT}]
                            (only applied if supported by color mode)
  -l, --topleftx VALUE      Top left x offset of scan area in mm (\${TOPLEFTX_MIN}..\${TOPLEFTX_MAX}) [\${TOPLEFTX_DEFAULT}]
  -t, --toplefty VALUE      Top left y offset of scan area in mm (\${TOPLEFTY_MIN}..\${TOPLEFTY_MAX}) [\${TOPLEFTY_DEFAULT}]
  -x, --width VALUE         Width of scan area in mm (\${WIDTH_MIN}..\${WIDTH_MAX}) [\${WIDTH_DEFAULT}]
  -y, --height VALUE        Height of scan area in mm (\${HEIGHT_MIN}..\${HEIGHT_MAX}) [\${HEIGHT_DEFAULT}]
  -k, --keep-temp           Keep temporary directory on exit
  -h, --help                Print usage information

\e[1mNOTE:\e[0m
Strings/values in square brackets show current defaults."

# Indent of option descriptions in usage information (used to properly align
# dynamically generated contents, i.e. when replacing '%{...}' tokens)
USAGE_INDENT=28


# --------------------------------------
#                                      -
#  Configuration                       -
#                                      -
# --------------------------------------

# NOTE:
# Turn scanner on and run 'scanimage --help' to get detailed information
# on supported parameters and/or valid values for scan-related settings

# Default scanner device (string)
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
#WIDTH_DEFAULT=210              # DIN A4 (210.0 mm / 8.3 in)
WIDTH_DEFAULT=216               # Letter/Legal (215.9 mm / 8.5 in)
HEIGHT_MIN=0
HEIGHT_MAX=356
#HEIGHT_DEFAULT=297             # DIN A4 (297.0 mm / 11.7 in)
#HEIGHT_DEFAULT=356             # Legal (355.6 mm / 14.0 in)
HEIGHT_DEFAULT=280              # Letter (279.4 mm / 11.0 in)

# Options passed to 'scanimage' (array of strings)
#SCANIMAGE_OPTS=("--progress" "--verbose")  # display scan progress, use verbose output
SCANIMAGE_OPTS=("--progress")   # display scan progress

# Options passed to 'tiffcp' (array of strings)
TIFFCP_OPTS=("-c" "lzw")        # use LZW compression (fast)

# Options passed to 'tiff2pdf' (array of strings)
#TIFF2PDF_OPTS=("-z")           # use ZIP compression (lossless, higher quality, bigger PDF file)
TIFF2PDF_OPTS=("-j" "-q" "95")  # use JPEG compression (quality 95) (lossy, lower quality, smaller PDF file)

# Keep temporary directory on exit by default (string, 'yes'/'no')
KEEPTEMP_DEFAULT="no"


# --------------------------------------
#                                      -
#  Functions                           -
#                                      -
# --------------------------------------

# Print normal/hilite/good/warn/error message [$*: message]
function printn() {
	echo -e "$*"
}
function printh() {
	echo -e "\e[1m$*\e[0m"
}
function printg() {
	echo -e "\e[1;32m$*\e[0m"
}
function printw() {
	echo -e "\e[1;33m$*\e[0m"
}
function printe() {
	echo -e "\e[1;31m$*\e[0m"
}

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

# Print error message and exit [$1: error message, $2: exit code (optional,
# defaults to 1)]
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


# --------------------------------------
#                                      -
#  Main                                -
#                                      -
# --------------------------------------

# Set up error handling (exit on unbound variables and on unhandled errors)
set -ueE; trap "printe \"Error: an unhandled error occurred on line \${LINENO}, aborting\"; exit 1" ERR

# Set up trap to handle CTRL+C/SIGINT
trap "set +e; trap - ERR; echo -en \"\r\e[2K\"; printw \"Aborting per user request (CTRL+C/SIGINT)\"; exit 130" INT

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
	eval "printn \"${USAGE_INFO}\""
	exit 0
fi

# Print title, set up cosmetic exit trap (will be replaced later)
printn
printh "--==[ ${SCRIPT_TITLE} v${SCRIPT_VERSION} ]==--"
printn
trap "printn" EXIT

# Initialize settings with defaults
for item in device mode resolution source brightness contrast topleftx toplefty width height keeptemp; do
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
		-l|--topleftx)
			getarg topleftx || { printe "Error: option '${option}' requires an argument"; result=1; continue; }
			is_integer "${topleftx}" ${TOPLEFTX_MIN} ${TOPLEFTX_MAX} || { printe "Error: invalid top left x value '${topleftx}'"; result=1; continue; }
			;;
		-t|--toplefty)
			getarg toplefty || { printe "Error: option '${option}' requires an argument"; result=1; continue; }
			is_integer "${toplefty}" ${TOPLEFTY_MIN} ${TOPLEFTY_MAX} || { printe "Error: invalid top left y value '${toplefty}'"; result=1; continue; }
			;;
		-x|--width)
			getarg width || { printe "Error: option '${option}' requires an argument"; result=1; continue; }
			is_integer "${width}" ${WIDTH_MIN} ${WIDTH_MAX} || { printe "Error: invalid width value '${width}'"; result=1; continue; }
			;;
		-y|--height)
			getarg height || { printe "Error: option '${option}' requires an argument"; result=1; continue; }
			is_integer "${height}" ${HEIGHT_MIN} ${HEIGHT_MAX} || { printe "Error: invalid height value '${height}'"; result=1; continue; }
			;;
		-k|--keep-temp)
			keeptemp="yes"
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
[[ -n "${outfile+set}" ]] || { printe "Error: no output file specified"; result=1; }
(( ${result} == 0 )) || { printe "Error: invalid command line, use '--help' to display usage information"; exit 2; }

# Check command availability
result=0
for cmd in scanimage tiffcp tiff2pdf; do
	is_cmd_avail "${cmd}" || { printe "Error: command '${cmd}' is not available"; result=1; }
done
(( ${result} == 0 )) || { printe "Error: missing required command(s), check dependencies"; exit 1; }

# Print scan settings
printh "Scan settings:"
printn "Device:      ${device}"
printn "Mode:        ${mode}"
printn "Resolution:  ${resolution} dpi"
printn "Source:      ${source}"
in_array "${mode}" BRIGHTNESS_MODES && printn "Brightness:  ${brightness}%"
in_array "${mode}" CONTRAST_MODES && printn "Contrast:    ${contrast}%"
printn "Top left x:  ${topleftx} mm"
printn "Top left y:  ${toplefty} mm"
printn "Width:       ${width} mm"
printn "Height:      ${height} mm"
printn "Keep temp:   ${keeptemp}"
printn "Output file: ${outfile}"

# Create temporary directory, set up exit trap for cleanup (replaces pre-
# viously set up cosmetic exit trap)
printh "Creating temporary directory..."
tempdir="$(mktemp -d)" || { printe "Error: failed to create temporary directory, aborting"; exit 1; }
trap "set +e; trap - ERR; if [[ \"${keeptemp}\" == \"yes\" ]]; then printw \"Keeping temporary directory '${tempdir}'\"; else rm -rf \"${tempdir}\"; fi; printn" EXIT
printn "Path: ${tempdir}"

# Scan pages (creates one TIFF file per page)
# NOTE:
# Using file name template 'page_%010d.tiff' ('page_0000000001.tiff', 'page_
# 0000000002.tiff', etc.) to maintain correct page order when passing files
# to 'tiffcp' using 'page_*.tiff' below
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
opts+=("--batch=page_%010d.tiff")
opts+=("${SCANIMAGE_OPTS[@]}")
print_cmd "scanimage" "${opts[@]}"
cd "${tempdir}" || { printe "Error: failed to change directory to '${tempdir}', aborting"; exit 1; }
scanimage "${opts[@]}" || { printe "Error: call to 'scanimage' failed (exit code: $?), aborting"; exit 1; }
cd - >/dev/null || :

# Merge pages (creates multipage TIFF file)
printh "Merging pages..."
opts=("${TIFFCP_OPTS[@]}")
opts+=("${tempdir}"/page_*.tiff "${tempdir}/multipage.tiff")
print_cmd "tiffcp" "${opts[@]}"
tiffcp "${opts[@]}" || { printe "Error: call to 'tiffcp' failed (exit code: $?), aborting"; exit 1; }

# Create PDF file (from multipage TIFF file)
printh "Creating PDF..."
opts=("${TIFF2PDF_OPTS[@]}")
opts+=("${tempdir}/multipage.tiff" "-o" "${outfile}")
print_cmd "tiff2pdf" "${opts[@]}"
tiff2pdf "${opts[@]}" || { printe "Error: call to 'tiff2pdf' failed (exit code: $?), aborting"; exit 1; }

# Return home safely
printg "Success, all done."
exit 0
