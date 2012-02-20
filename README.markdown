## What 500px Aperture Uploader Is ##

[500px.com](http://500px.com/) is a pretty sweet photo sharing website, but they're taking their slow-ass time releasing an official Aperture Export plugin. This is a very basic Export plugin for Aperture that fills the gap in the meantime.

You can see a screenshot of the plugin [here](http://cloud.github.com/downloads/iKenndac/500px-Aperture-Uploader/LatestScreenshot.png).

## IMPORTANT ##

This plugin is something I threw together in less than 48 hours one weekend, so it isn't packed with features and it may be buggy. If you have any feature requests or encounter any bugs, please report them in the [Issues tab](https://github.com/iKenndac/500px-Aperture-Uploader/issues) on the project's home on GitHub.

## Donations ##

If you love this plugin, feel free to give me the [gift of awesome](https://500px.com/gift) - it'd be very much appreciated! *Especially* if you work at 500px and you're coming here wondering where all your new customers came from! 

## Requirements ##

This plugin requires Aperture 3.x and a Mac running Mac OS X 10.7 (Lion) or later.

## Downloading and Installing ##

If you'd like to download the plugin without building, you'll find periodic snapshot builds in the [Downloads section](https://github.com/iKenndac/500px-Aperture-Uploader/downloads) of the project's home on GitHub.

To install the plugin, place it in `~/Library/Application Support/Aperture/Plug-Ins/Export`. This folder tree may well be missing on your Mac - if so, just create them. Note: The Library folder in your home folder is hidden by default on Lion - you can get to it by holding down the Option/Alt key and choosing "Library" from the Finder's "Go" menu.

## Building ##

1. Clone using `git clone --recursive git://github.com/iKenndac/500px-Aperture-Uploader.git` to make sure you get all the submodules too.
2. If you got excited and cloned the repo before reading this, run `git submodule update --init` in the project's root directory to grab the submodules. If I get tickets about it not building and you haven't got the submodules checked out, you lose 5 internet points!
3. You'll need Apple's [Aperture SDK](http://connect.apple.com/cgi-bin/WebObjects/MemberSite.woa/wa/getSoftware?bundleID=20044).
4. Build away!

## Contact ##

I'm `iKenndac` on most services you'd care to mention, including [Twitter](http://twitter.com/iKenndac) and [500px](http://500px.com/iKenndac).
