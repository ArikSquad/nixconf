pragma ComponentBehavior: Bound

import QtQuick

Canvas {
    id: root

    property var values: []
    property color lineColor: Tokens.accent
    property color fillColor: Qt.alpha(lineColor, 0.12)

    implicitHeight: 34

    onValuesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        if (!values || values.length < 2)
            return;
        const max = Math.max(1, ...values);
        const step = width / Math.max(1, values.length - 1);
        ctx.beginPath();
        values.forEach((value, index) => {
            const x = index * step;
            const y = height - 2 - Math.max(0, value) / max * (height - 5);
            if (index === 0)
                ctx.moveTo(x, y);
            else
                ctx.lineTo(x, y);
        });
        ctx.lineTo(width, height);
        ctx.lineTo(0, height);
        ctx.closePath();
        ctx.fillStyle = fillColor;
        ctx.fill();
        ctx.beginPath();
        values.forEach((value, index) => {
            const x = index * step;
            const y = height - 2 - Math.max(0, value) / max * (height - 5);
            if (index === 0)
                ctx.moveTo(x, y);
            else
                ctx.lineTo(x, y);
        });
        ctx.strokeStyle = lineColor;
        ctx.lineWidth = 1.5;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.stroke();
    }
}
