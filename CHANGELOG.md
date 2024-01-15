## Changelog for release v2.4

**Changes:**
- Changed workflow to either use `scanimage`+`convert` (preferred) -or-
  `scanimage`+`tiffcp`+`tiff2pdf` (fallback); `convert` is preferred as
  `tiff2pdf` might get removed from _LibTIFF_ in the future (see https://
  bugs.gentoo.org/914232)
- Updated dependency requirements in `README.md` to reflect new workflow
  (now, either _ImageMagick_ -or- _LibTIFF_ is required)
- Added output options for `convert` equivalent to those currently used for
  `tiff2pdf` (i.e. ZIP compression -or- JPEG compression, quality 95)
- Added command options to `Scan settings/parameters` listing printed to
  console

## Changelog for release v2.3

**Changes:**
- Added option `-a/--batch-scan` to allow scanning multiple documents in one
  go, prompting user in between documents (depends on option
  `-o/--outfile-pattern` for output file naming)
- Added option `-o/--outfile-pattern` that allows specifying OUTFILE command
  line argument as printf-style pattern (e.g. `~/Documents/Scan_%05d.pdf`)
  that is used to automatically determine the next available output file name
  by incrementing the integer part of the pattern
- Reordered configuration items to better highlight which settings to use for
  which paper size
- Removed configuration items that only make sense to be modified via command
  line options from configuration file (`BATCH_SCAN_DEFAULT`,
  `OUTFILE_PATTERN_DEFAULT`, `KEEP_TEMP_DEFAULT`)
- Eliminated need to `cd` to temporary directory by adding path to temporary
  directory to `--batch=` template of call to `scanimage`
- Added '--' to explicitely end option parsing to all external commands that
  support it
- Applied a few minor tweaks to printed output (wording, spacing)
- Extended headers in script and configuration file to 80 characters
- Reformatted `README.md` and `CHANGELOG.md` to be more readable when viewed
  in a simple text viewer/editor

## Changelog for release v2.2

Release has not been published (skipped ahead to release v2.3).

**Changes:**
- Added support for using `convert` (part of ImageMagick) instead of
  `tiff2pdf` (part of LibTIFF) as the latter is no longer being built by
  default and will probably be removed completely from from LibTIFF in the
  foreseeable future (see https://bugs.gentoo.org/914232)
- Added empty lines within usage information group similar items (e.g.
  brightness + contrast, topleftx + toplefty + width + height, etc.)
- If an output file is specified, abort if it already exists (instead of
  overwriting it)
- If no output file is specified, automatically choose the next available
  `scan_NNNNN.pdf` file name (i.e. `scan_00001.pdf`, `scan_00002.pdf`, etc.)
- Use `-e` for output file checks instead of `-f` (to catch non-file items
  like folders, fifos, sockets, etc. as well)

## Changelog for release v2.1

Initial release (versions prior to v2.1 have not been published).

**Features:**
- Highly configurable (both via configuration file and command line options)
- Allows selecting scan source, scan resolution and color mode
- Allows setting brightness and contrast (for color modes that support this)
- Allows specifying scan geometry (i.e. offset and dimensions of scan area)
- Lightweight with only few dependencies

##

_Last updated: 01/15/24_
