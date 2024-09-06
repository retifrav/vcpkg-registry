const canvas = document.getElementById("canvas");
const gameUI = document.getElementById("game-ui");
const placeholder = document.getElementById("placeholder");
const statusBar = document.getElementById("statusbar");

const gameContainer = document.getElementById("game-container");
const manualContainer = document.getElementById("manual-container");
const manualHeaderContainer = document.getElementById("manual-header-container");
const manualHeader = document.getElementById("manual-header");
const hideManualButton = document.getElementById("hide-manual-button");
const showManualButton = document.getElementById("show-manual-button");

const manualEnabledKey = "manual-enabled";
let manualEnabled = localStorage.getItem(manualEnabledKey);

function enableManual()
{
    manualContainer.style.display = "block";
    gameContainer.style.marginTop = "20px";

    hideManualButton.style.display = "block";
    showManualButton.style.display = "none";

    manualEnabled = "1";
    localStorage.setItem(manualEnabledKey, manualEnabled);
}

function disableManual()
{
    manualContainer.style.display = "none";
    gameContainer.style.marginTop = "0";

    hideManualButton.style.display = "none";
    showManualButton.style.display = "block";

    manualEnabled = "0";
    localStorage.setItem(manualEnabledKey, manualEnabled);
}

function enterFullScreenMode()
{
    var downEvent = new Event("keydown", { "bubbles": true });
    downEvent.key = "F5";
    downEvent.code = "F5";
    downEvent.which = 116;
    downEvent.keyCode = 116;
    canvas.dispatchEvent(downEvent);

    var upEvent = new Event("keyup", { "bubbles": true });
    upEvent.key = "F5";
    upEvent.code = "F5";
    upEvent.which = 116;
    upEvent.keyCode = 116;
    canvas.dispatchEvent(upEvent);
}

async function runGame()
{
    var m = await Module(); // reSL()

    m.canvas = (() => {
        var e = canvas;
        return e.addEventListener("webglcontextlost",
            (e => {
                alert("WebGL context lost. You will need to reload the page."),
                    e.preventDefault()
            }), !1
        ), e
    })();

    m.addOnExit(
        () => {
            gameUI.style.display = "none";
            placeholder.style.display = "block";
        }
    );

    gameUI.style.display = "block";
    placeholder.style.display = "none";
    m.callMain(["--windowed"])

    // if it wasn't for `aspect-ratio` CSS rule, preserving aspect ration would have been happening here
    // const observer = new ResizeObserver(
    //     (entries) =>
    //     {
    //         console.debug(`Canvas has been resized: ${entries[0].target.offsetWidth}x${entries[0].target.offsetHeight}`);
    //     }
    // );
    // observer.observe(canvas);
}

window.onload = () =>
{
    if (manualEnabled === null || manualEnabled !== "0") { enableManual(); }
    else { disableManual(); }

    placeholder.addEventListener(
        "click",
        () =>
        {
            runGame();
        }
    );

    canvas.addEventListener(
        "contextmenu",
        (event) =>
        {
            event.preventDefault();
        }
    );

    hideManualButton.addEventListener(
        "click",
        (event) =>
        {
            if (manualEnabled === "0")
            {
                console.warn("Got a request to show the manual, but `manualEnabled` is already `0`");
            }
            disableManual();
        }
    );

    showManualButton.addEventListener(
        "click",
        (event) =>
        {
            if (manualEnabled === "1")
            {
                console.warn("Got a request to show the manual, but `manualEnabled` is already `1`");
            }
            enableManual();
        }
    );
}
