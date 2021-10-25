# JavaScript API

## Usage

### Import modules

```
(function() {
'use strict';

    function loadScript(url, callback) {
        var head = document.head;
        var script = document.createElement('script');
        script.type = 'text/javascript';
        script.src = url;

        script.onreadystatechange = callback;
        script.onload = callback;

        head.appendChild(script);
    }

    const run = () => {
        Utils.wait(100);
    }

    loadScript("https://cdn.jsdelivr.net/gh/rkowalik/api-scripts/js/automated-tests/<FILE>.js", run);
})();
```