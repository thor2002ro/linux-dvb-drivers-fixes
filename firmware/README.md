# Firmware for the bundled tuner paths

These vendor images are installed automatically by `make install`,
`./build.sh install` and the DKMS post-install hook. Installation verifies all
SHA-256 hashes before replacing files. No download is needed at install time.

| File | Bytes | Used by |
| --- | ---: | --- |
| `dvb-demod-mn88472-02.fw` | 2005 | Astrometa MN88472 demodulator |
| `dvb-demod-mn88473-01.fw` | 2271 | Astrometa MN88473 demodulator |
| `dvb-usb-dib0700-1.20.fw` | 33768 | Xbox One tuner DiB0700 USB bridge |

Run `make firmware-install KERNELRELEASE=<release>` to install just firmware.
The destination is `/lib/firmware/updates/<release>/`, the first standard
firmware search directory for that kernel. Existing files at that destination
are replaced; distribution copies elsewhere remain available. A custom
`firmware_class.path` kernel parameter takes precedence over standard paths.
`INSTALL_MOD_PATH=/path/to/root` prefixes the destination for staged installs.
The target does not require kernel headers.

Uninstalling modules leaves firmware in place, since the stock drivers use
the same images. Reconnect the tuner or reboot after installation to load it;
copying a file does not replace firmware already running on a device.

## Provenance

Both Panasonic images were extracted unchanged from the local Astrometa
`AMDVBT2_Setup_200917.exe` driver package. Its x86 and x64 `AMDVBT2BDA.sys`
images have SHA-256 hashes
`1882f3ba7b023c90a574371cf5c6217ef99f509f0a5f16b235eb1138a2432567` and
`aab59d46dbab73dc9ff0dacff01d89d472d110c97b14f8dfa0dc8faaa0a1b199`.
Firmware extracted independently from both architectures is byte-identical.

The MN88472 image matches the
[Palosaari latest image](https://palosaari.fi/linux/v4l-dvb/firmware/MN88472/02/088b891ac9273ff8c6818fca27b24d81/),
MD5 `088b891ac9273ff8c6818fca27b24d81` (driver 151102, archived November 2016).
The MN88473 image matches the
[Palosaari February 2016 image](https://palosaari.fi/linux/v4l-dvb/firmware/MN88473/01/2016-02-07/),
MD5 `bdb15b2311581db4c8411fca5e4ce3ce`; the previously downloaded 2014 and
latest copies have the same contents. Archive dates are distribution dates.

DiB0700 firmware was copied unchanged from the host's `linux-firmware` package
after decompression. Its redistribution terms are in [LICENSE.dib0700](LICENSE.dib0700).
The Panasonic images remain vendor firmware distributed in the Windows
package and public archive; the GPL headers on installer scripts do not
relicense those images. `SHA256SUMS` records the exact installed payloads.

These files cover the Astrometa and Xbox paths used by this project. Other
cards supported by the bridge drivers can require their own firmware; for
example, DiB9090 devices request `dib9090.fw` from the distribution.
