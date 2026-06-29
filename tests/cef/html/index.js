const colorBlue = "#0088FF";
const colorRed = "#FF383C";

const theRectangle = document.getElementById("the-rectangle");
const theRectangleComputedStyle = window.getComputedStyle(theRectangle);

const spanCppAnswer = document.getElementById("cpp-answer");

function rgba2hex(rgba, withAlpha = false)
{
    hexValue = rgba.match(
        /^rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*(\d+\.{0,1}\d*))?\)$/
    )
        .slice(1).map(
            (n, i) =>
            (
                i === 3 ? Math.round(parseFloat(n) * 255) : parseFloat(n)
            )
            .toString(16)
            .padStart(2, "0")
            .replace("NaN", "")
        ).join("");

    return `#${hexValue}`;
}

window.onload = () =>
{
    document.getElementById("btn-color-red").addEventListener(
        "click",
        function()
        {
            theRectangle.style.backgroundColor = colorRed;
            theRectangle.style.setProperty("--rectangle-color", colorRed);
        }
    );

    document.getElementById("btn-color-blue").addEventListener(
        "click",
        function()
        {
            theRectangle.style.backgroundColor = colorBlue;
            theRectangle.style.setProperty("--rectangle-color", colorBlue);
        }
    );

    document.getElementById("btn-print-stdout").addEventListener(
        "click",
        function()
        {
            this.style.display = "none";

            let hexColor = rgba2hex(theRectangleComputedStyle.backgroundColor);
            console.debug(`[JS] Rectangle background color: ${hexColor}`);

            const cppAnswer = PrintColorToStdout(hexColor);
            const msg = `C++ answer: ${cppAnswer}`
            console.debug(`[JS] ${msg}`);
            spanCppAnswer.textContent = msg;
            spanCppAnswer.style.display = "inline";

            setTimeout(
                () =>
                {
                    spanCppAnswer.style.display = "none";
                    this.style.display = "inline-block";
                },
                5000
            );

        }
    );
}
