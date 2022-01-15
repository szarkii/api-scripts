# Overview

`szarkii-apps` is an application manager for organizing bash scripts. The scripts were made for very specific cases, so I don't expect anyone to use them, but they are available anyway. Rather, the goal is to manage and document scripts and use them across devices.

# Manager installation

Download manager script and place it in the directory belonging to `$PATH`. Please note that user should have appropriate privilages to access this dictionary (you can do it as a root - `sudo su`).

```
curl https://raw.githubusercontent.com/rkowalik/api-scripts/szarkii-apps/bash/szarkii-apps/apps-manager.sh > /usr/local/bin/szarkii-apps
chmod +x /usr/local/bin/szarkii-apps
```

Now the manager can be used to install or update the applications, i.e.:

```
# Install application
szarkii-apps -i szarkii-img-diff
# Updated all installed applications 
szarkii-apps -u
```

# Applications

## szarkii-img-diff

The script checks how similar the images are and retruns the number. The greater value means more similarity. If images are identical the "inf" value is returned.

**Dependencies**: magick (https://imagemagick.org/script/download.php)

```
szarkii-apps -i szarkii-img-diff
```

## szarkii-vid-diff

Checks that the video shows static content that does not change over the course of the video.
The script creates a snapshot of a frame every second. Depending on the detected differences, all snapshot will be moved to the diffrent dictionaries.

Increasing the similarity threshold and the number of frames to be checked increases the accuracy and time of script execution.

**Dependencies**: szarkii-img-diff

```
szarkii-apps -i szarkii-vid-diff
```

## szarkii-vid-convert

Convert video into another format. Dedicated for converting all files in the given directory.

**Dependencies**: ffmpeg

```
szarkii-apps -i szarkii-vid-convert
```

## szarkii-camstream

Simple stream Raspberry Pi camera. `szarkii-camstream` command will start streaming with 1024x768 resolution over HTTP on 11002 port. App uses `libcamera-vid` or `raspivid` depending on Raspian version.
You can use VLC to open network stream (e.g. http://192.168.0.1:110002).

```
szarkii-apps -i szarkii-camstream
```

## szarkii-rec

Record videos using Raspberry Pi camera.

```
szarkii-apps -i szarkii-rec
```

## szarkii-merge-vid

Merge multiple videos into one file.

**Dependencies**: ffmpeg.

```
szarkii-apps -i szarkii-merge-vid
```