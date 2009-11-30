[CameraObscura](http://github.com/jpld/CameraObscura/)
=============
quartz composer plug-in to trigger capture from a tethered camera. patch acts on the rising edge of the Capture Signal input and provides image output asynchronously, as indicated by the Done Signal.

[Download - CameraObscura-0.3.0.zip](http://cloud.github.com/downloads/jpld/CameraObscura/CameraObscura-0.3.0.zip)

to install from the binary download, move _CameraObscura.plugin_ to _~/Library/Graphics/Quartz Composer Plug-Ins/_, and to install from source, simply build the _Build & Copy_ project target.

when run, the patch will select the first camera detected that supports tethered shooting and the camera selection is not yet serialized through a composition save.

the debug builds dump lots of messages to the console, give it a quick look for camera connection and recognition status. not all cameras support ImageCaptureCore's tethered shooting. those supported by this patch are likely to be similar to that of aperture 2+ and Image Capture (refer to the buggy Take Picture action accessible from the File menu). see link below for a supported camera list and additional usage and debugging information. one may need to try PTP or PC Connection camera communication mode to find a successful pairing.
<http://support.apple.com/kb/HT1085>
