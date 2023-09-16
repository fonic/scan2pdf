# Scan to PDF (scan2pdf)
Scan documents directly to PDF file from the command line. Especially useful to batch-scan large volumes.

## Donations
I'm striving to become a full-time developer of [Free and open-source software (FOSS)](https://en.wikipedia.org/wiki/Free_and_open-source_software). Donations help me achieve that goal and are highly appreciated.

<a href="https://www.buymeacoffee.com/fonic"><img src="https://raw.githubusercontent.com/fonic/donate-buttons/main/buymeacoffee-button.png" alt="Buy Me A Coffee" height="35"></a>&nbsp;&nbsp;&nbsp;<a href="https://paypal.me/fonicmaxxim"><img src="https://raw.githubusercontent.com/fonic/donate-buttons/main/paypal-button.png" alt="Donate via PayPal" height="35"></a>&nbsp;&nbsp;&nbsp;<a href="https://ko-fi.com/fonic"><img src="https://raw.githubusercontent.com/fonic/donate-buttons/main/kofi-button.png" alt="Donate via Ko-fi" height="35"></a>

## Requirements
**Dependencies:**<br/>
_Bash (>=v4.0)_, _scanimage_ (part of [SANE](http://www.sane-project.org/)), _tiffcp_ and _tiff2pdf_ (part of [libtiff](http://libtiff.maptools.org/))

**Packages:**<br/>
Ubuntu: _bash_, _sane-utils_, _libtiff-tools_<br/>
Gentoo: _app-shells/bash_, _media-gfx/sane-backends_, _media-libs/tiff_

## Download & Installation
Refer to the [releases](https://github.com/fonic/scan2pdf/releases) section for downloads links. There is no installation required. Simply extract the downloaded archive to a folder of your choice.

## Configuration
Open `scan2pdf.conf` in your favorite text editor and adjust the settings to your liking. Refer to embedded comments for details. Refer to [this section](#configuration-options--defaults) for a listing of all configuration options and current defaults.

## Usage
To scan a document to PDF file, use the following commands:
```
$ cd scan2pdf-vX.Y
$ ./scan2pdf.sh document.pdf
```

Available command line options:
```
Usage: scan2pdf.sh [OPTIONS] OUTFILE

Scan to PDF (scan2pdf) v2.1 (09/16/23)
Scan documents directly to PDF file.

Options:
  -d, --device STRING       Scanner device ['brother4:net1;dev0']
  -m, --mode STRING         Color mode ['24bit Color']
                            'Black & White',
                            'Gray[Error Diffusion]',
                            'True Gray',
                            '24bit Color',
                            '24bit Color[Fast]'
  -r, --resolution VALUE    Scan resolution in dpi [300]
                            100, 150, 200, 300, 400, 600, 1200, 2400, 4800, 9600
  -s, --source STRING       Scan source ['Automatic Document Feeder(left aligned)']
                            'FlatBed',
                            'Automatic Document Feeder(left aligned)',
                            'Automatic Document Feeder(left aligned,Duplex)',
                            'Automatic Document Feeder(centrally aligned)',
                            'Automatic Document Feeder(centrally aligned,Duplex)'
  -b, --brightness VALUE    Brightness in percent (-50..50) [0]
                            (only applied if supported by color mode)
  -c, --contrast VALUE      Contrast in percent (-50..50) [0]
                            (only applied if supported by color mode)
  -l, --topleftx VALUE      Top left x offset of scan area in mm (0..216) [0]
  -t, --toplefty VALUE      Top left y offset of scan area in mm (0..356) [0]
  -x, --width VALUE         Width of scan area in mm (0..216) [216]
  -y, --height VALUE        Height of scan area in mm (0..356) [280]
  -k, --keep-temp           Keep temporary directory on exit
  -h, --help                Print usage information

NOTE:
Strings/values in square brackets show current defaults.
```

## Configuration Options & Defaults

Configuration options and current defaults:
```sh
# scan2pdf.conf

# -------------------------------------------------------------------------
#                                                                         -
#  Scan to PDF (scan2pdf)                                                 -
#                                                                         -
#  Created by Fonic <https://github.com/fonic>                            -
#  Date: 04/17/21 - 09/16/23                                              -
#                                                                         -
# -------------------------------------------------------------------------

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
```

##

_Last updated: 09/16/23_
