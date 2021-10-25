# JavaScript API

## Usage

### Import modules

```
(async function() {
    'use strict';

    async function loadScript(url, callback) {
        var head = document.head;
        var script = document.createElement('script');
        script.type = 'text/javascript';
        script.src = url;

        script.onreadystatechange = callback;
        script.onload = callback;

        head.appendChild(script);
    }

    const run = async () => {
        await Utils.sleep(100);
        console.debug("end");

    }

    let Utils;
    await loadScript("https://cdn.jsdelivr.net/gh/rkowalik/api-scripts/js/automated-tests/utils.js", run);
})();
```