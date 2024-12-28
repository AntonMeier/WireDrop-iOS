[![License](https://img.shields.io/badge/license-GPLv3-green)](LICENSE)
[![App Store](https://img.shields.io/itunes/v/6480213232?label=App%20Store&color=038BFD)](https://apps.apple.com/us/app/wiredrop/id6480213232)

<div align="center">

<picture>
<source srcset="https://github.com/user-attachments/assets/a31e48a2-8982-4306-9073-f5270d931409" media="(prefers-color-scheme: dark)">
<img width="305" src="https://github.com/user-attachments/assets/7ac103c9-e737-4ba3-9c3b-e897af1cc2c7">
</picture>

<br>
<br>

<p>Open Source USB file transfer app for iOS and macOS.</p>

<picture>
<source srcset="https://github.com/user-attachments/assets/6a4fe6c5-4e9b-4cb0-a4e8-f3f44ee03683" media="(prefers-color-scheme: dark)">
<img width="456" src="https://github.com/user-attachments/assets/6e2354c7-beb1-4a8b-ac32-c01c2de1dcd1">
</picture>

<br>
<br>
<a href="https://wiredrop.app">wiredrop.app</a>
</div>

# About ℹ️

WireDrop lets you transfer files between your iOS and macOS devices via USB cable. This can be useful in situations where other means of transferring files (ex AirDrop) is not possible, such as, if you have WiFi or Bluetooth disabled.

**System requirements**
* iOS device running iOS 16.0 or later.
* Mac running macOS 14.0 (Sonoma) or later.

**Usage**
* **iOS to macOS**: WireDrop will appear as a share option inside the regular iOS share sheet. As long as you have the USB cable attached, and the WireDrop companion app running on your Mac, you will be able to quickly transfer files.
* **macOS to iOS**: Open the WireDrop app on your iOS device. On your Mac, you can now drag-and-drop your files to the WireDrop main window to start the transfer. Once all files are transferred, a share sheet will appear in the iOS app, allowing you to choose where to save the files.

# Getting Started :memo:

For those who just want to start using the application right away, you can download the latest version from the iOS App Store. See [wiredrop.app](https://wiredrop.app) for more information.

If you want to install and run the code from source, the setup is fairly straightforward as well:

1. Clone the repository
2. In the project's root, create a new folder `/Configuration`
3. In this new folder, create 3 new files: `project-ios-app.xcconfig`, `project-macos-app.xcconfig`, and `project-ios-extension.xcconfig`. These files will contain your personal configuration details for each Xcode target, such as `PRODUCT_BUNDLE_IDENTIFIER`, `DEVELOPMENT_TEAM`. Templates for each file can be found under [Configuration FIle Templates](https://github.com/AntonMeier/WireDrop-iOS/wiki/Configuration-FIle-Templates).

![XCConfig](https://github.com/user-attachments/assets/a0cb5d8c-d4c8-4e0d-babd-607419313547)

4. You can now open the `WireDrop.xcodeproj` Xcode project file. If the config files have been added correctly, you should be able to build the WireDrop target without errors.

_For the macOS app, I am using a Developer ID Application profile, but this may or may not be suitable for your needs. If you only wish to build the iOS targets, you can ignore the configuration file for macOS._

# Contributing To WireDrop :construction_worker:

Currently, there is no list of specific features in need of development, but you are welcome contribute if you come up with something useful. This could be to improve documentation, suggest new features, report issues, fix bugs, or even create design assets.

# License :mag_right:

The source code for WireDrop is released under the GNU General Public License V3 (GPLv3) License, as outlined in [LICENSE](LICENSE).
Please contact me if you are unsure of the implications of this, or if you have other specific licensing requests.

The marketing name "WireDrop", along with the WireDrop icon, is not covered by GPLv3.

# Questions :question:

If you have a question directly related to the source code, that you feel may be of interest to other developers as well, then feel free to open an issue here on GitHub.
Otherwise, you can get in touch with me via [wiredrop.app/contact](https://wiredrop.app/contact)

