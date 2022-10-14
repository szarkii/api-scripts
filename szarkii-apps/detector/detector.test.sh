#!/bin/bash

function test() {
    echo "[TEST]: $1"
    echo "$ $2"
    out=$(exec $2)

    successesNumber=0
    failuresNumber=0

    for expected in "${@: 3}"; do
        if [[ "$out" = *"$expected"* ]]; then
            echo "[SUCCESS]: '$expected' found"
            successesNumber=$((successesNumber+1))
        else
            echo "[FAILURE]: '$expected' not found."
            failuresNumber=$((failuresNumber+1))
        fi
    done

    if [[ $failuresNumber -eq 0 ]]; then
        echo "[SUCCESS]: All tests passed!"
    else
        echo "[FAILURE]: $failuresNumber test(s) failed. Output:"
        echo "$out"
    fi

    echo "=============================="
}

test    "Test default values" \
        "python3 detector.py" \
        "width: 1920" \
        "height: 1088" \
        "zoom: [0.0, 0.0, 1.0, 1.0]" \
        "szarkii-apps/szarkii-detector" \
        "difference threshold: 80" \
        "continuous time interval: None" \
        "pause record time interval: None" \
        "record time interval: 120" \
        "max space (MB): 400" \
        "on movement strategy: record"

test    "Test custom values" \
        "python3 detector.py -w 800 -h 600 -z 0.5,0.7,0.3,0.3 -o /tmp/szarkii-detector-test -d 20 -c 10:02-11:48 -p 06:01-06:02 -i 60 -s 2000 -t" \
        "width: 800" \
        "height: 600" \
        "zoom: [0.5, 0.7, 0.3, 0.3]" \
        "/tmp/szarkii-detector-test" \
        "difference threshold: 20" \
        "continuous time interval: 10:02-11:48" \
        "pause record time interval: 06:01-06:02" \
        "record time interval: 60" \
        "max space (MB): 2000" \
        "on movement strategy: take photos"


minuteBefore=$(date -d "now -1 minute" +"%H:%M")
minuteAfter=$(date -d "now 1 minute" +"%H:%M")

test    "Test continuous record" \
        "python3 detector.py -c $minuteBefore-$minuteAfter" \
        "Continuous recording is in effect."