# Firmware

The firmware is built with PlatformIO and esp-idf.

## Project Status

Generally, things work but code quality is poor.
The firmware was originally written very fast for rapid development and iteration.
There has been a push to refactor out low-quality code but significant time constraints have made this challenging.
New features (WiFi, Bluetooth) are well-written, but some other components have hacks upon hacks and inefficient design.
The system works "well enough" at present.

## Patches

To work around limitations in the esp-idf, we maintain a series of patches in the firmware source that are applied to PlatformIO's esp-idf.
The patches are located in `/firmware/patches/`.
We use the python script method based on [this PlatformIO document](https://docs.platformio.org/en/stable/scripting/examples/override_package_files.html).

Current patches deal with Protocomm NimBLE, adding a few points for our custom Bluetooth code to hook into.

### Patch workflow

Patches are automatically applied to the esp-idf when building the project (see above).
Note that the patches are (unfortunately) applied to the global esp-idf installation (no known workaround at this time).

Patches are a maintenance burden and should be avoided whenever possible.
To create a new patch, Git is the recommended workflow.
Checkout the target project in git, make your changes directly to that source tree, and then run `git diff > output.patch` to generate a patchfile.
You'll need to modify the python script `apply_patches.py` to include your new patchfile.

## Building

Use `pio run`.  Output is in `.pio/build/esp32dev`.
Files included in a release are `partitions.bin`, `ota_data_initial.bin`, `firmware.bin` and `bootloader.bin`.

### CI/CD

The firmware is automatically built and bundled into a ZIP by Github Actions every time there is a successful push to master.
The workflow file is `firmware.yml`.

Note that the firmware is **not** automatically deployed to end-users (this is a manual process, see below).

The latest firmware bundle can be accessed on Github under the "Actions" tab, selecting the run, and downloading the file under "Artifacts".

## Versioning

There are effectively three different version numbers.

1. Build number - the Github Action automatically adds an incrementing number into the `FIRMWARE_BUILD` macro in `config.h`.
2. Revision number - this is the primary major "version" of the firmware, used in OTA firmware updates.
    Major changes should bump this number in the `FIRMWARE_REVISION` macro in `config.h`.
    The OTA update system won't accept an update if this version number stays the same.
3. Espressif-defined version, which is a Git hash of the repository when the firmware was built.
    We don't use this.

The build number is appended to the firmware bundle ZIP file name.

## Manual Flashing

Manual flashing inside PlatformIO is easy, just use the "Upload" task in the PlatformIO pane.

Installing a firmware bundle without PlatformIO requires the [ESP flash download tool](https://www.espressif.com/en/support/download/other-tools)
and a serial-to-USB dongle that supports DTR and RTS (Brendan uses an FTDI-based one).
Wire up your dongle to RTS, RXD, TXD, GND, and DTR.

Run the flash download tool in ESP32/develop mode.
Configure the partitions as follows:

* `bootloader.bin` - 0x1000
* `firmware.bin` - 0x10000
* `ota_data_initial.bin` - 0xd000
* `partitions.bin` - 0x8000

## Over-the-air updates

We have three mechanisms to deliver OTA firmware updates.
All methods are designed to be pushed out/initiated from the mobile app.

The first one registers two custom endpoints with protocomm (`fw-version` and `update-fw`).
This is the only provisioning method available before provisioning is complete.
The `fw-version` endpoint accepts a firmware version and replies with the currently installed firmware version.
The `update-fw` endpoint accepts the firmware and begins writing it to the partition
This method is unfortunately very slow, but is available before provisioning.

The second one is equivalent to the first, except using our own BLE characteristic (not tied to protcomm).
Thus, this method is only available after provisioning is complete.

The last one accepts the firmware via the HTTP POST to `/update`.
It is the fastest method, but is only available after provisioning and requires the phone to be on the same WiFi network as the device.

(There is currently no support in the app to use the OTA update endpoints, stopgap solution downloads the latest firmware on-device)

We use the two-slot OTA partitioning method. Note that due to firmware size constraints, **the factory partition is not used and is reclaimed space**.
The firmware runs off of one slot and writes incoming OTA updates to the alternate partition.
On the next boot, the bootloader attempts to load off the alternate partition and switches back to the original if it can't boot.

## Deploying an update

Deploying a firmware update pushes it out to end-users, making it available for over-the-air firmware updates.

1. Increment the revision number in `config.h` (see above).
2. Build the firmware. You only need `firmware.bin`.
3. Move the `firmware.bin` to `backend/src/main/resources/firmware_latest.net` (overwriting the existing file). 
4. Copy the `firmware.bin` again to `backend/src/main/resources/firmware_{REVISION NUMBER}.bin`, making sure the proper revision number is appended to the end of the file name.
5. Edit `backend/src/main/java/jct/pillorganizer/service/FirmwareService.java` and replace the `getLatestVersion` return value to the new revision number.
6. Build and deploy the backend (push to Github and let the actions take care of deployment).

The update will be immediately available to all users, but may take time for all devices to process the update.
