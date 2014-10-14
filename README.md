MCamera 

MCamera is a class using the camera features of AVFoundation.It is easy to use the camera features and install your iOS Apps.
This class can control lots of camera parameters manually in later version of iOS8.

# How to use

1. drag&drop MCamera.m and MCamera.h into your project.

2. call the function "start"

That's it!


# Example

@property MCamera *camera;
@property UIImageView *preview;

...

// initialize your MCamera
self.camera = [[MCamera alloc]init];

// start your MCamera
// captured images will be shown in self.preview
[self.camera start: self.preview];

...

// take a picture
UIImage *image = [self.camera capture];


# Controllable camera parameters

Here are currently custamable camera parameters below.
Other parameters (e.g. White Balance, Bias,...) will be custamable soon!

*Focus Length

*Exposure Duration

*ISO


(https://github.com/MthrNakamura/MCamera)