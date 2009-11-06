[CameraObscura](http://github.com/jpld/CameraObscura/)
=============
quartz composer plug-in to trigger capture from a tethered camera. patch executes asynchronously on the rising edge of the Capture Signal input.

[Download - CameraObscura_v0.1.zip](http://cloud.github.com/downloads/jpld/CameraObscura/CameraObscura_v0.1.zip)

while the image output port is not yet active, the captured images are downloaded to ~/Desktop and when paired with a Directory Scanner patch the output can be fetched - see the included composition _Camera Capture.qtz_ for an example of this in action.

lots of debug output is currently dumped to the console, give it a quick look for camera connection and recognition status. not all cameras support ImageCaptureCore's tethered shooting. those supported by this patch are likely to be similar to that of aperture 2 or greater. see below for a link to a list and additional usage and debugging information. one may need to try PTP or PC Connection camera communication mode to find a successful pairing.
  <http://support.apple.com/kb/HT1085>