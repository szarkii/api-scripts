const http = require("http");
const { exec } = require("child_process");
const Fs = require('fs');
const Path = require('path');

const configFilePath = Path.resolve(__dirname, "config.json");

if (!Fs.existsSync(configFilePath)) {
  const defaultConfiguration = {
    hostname: "0.0.0.0",
    port: 8000,
    authorizationToken: "",
    musicDirectory: "",
    debugMode: true
  };

  console.error(`Configuration file does not exist. Go to "${configFilePath}" and update the file.`);
  Fs.writeFileSync(configFilePath, JSON.stringify(defaultConfiguration, null, 2), 'utf8');
  return;
}

const Config = require(configFilePath);

const Logger = {
  debug: (message) => {
    if (Config.debugMode) {
      console.debug(`[${Logger.getTime()}] DEBUG ${message}`);
    }
  },

  error: (message) => {
      console.error(`[${Logger.getTime()}] ERROR ${message}`);
  },

  getTime: () => {
    const date = new Date();
    return `${date.toLocaleString("sv-SE")}:${date.getMilliseconds()}`;
  }
};

async function downloadFile(url, artist, album) {
  let artistArgument = "";
  if (artist) {
    artistArgument = `-a "${artist}"`;
  }

  let albumArgument = "";
  if (album) {
    albumArgument = `-l "${album}"`;
  }

  return new Promise((resolve) => {
    const command = `cd "${Config.musicDirectory}"; szarkii-music-metadata ${artistArgument} ${albumArgument} ${url}`;
    Logger.debug(`Executing command "${command}"`);

    exec(command, (error, stdout, stderr) => {
      if (error) {
        Logger.error(error);
        resolve(false);
      } else {
        Logger.debug("Command finished.");
        Logger.debug(stdout);
        Logger.debug(stderr);
        resolve(true);
      }
    });
  });
}

http.createServer(async function (request, response) {
  Logger.debug(request.url);

  if (request.headers.authorization !== Config.authorizationToken) {
    response.writeHead(401);
    response.end();
    return;
  }

  if (request.url === "/upload") {
    let body = "";

    request.on("data", chunk => {
      body += chunk.toString();
    });

    request.on('end', async () => {
      Logger.debug(body);
      body = JSON.parse(body);

      if (!body.url) {
        response.writeHead(422);
        response.write("URL is empty.");
        response.end();
        return;
      }

      if(await downloadFile(body.url, body.artist, body.album)) {
        response.writeHead(200);
        response.write("OK");
        response.end();
      } else {
        response.writeHead(500);
        response.write("Server error.");
        response.end();
      }   
    });

    return;
  }

  /** 404 */
  response.writeHead(404);
  response.end();

}).listen(Config.port, Config.hostname, () => {
  Logger.debug(`Server running at http://${Config.hostname}:${Config.port}/`)
});