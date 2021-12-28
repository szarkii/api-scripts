# Overview

`szarkii-apps` is an application manager for organizing bash scripts. The scripts were made for very specific cases, so I don't expect anyone to use them, but they are available anyway. Rather, the goal is to manage and document scripts and use them across devices.

# Manager installation

Download manager script and place it in the directory belonging to `$PATH`. Please note that user should have appropriate privilages to access this dictionary (you can do it as a root).

```
curl https://raw.githubusercontent.com/rkowalik/api-scripts/szarkii-apps/bash/szarkii-apps/manager.sh > /usr/local/bin/szarkii-apps
chmod +x /usr/local/bin/szarkii-apps
```

# Applications

## szarkii-camstream

Simple stream Raspberry Pi camera. `szarkii-camstream` command will start streaming with 1024x768 resolution over HTTP on 11002 port.
You can use VLC to open network stream (e.g. http://192.168.0.1:110002).

```
szarkii-apps -i szarkii-camstream
```