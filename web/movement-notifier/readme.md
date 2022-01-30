# Overview

Simple web application for movement detection, based on NodeJS. It takes photos (using Raspberry Pi camera), compares two of them (using `szarkii-img-diff`) and if the similarity coefficient exceeds a certain threshold, sends a notification to the browser. The browser will show the snapshot and display alert.