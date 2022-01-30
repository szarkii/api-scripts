const moment = require("moment");
const fs = require("fs");
const Path = require('path');
const { exec } = require("child_process");

class SnapshotService {
    snapshotsDir = "snapshots";
    imageExtension = "jpg";
    width = 600;
    height = 480;
    projectAbsolutePath = Path.dirname(require.main.filename);

    constructor() {
    }

    async takeSnapshot() {
        const newSnapshotPath = this.getNewSnapshotPath();

        return new Promise((resolve) => {
            exec(`raspistill -w "${this.width}" -h "${this.height}" -o "${newSnapshotPath}"`, (error, stdout, stderr) => {
                if (error) {
                    console.error(error)
                } else {
                    resolve(newSnapshotPath);
                }
            });
        });
    }

    getNewSnapshotPath() {
        const dayDir = moment().format("YYYY-MM-DD");
        const time = moment().format("YYYY-MM-DD_HH-mm-ss");
        const dirPath = Path.join(this.projectAbsolutePath, this.snapshotsDir, dayDir);

        this.createDirIfNotExist(dirPath);

        return Path.join(dirPath, `${time}.${this.imageExtension}`);
    }

    createDirIfNotExist(path) {
        if (!fs.existsSync(path)) {
            fs.mkdirSync(path);
        }
    }

    getSnapshotNameFromPath(path) {
        return Path.basename(path);
    }

    getSnapshotPathFromName(name) {
        const dayDir = name.replace(/_.*$/, "");
        return Path.join(this.projectAbsolutePath, this.snapshotsDir, dayDir, name);
    }
}

module.exports = SnapshotService;