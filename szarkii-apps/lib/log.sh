lib_getFormattedTime() {
    date '+%Y-%m-%d %H:%M:%S_%N' | cut -c 1-23
}

lib_logInfo() {
    echo "[INFO] $(lib_getFormattedTime) $1"
}

lib_logWarn() {
    echo "[WARN] $(lib_getFormattedTime) $1"
}

lib_logSuccess() {
    echo "[SUCC] $(lib_getFormattedTime) $1"
}

lib_logError() {
    echo "[ERRO] $(lib_getFormattedTime) $1"
}


lib_logSeparator() {
    echo
}