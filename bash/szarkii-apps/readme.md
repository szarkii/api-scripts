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

## szarkii-csv-jobs

Helps with processing multiple files - executes commands from CSV file. Creates a CSV file and appends all files paths from the current directory. You can define bash command in the first column. You can use other columns as arguments (by its numbers).

The `szarkii-csv-jobs --create` command, exectued in `/files/music` will create `music.csv` file containing:

| command | file             |
| ------- | ---------------- |
|         | /files/file1.mp3 |
|         | /files/file2.mp3 |

You can define command freely. This CSV file:

| command                         | file             | track |
| ------------------------------- | ---------------- | ----- |
| szarkii-music-metadata -t $3 $2 | /files/file1.mp3 | 1     |
| szarkii-music-metadata -t $3 $2 | /files/file2.mp3 | 2     |

will produce and execute the following commands:

```
szarkii-music-metadata -t "1" "/files/file1.mp3"
szarkii-music-metadata -t "2" "/files/file2.mp3"
```

## szarkii-music-metadata

Sets metadata to music files. Downloads the file if URL provided.

**Dependencies**: kid3-cli

## szarkii-img-diff

The script checks how similar the images are and retruns the number. The greater value means more similarity. If images are identical the "inf" value is returned.

**Dependencies**: magick (https://imagemagick.org/script/download.php)

## szarkii-vid-diff

Checks that the video shows static content that does not change over the course of the video.
The script creates a snapshot of a frame every second. Depending on the detected differences, all snapshot will be moved to the diffrent dictionaries.

Increasing the similarity threshold and the number of frames to be checked increases the accuracy and time of script execution.

**Dependencies**: szarkii-img-diff

## szarkii-vid-convert

Convert video into another format. Dedicated for converting all files in the given directory.

**Dependencies**: ffmpeg

## szarkii-camstream

Simple stream Raspberry Pi camera. `szarkii-camstream` command will start streaming with 1024x768 resolution over HTTP on 11002 port. App uses `libcamera-vid` or `raspivid` depending on Raspian version.
You can use VLC to open network stream (e.g. http://192.168.0.1:110002 (Buster) or tcp/h264://192.168.0.1:110002 (BullsEye)).

## szarkii-rec

Record videos using Raspberry Pi camera.

## szarkii-merge-vid

Merge multiple videos into one file.

**Dependencies**: ffmpeg