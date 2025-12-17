pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import qs.Common

Scope {
    id: root

    property bool lockSecured: false
    property bool unlockInProgress: false

    readonly property alias passwd: passwd
    readonly property alias fprint: fprint
    property string lockMessage
    property string state
    property string fprintState
    property string buffer

    signal flashMsg
    signal unlockRequested

    FileView {
        id: dankshellConfigWatcher

        path: "/etc/pam.d/dankshell"
        printErrors: false
    }

    FileView {
        id: loginConfigWatcher

        path: "/etc/pam.d/login"
        printErrors: false
    }

    PamContext {
        id: passwd

        config: dankshellConfigWatcher.loaded ? "dankshell" : "login"
        configDirectory: dankshellConfigWatcher.loaded || loginConfigWatcher.loaded ? "/etc/pam.d" : Quickshell.shellDir + "/assets/pam"

        onMessageChanged: {
            if (message.startsWith("The account is locked"))
                root.lockMessage = message;
            else if (root.lockMessage && message.endsWith(" left to unlock)"))
                root.lockMessage += "\n" + message;
        }

        onResponseRequiredChanged: {
            if (!responseRequired)
                return;

            respond(root.buffer);
        }

        onCompleted: res => {
            if (res === PamResult.Success) {
                if (!root.unlockInProgress) {
                    root.unlockInProgress = true;
                    fprint.abort();
                    root.unlockRequested();
                }
                return;
            }

            if (res === PamResult.Error)
                root.state = "error";
            else if (res === PamResult.MaxTries)
                root.state = "max";
            else if (res === PamResult.Failed)
                root.state = "fail";

            root.flashMsg();
            stateReset.restart();
        }
    }

    PamContext {
        id: fprint

        property bool available
        property int tries
        property int errorTries

        function checkAvail(): void {
            if (!available || !SettingsData.enableFprint || !root.lockSecured) {
                abort();
                return;
            }

            tries = 0;
            errorTries = 0;
            start();
        }

        config: "fprint"
        configDirectory: Quickshell.shellDir + "/assets/pam"

        onCompleted: res => {
            if (!available)
                return;

            if (res === PamResult.Success) {
                if (!root.unlockInProgress) {
                    root.unlockInProgress = true;
                    passwd.abort();
                    root.unlockRequested();
                }
                return;
            }

            if (res === PamResult.Error) {
                root.fprintState = "error";
                errorTries++;
                if (errorTries < 5) {
                    abort();
                    errorRetry.restart();
                }
            } else if (res === PamResult.MaxTries) {
                tries++;
                if (tries < SettingsData.maxFprintTries) {
                    root.fprintState = "fail";
                    start();
                } else {
                    root.fprintState = "max";
                    abort();
                }
            }

            root.flashMsg();
            fprintStateReset.start();
        }
    }

    Process {
        id: availProc

        command: ["sh", "-c", "fprintd-list $USER"]
        onExited: code => {
            fprint.available = code === 0;
            fprint.checkAvail();
        }
    }

    Timer {
        id: errorRetry

        interval: 800
        onTriggered: fprint.start()
    }

    Timer {
        id: stateReset

        interval: 4000
        onTriggered: {
            if (root.state !== "max")
                root.state = "";
        }
    }

    Timer {
        id: fprintStateReset

        interval: 4000
        onTriggered: {
            root.fprintState = "";
            fprint.errorTries = 0;
        }
    }

    onLockSecuredChanged: {
        if (lockSecured) {
            availProc.running = true;
            root.state = "";
            root.fprintState = "";
            root.lockMessage = "";
            root.unlockInProgress = false;
        } else {
            fprint.abort();
            passwd.abort();
            root.unlockInProgress = false;
        }
    }

    Connections {
        target: SettingsData

        function onEnableFprintChanged(): void {
            fprint.checkAvail();
        }
    }
}
