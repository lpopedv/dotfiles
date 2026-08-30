import QtQuick
import ".."

Text {
    // NativeRendering, not Qt's default: QtRendering puts colour fringes on
    // thin glyphs here (37% of text pixels vs 0% for the GTK bar it replaced).
    renderType: Text.NativeRendering
    color: Theme.fg
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
}
