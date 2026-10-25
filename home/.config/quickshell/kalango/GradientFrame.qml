// Rounded translucent panel with the kalango blue -> green gradient border.
import QtQuick

Item {
    id: frame

    property color fill: Theme.glass
    property int radius: Theme.radius
    property int borderWidth: Theme.border

    Rectangle {
        anchors.fill: parent
        radius: frame.radius
        color: frame.fill
    }

    Canvas {
        id: stroke
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const g = ctx.createLinearGradient(0, 0, width, 0);
            g.addColorStop(0, Theme.blue);
            g.addColorStop(1, Theme.neon);
            ctx.strokeStyle = g;
            ctx.lineWidth = frame.borderWidth;
            const h = frame.borderWidth / 2;
            ctx.beginPath();
            ctx.roundedRect(h, h, width - frame.borderWidth, height - frame.borderWidth,
                            frame.radius - h, frame.radius - h);
            ctx.stroke();
        }
    }
}
