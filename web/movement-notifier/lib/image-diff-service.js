const { exec } = require("child_process");

class ImageDiffService {
    async getImagesSimilarityIndex(firstImagePath, secondImagePath) {
        return new Promise((resolve) => {
            exec(`szarkii-img-diff "${firstImagePath}" "${secondImagePath}"`, (error, stdout, stderr) => {
                if (error) {
                    console.error(error)
                } else {
                    resolve(stdout);
                }
            });
        });
    }
}

module.exports = ImageDiffService;