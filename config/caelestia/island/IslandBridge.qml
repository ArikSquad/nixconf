pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property var controller: null

    function open(page) {
        controller?.open(page);
    }

    function close() {
        controller?.dismiss();
    }
}
