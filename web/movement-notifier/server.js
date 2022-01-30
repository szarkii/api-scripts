const http = require("http");
const fs = require("fs");
const SnapshotService = require("./lib/snapshot-service");
const ImageDiffService = require("./lib/image-diff-service");

const HOSTNAME = '0.0.0.0';
const PORT = 8000;
const SIMILARITY_THRESHOLD = 39;

const snapshotService = new SnapshotService();
const imageDiffService = new ImageDiffService();
const clients = [];

function sendAlert(response, id, message) {
  response.write("id: " + id + "\n");
  response.write("data: " + message + "\n\n");
}

http.createServer(async function (request, response) {
  console.log(request.url);

  /** Index.html */
  if (request.url === "/") {
    response.writeHead(200, { "Content-Type": "text/html" });
    response.write(fs.readFileSync(__dirname + "/index.html"));
    response.end();
    return;
  }

  /** Server-sent events */
  if (request.headers.accept && request.headers.accept == "text/event-stream") {
    if (request.url == "/events") {
      response.writeHead(200, {
        "Content-Type": "text/event-stream",
        "Cache-Control": "no-cache",
        "Connection": "keep-alive"
      });

      let clientAvailable = true;
      request.on('close', () => {
        clientAvailable = false;
      });

      const clientId = (new Date()).toLocaleTimeString();

      let previousSnapshotPath = await snapshotService.takeSnapshot();

      while (clientAvailable) {
        const snapshotToComparePath = await snapshotService.takeSnapshot();
        const similarityIndex = await imageDiffService.getImagesSimilarityIndex(previousSnapshotPath, snapshotToComparePath);
        
        if (similarityIndex < SIMILARITY_THRESHOLD) {
          sendAlert(response, clientId, "snapshots/" + snapshotService.getSnapshotNameFromPath(snapshotToComparePath));
        } else {
          fs.unlinkSync(previousSnapshotPath);
        }

        previousSnapshotPath = snapshotToComparePath;
      };
    }
    
    return;
  }
  
  /** Snapshots */
  if (request.url.startsWith("/snapshots")) {
    const snapshotName = request.url.replace("/snapshots/", "");
    const snapshotPath = snapshotService.getSnapshotPathFromName(snapshotName);

    response.writeHead(200, { "content-type": "image/jpg" });
    response.write(fs.readFileSync(snapshotPath));
    response.end();

    return;
  }

  /** 404 */
  response.writeHead(404);
  response.end();

}).listen(PORT, HOSTNAME, () => {
  console.log(`Server running at http://${HOSTNAME}:${PORT}/`)
});