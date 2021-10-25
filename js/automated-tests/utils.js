const Utils = {
        click: async function (selector) {
            await Function.waitUntilElementClickable(selector);
            document.querySelector(selector).click();
        },

        setInputValue: async function (selector, value) {
            const element = await Function.getElement(selector);
            Function.scrollTo(element);

            element.value = value;
            element.dispatchEvent(new Event('input'));
            element.dispatchEvent(new Event('blur'));
        },

        selectOption: async function (selector, optionName) {
            await Function.waitUntil(() => document.querySelectorAll(`${selector} option`).length > 1);
            const options = Array.from(document.querySelectorAll(`${selector} option`));
            const value = options.find((option) => option.innerText.trim() === optionName || option.label.trim() === optionName).value;
            const element = await Function.getElement(selector);
            Function.scrollTo(element);

            element.value = value;
            element.dispatchEvent(new Event('change'));
        },

        getElement: async function (selector) {
            if (await Function.waitUntil(() => document.querySelector(selector))) {
                return document.querySelector(selector);
            }

            throw new Error(`Element not found by '${selector}' selector.`);
        },

        getElements: async function (selector) {
            if (await Function.waitUntil(() => document.querySelectorAll(selector).length)) {
                return Array.from(document.querySelectorAll(selector));
            }

            throw new Error(`None element found by '${selector}' selector.`);
        },

        waitUntilElementClickable: async function (selector) {
            const clickable = await Function.waitUntil(() => {
                const element = document.querySelector(selector);
                if (element) {
                    Function.scrollTo(element);
                    return (element.getAttribute('disabled') && element.getAttribute('disabled') !== "true")
                        || !element.disabled;
                }
            });

            if (!clickable) {
                throw new Error(`Element found by '${selector}' selector is not clickable.`);
            }
        },

        waitUntilClassAdded: async function(selector, className) {
            const added = await Function.waitUntil(() => {
                const element = document.querySelector(selector);
                return element && element.className.includes(className);
            });
            if (!added) {
                throw new Error(`Element not found by '${selector}' or element has no '${className}' class name.`);
            }
        },

        waitUntilClassRemoved: async function(selector, className) {
            const removed = await Function.waitUntil(() => {
                const element = document.querySelector(selector);
                return element && !element.className.includes(className);
            });
            if (!removed) {
                throw new Error(`Element not found by '${selector}' or element still has '${className}' class name.`);
            }
        },

        waitUntil: async function (condition) {
            let timeoutMs = 30 * 1000;
            let msSpent = 0;

            while (msSpent < timeoutMs) {
                if (condition()) {
                    return new Promise(resolve => {
                        resolve(true);
                    });
                }
                await Function.sleep(500);
                msSpent += 500;
            }

            return new Promise(resolve => {
                resolve(false);
            });
        },

        sleep: function (ms) {
            return new Promise(resolve => setTimeout(resolve, ms));
        },

        scrollTo: function (element) {
            element.scrollIntoView();
        }
    };