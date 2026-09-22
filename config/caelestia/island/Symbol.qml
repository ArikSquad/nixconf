pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    property string name: "today"
    property color color: Tokens.text
    property real size: 20
    readonly property var paths: ({
            today: "M6 3 L6 7 M18 3 L18 7 M4 10 L20 10 M5 5 L19 5 Q21 5 21 7 L21 20 Q21 22 19 22 L5 22 Q3 22 3 20 L3 7 Q3 5 5 5 M7 14 L10 14 M14 14 L17 14 M7 18 L10 18",
            controls: "M3 6 L8 6 M14 6 L21 6 M3 18 L10 18 M16 18 L21 18 M11 3 A3 3 0 1 0 11 9 A3 3 0 1 0 11 3 M13 15 A3 3 0 1 0 13 21 A3 3 0 1 0 13 15",
            media: "M9 17 L9 5 L20 3 L20 15 M9 8 L20 6 M6 16 A3 2.5 0 1 0 6 21 A3 2.5 0 1 0 6 16 M17 14 A3 2.5 0 1 0 17 19 A3 2.5 0 1 0 17 14",
            notifications: "M9 20 Q12 23 15 20 M5 17 L19 17 L17 14 L17 9 Q17 4 12 4 Q7 4 7 9 L7 14 Z M12 2 L12 4",
            more: "M5 11 A1 1 0 1 0 5 13 A1 1 0 1 0 5 11 M12 11 A1 1 0 1 0 12 13 A1 1 0 1 0 12 11 M19 11 A1 1 0 1 0 19 13 A1 1 0 1 0 19 11",
            close: "M7 7 L17 17 M17 7 L7 17",
            search: "M10.5 4 A6.5 6.5 0 1 0 10.5 17 A6.5 6.5 0 1 0 10.5 4 M15.5 15.5 L21 21",
            terminal: "M5 7 L10 12 L5 17 M12 17 L19 17",
            return: "M19 6 L19 12 Q19 16 15 16 L6 16 M9 12 L5 16 L9 20",
            "arrow.right": "M5 12 L19 12 M14 7 L19 12 L14 17",
            ellipsis: "M5 11 A1 1 0 1 0 5 13 A1 1 0 1 0 5 11 M12 11 A1 1 0 1 0 12 13 A1 1 0 1 0 12 11 M19 11 A1 1 0 1 0 19 13 A1 1 0 1 0 19 11",
            previous: "M6 5 L6 19 M19 5 L9 12 L19 19 Z",
            next: "M18 5 L18 19 M5 5 L15 12 L5 19 Z",
            play: "M8 5 L19 12 L8 19 Z",
            pause: "M8 5 L11 5 L11 19 L8 19 Z M14 5 L17 5 L17 19 L14 19 Z"
        })
    implicitWidth: size
    implicitHeight: size
    Shape {
        width: 24
        height: 24
        scale: root.width / 24
        transformOrigin: Item.TopLeft
        ShapePath {
            strokeColor: root.color
            strokeWidth: ["previous", "next", "play", "pause"].includes(root.name) ? 1.9 : 1.5
            fillColor: ["previous", "next", "play", "pause"].includes(root.name) ? root.color : "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg {
                path: root.paths[root.name] ?? root.paths.more
            }
        }
    }
}
