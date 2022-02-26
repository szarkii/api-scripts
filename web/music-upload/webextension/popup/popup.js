const StorageKey = {
    Host: "HOST",
    Token: "TOKEN",
    Artist: "ARTIST",
    Album: "ALBUM"
};

class StorageService {

    async set(key, value) {
        const storage = await this.getAll();
        storage[key] = value;
        browser.storage.local.set(storage)
    }

    async get(key) {
        return (await this.getAll())[key];
    }

    getAll() {
        return browser.storage.local.get();
    }
}

class PopupComponent {

    getHost() {
        return this.getHostHtmlElement().value;
    }

    setHost(host) {
        this.getHostHtmlElement().value = host;
    }

    getHostHtmlElement() {
        return document.querySelector("#host");
    }

    getToken() {
        return this.getTokenHtmlElement().value;
    }

    setToken(token) {
        this.getTokenHtmlElement().value = token;
    }

    getTokenHtmlElement() {
        return document.querySelector("#token");
    }

    getArtist() {
        return this.getArtistHtmlElement().value;
    }

    setArtist(artist) {
        this.getArtistHtmlElement().value = artist;
    }

    getArtistHtmlElement() {
        return document.querySelector("#artist");
    }

    getAlbum() {
        return this.getAlbumHtmlElement().value;
    }

    setAlbum(album) {
        this.getAlbumHtmlElement().value = album;
    }

    getAlbumHtmlElement() {
        return document.querySelector("#album");
    }

    getUploadButton() {
        return document.querySelector("#upload-button");
    }
}

class UrlService {
    async getCurrentTabUrl() {
        const tabs = await browser.tabs.query({ active: true, currentWindow: true });
        return tabs[0].url;
    }
}

class UploadService {
    upload(url, token, payload) {
        const httpRequest = new XMLHttpRequest();

        httpRequest.onreadystatechange = () => console.log("response: " + JSON.stringify(httpRequest));

        httpRequest.open("POST", url, false);
        httpRequest.setRequestHeader("Authorization", token);
        httpRequest.send(JSON.stringify(payload));
    }
}

const storageService = new StorageService();
const popup = new PopupComponent();
const urlService = new UrlService();
const uploadService = new UploadService();

document.addEventListener("DOMContentLoaded", async () => {
    popup.setHost(await storageService.get(StorageKey.Host) || "");
    popup.setToken(await storageService.get(StorageKey.Token) || "");
    popup.setArtist(await storageService.get(StorageKey.Artist) || "");
    popup.setAlbum(await storageService.get(StorageKey.Album) || "");

    popup.getUploadButton().addEventListener("click", async () => {
        const url = await urlService.getCurrentTabUrl();
        const host = popup.getHost();
        await storageService.set(StorageKey.Host, host);
        const token = popup.getToken();
        await storageService.set(StorageKey.Token, token);
        const artist = popup.getArtist();
        await storageService.set(StorageKey.Artist, artist);
        const album = popup.getAlbum();
        await storageService.set(StorageKey.Album, album);

        const payload = {
            url,
            artist,
            album
        };

        uploadService.upload(host, token, payload);
    });
});
