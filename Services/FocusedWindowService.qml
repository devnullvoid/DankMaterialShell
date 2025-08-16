pragma Singleton

pragma ComponentBehavior

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool niriAvailable: false
  property string focusedAppId: ""
  property string focusedAppName: ""
  property string focusedWindowTitle: ""
  property int focusedWindowId: -1

  function updateFromNiriData() {
    if (!root.niriAvailable) {
      clearFocusedWindow()
      return
    }

    let focusedWindow = NiriService.windows.find(w => w.is_focused)

    if (focusedWindow) {
      root.focusedAppId = focusedWindow.app_id || ""
      root.focusedWindowTitle = focusedWindow.title || ""
      root.focusedAppName = getDisplayName(focusedWindow.app_id || "")
      root.focusedWindowId = parseInt(focusedWindow.id) || -1
    } else {
      setWorkspaceFallback()
    }
  }

  function clearFocusedWindow() {
    root.focusedAppId = ""
    root.focusedAppName = ""
    root.focusedWindowTitle = ""
    root.focusedWindowId = -1
  }
  
  function setWorkspaceFallback() {
    if (NiriService.focusedWorkspaceIndex >= 0 && NiriService.allWorkspaces.length > 0) {
      const workspace = NiriService.allWorkspaces[NiriService.focusedWorkspaceIndex]
      if (workspace) {
        root.focusedAppId = "niri"
        root.focusedAppName = "niri"
        if (workspace.name && workspace.name.length > 0) {
          root.focusedWindowTitle = workspace.name
        } else {
          root.focusedWindowTitle = "workspace " + workspace.idx
        }
        root.focusedWindowId = -1
      } else {
        clearFocusedWindow()
      }
    } else {
      clearFocusedWindow()
    }
  }

  function getDisplayName(appId) {
    if (!appId)
      return ""
    const desktopEntry = DesktopEntries.byId(appId)
    return desktopEntry && desktopEntry.name ? desktopEntry.name : ""
  }

  Component.onCompleted: {
    root.niriAvailable = NiriService.niriAvailable
    NiriService.onNiriAvailableChanged.connect(() => {
                                                 root.niriAvailable = NiriService.niriAvailable
                                                 if (root.niriAvailable)
                                                 updateFromNiriData()
                                               })
    if (root.niriAvailable)
    updateFromNiriData()
  }

  Connections {
    function onFocusedWindowIdChanged() {
      const focusedWindowId = NiriService.focusedWindowId
      if (!focusedWindowId) {
        setWorkspaceFallback()
        return
      }

      const focusedWindow = NiriService.windows.find(
                            w => w.id == focusedWindowId)
      if (focusedWindow) {
        root.focusedAppId = focusedWindow.app_id || ""
        root.focusedWindowTitle = focusedWindow.title || ""
        root.focusedAppName = getDisplayName(focusedWindow.app_id || "")
        root.focusedWindowId = parseInt(focusedWindow.id) || -1
      } else {
        setWorkspaceFallback()
      }
    }

    function onWindowsChanged() {
      updateFromNiriData()
    }

    function onWindowOpenedOrChanged(windowData) {
      if (windowData.is_focused) {
        root.focusedAppId = windowData.app_id || ""
        root.focusedWindowTitle = windowData.title || ""
        root.focusedAppName = getDisplayName(windowData.app_id || "")
        root.focusedWindowId = parseInt(windowData.id) || -1
      }
    }

    target: NiriService
  }
}
