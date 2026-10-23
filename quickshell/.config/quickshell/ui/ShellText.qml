import QtQuick
import qs

Text {
    // NativeRendering, not Qt's default: QtRendering puts colour fringes on
    // thin glyphs here (37% of text pixels vs 0% for the GTK bar it replaced).
    renderType: Text.NativeRendering
    // Plain, not Qt's AutoText: most of what the shell prints comes from other programs
    // (track and window titles, tray menus, notifications), and AutoText renders anything
    // that looks like markup - an <img> in a web page's title would make the shell fetch it.
    // A sender's markup is opted into explicitly, after NotificationsService.sanitize().
    textFormat: Text.PlainText
    color: Theme.fg
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
}
