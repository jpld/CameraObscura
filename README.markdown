plug-in executes asynchronously on the rising edge of the Capture input signal.

while the image output port is _not yet active_ (QCPlugInOutputImageProvider is confusing), the captured images are downloaded to ~/Desktop and when paired with a Directory Scanner patch the output can be fetched - see the included composition for an example.

lots of debug output is currently dumped to the console, give it a quick look for camera connection and recognition status. not all cameras support ImageCaptureCore's tethered shooting. those supported by this patch are likely to be similar to that of aperture 2 or greater. see below for a link to a list and additional usage and debugging information.
  <http://support.apple.com/kb/HT1085>