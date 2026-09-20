pragma ComponentBehavior: Bound
import QtQuick

Text {
    color: Tokens.text
    font.family: Tokens.fontFamily
    font.pixelSize: Tokens.body
    font.weight: Tokens.medium
    textFormat: Text.PlainText
    elide: Text.ElideRight
}
