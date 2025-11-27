import QtQuick
import Quickshell
import qs.Common
import qs.Modals

AppPickerModal {
    id: root

    property string url: ""

    title: I18n.tr("Open with...")
    targetData: url
    targetDataLabel: ""
    categoryFilter: ["WebBrowser", "X-WebBrowser"]
    viewMode: SettingsData.browserPickerViewMode || "grid"
    usageHistoryKey: "browserUsageHistory"
    showTargetData: true

    onApplicationSelected: (app, url) => {
        if (!app) return

        let cmd = app.exec || ""

        let hasField = false
        if (cmd.includes("%u")) { cmd = cmd.replace("%u", url); hasField = true }
        else if (cmd.includes("%U")) { cmd = cmd.replace("%U", url); hasField = true }
        else if (cmd.includes("%f")) { cmd = cmd.replace("%f", url); hasField = true }
        else if (cmd.includes("%F")) { cmd = cmd.replace("%F", url); hasField = true }

        cmd = cmd.replace(/%[ikc]/g, "")

        if (!hasField) {
            cmd += " " + url
        }

        console.log("BrowserPicker: Launching", cmd)

        Quickshell.execDetached({
            command: ["sh", "-c", cmd]
        })
    }

    onViewModeChanged: {
        SettingsData.set("browserPickerViewMode", viewMode)
    }
}
