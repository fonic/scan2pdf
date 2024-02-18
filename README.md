# Scan to PDF (scan2pdf)
Scan documents directly to PDF files from the command line. Especially useful
to batch-scan large volumes of documents.


## Donations
I'm striving to become a full-time developer of [Free and open-source software
(FOSS)](https://en.wikipedia.org/wiki/Free_and_open-source_software). Donations
help me achieve that goal and are highly appreciated.

<a href="https://www.buymeacoffee.com/fonic"><img src="https://raw.githubusercontent.com/fonic/donate-buttons/main/buymeacoffee-button.png" alt="Buy Me A Coffee" height="35"></a>&nbsp;&nbsp;
<a href="https://paypal.me/fonicmaxxim"><img src="https://raw.githubusercontent.com/fonic/donate-buttons/main/paypal-button.png" alt="Donate via PayPal" height="35"></a>&nbsp;&nbsp;
<a href="https://ko-fi.com/fonic"><img src="https://raw.githubusercontent.com/fonic/donate-buttons/main/kofi-button.png" alt="Donate via Ko-fi" height="35"></a>


## Requirements
**Dependencies:**<br/>
_Bash_              (&ge;v4.0),
_scanimage_         (part of [SANE](http://www.sane-project.org/)),
_convert_           (part of [ImageMagick](https://www.imagemagick.org/))
-or-
_tiffcp_/_tiff2pdf_ (part of [LibTIFF](http://libtiff.maptools.org/))

**Packages:**<br/>
Ubuntu: _bash_, _sane-utils_, _imagemagick_ -or- _libtiff-tools_<br/>
Gentoo: _app-shells/bash_, _media-gfx/sane-backends_, _media-gfx/imagemagick_
         -or- _media-libs/tiff_


## Download & Installation
Refer to the [releases](https://github.com/fonic/scan2pdf/releases) section
for downloads links. There is no actual installation required. Simply extract
the downloaded archive to a folder of your choice.

For [KDE](https://kde.org/) file managers
[Konqueror](https://apps.kde.org/konqueror/) and
[Dolphin](https://apps.kde.org/dolphin/), a
[Service Menu](#service-menu) is included that allows for convenient one-click
scanning to PDF file from within the context menu.


## Configuration
Open `scan2pdf.conf` in your favorite text editor and adjust the settings
to your liking. Refer to embedded comments for details. Refer to
[this section](#configuration-options) for a listing of configuration options
and current defaults.


## Quick Start
To scan a single document to PDF file, use the following command:
```
$ ./scan2pdf.sh document.pdf
```

To scan multiple documents to PDF files, use the following command:
```
$ ./scan2pdf.sh -a -o document_%05d.pdf
```

See [this section](#command-line-options) for a detailed list of command line
options.


## Contributing

_Scan to PDF (scan2pdf)_ has mainly been tested with _Brother_ printers.
If you own a printer manufactured by _HP_, _Canon_, _Epson_ or some other
well-established brand and would like to help with adding support, please
create an [issue on GitHub](https://github.com/fonic/scan2pdf/issues) and
provide the output of `scanimage --help`.


## Service Menu

To use the _Service Menu_, which provides a _Scan to PDF_ entry in the
right-click context menu of [KDE](https://kde.org/) file managers
[Konqueror](https://apps.kde.org/konqueror/) and
[Dolphin](https://apps.kde.org/dolphin/), simply copy/move `scan2pdf.desktop`
to `~/.local/share/kio/servicemenus` and make sure `scan2pdf.sh` is stored in
a location accessible via `PATH`.

Advanced users might want to edit and customize `scan2pdf.desktop` (which is
an INI-style text file) to their liking (e.g. to change scan sources, color
modes, scan resolutions, path to `scan2pdf.sh`, etc.).

Screenshot:

![Screenshot](https://raw.githubusercontent.com/fonic/scan2pdf/main/SERVICEMENU.png)


## Command Line Options

Available command line options:
```
Usage: scan2pdf.sh [OPTIONS] OUTFILE

Scan to PDF (scan2pdf) v2.6 (02/18/24)
Scan documents directly to PDF files.

Options:
  -d, --device STRING           Scanner device ['brother3:net1;dev0']
  -m, --mode STRING             Color mode ['24bit Color']
                                'Black & White',
                                'Gray[Error Diffusion]',
                                'True Gray',
                                '24bit Color',
                                '24bit Color[Fast]'
  -r, --resolution VALUE        Scan resolution in dpi [300]
                                100, 150, 200, 300, 400, 600, 1200, 2400, 4800, 9600
  -s, --source STRING           Scan source ['Automatic Document Feeder(left aligned)']
                                'FlatBed',
                                'Automatic Document Feeder(left aligned)',
                                'Automatic Document Feeder(left aligned,Duplex)',
                                'Automatic Document Feeder(centrally aligned)',
                                'Automatic Document Feeder(centrally aligned,Duplex)'

  -b, --brightness VALUE        Brightness in percent (-50..50) [0]
                                (only applied if supported by color mode)
  -c, --contrast VALUE          Contrast in percent (-50..50) [0]
                                (only applied if supported by color mode)

  -x, --topleftx VALUE          Top left x offset of scan area in mm (0..216) [0]
  -y, --toplefty VALUE          Top left y offset of scan area in mm (0..356) [0]
  -w, --width VALUE             Width of scan area in mm (0..216) [210]
  -e, --height VALUE            Height of scan area in mm (0..356) [297]

  -u, --manual-duplex           Scan odd pages, prompt, scan even pages, interleave
                                odd and even pages to produce combined output [no]

  -a, --batch-mode              Scan multiple documents, prompt in between documents
                                (makes option '-p/--outfile-pattern' mandatory) [no]
  -p, --outfile-pattern         Interpret OUTFILE argument as printf-style pattern,
                                determine next output file by incrementing integer
                                token (e.g. '~/Documents/Scan_%05d.pdf') [no]

  -i, --initial-prompt          Prompt before first scan operation (e.g. before odd
                                pages for manual duplex or before first document in
                                batch mode) [no]
  -t, --prompt-timeout VALUE    Timeout for prompts in seconds (0 == no timeout) [0]
                                Allows duplex- and/or batch-scanning without having
                                to press ENTER to continue when being prompted

  -k, --keep-temp               Keep temporary directory on exit [no]

  -h, --help                    Print usage information

NOTE:
Strings/values in square brackets show current defaults.
```


## Configuration Options

Configuration options and current defaults:
```sh
# scan2pdf.conf

# ------------------------------------------------------------------------------
#                                                                              -
#  Scan to PDF (scan2pdf)                                                      -
#                                                                              -
#  Created by Fonic <https://github.com/fonic>                                 -
#  Date: 04/17/21 - 02/18/24                                                   -
#                                                                              -
# ------------------------------------------------------------------------------

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
```

##

_Last updated: 02/18/24_
