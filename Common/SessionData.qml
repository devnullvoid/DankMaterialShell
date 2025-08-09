pragma Singleton

pragma ComponentBehavior

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {

  id: root

  property bool isLightMode: false
  property string wallpaperPath: ""
  property string wallpaperLastPath: ""
  property string profileLastPath: ""
  property bool doNotDisturb: false
  property var pinnedApps: []
  property int selectedGpuIndex: 0

  Component.onCompleted: {
    loadSettings()
  }

  function loadSettings() {
    parseSettings(settingsFile.text())
  }

  function parseSettings(content) {
    try {
      if (content && content.trim()) {
        var settings = JSON.parse(content)
        isLightMode = settings.isLightMode !== undefined ? settings.isLightMode : false
        wallpaperPath = settings.wallpaperPath !== undefined ? settings.wallpaperPath : ""
        wallpaperLastPath = settings.wallpaperLastPath
            !== undefined ? settings.wallpaperLastPath : ""
        profileLastPath = settings.profileLastPath !== undefined ? settings.profileLastPath : ""
        doNotDisturb = settings.doNotDisturb !== undefined ? settings.doNotDisturb : false
        pinnedApps = settings.pinnedApps !== undefined ? settings.pinnedApps : []
        selectedGpuIndex = settings.selectedGpuIndex !== undefined ? settings.selectedGpuIndex : 0
      }
    } catch (e) {

    }
  }

  function saveSettings() {
    settingsFile.setText(JSON.stringify({
                                          "isLightMode": isLightMode,
                                          "wallpaperPath": wallpaperPath,
                                          "wallpaperLastPath": wallpaperLastPath,
                                          "profileLastPath": profileLastPath,
                                          "doNotDisturb": doNotDisturb,
                                          "pinnedApps": pinnedApps,
                                          "selectedGpuIndex": selectedGpuIndex
                                        }, null, 2))
  }

  function setLightMode(lightMode) {
    isLightMode = lightMode
    saveSettings()
  }

  function setDoNotDisturb(enabled) {
    doNotDisturb = enabled
    saveSettings()
  }

  function setWallpaperPath(path) {
    wallpaperPath = path
    saveSettings()
  }

  function setWallpaper(imagePath) {
    wallpaperPath = imagePath
    saveSettings()

    if (typeof Colors !== "undefined" && typeof SettingsData !== "undefined"
        && SettingsData.wallpaperDynamicTheming) {
      Colors.extractColors()
    }
  }

  function setWallpaperLastPath(path) {
    wallpaperLastPath = path
    saveSettings()
  }

  function setProfileLastPath(path) {
    profileLastPath = path
    saveSettings()
  }

  function setPinnedApps(apps) {
    pinnedApps = apps
    saveSettings()
  }

  function addPinnedApp(appId) {
    if (!appId)
      return
    var currentPinned = [...pinnedApps]
    if (currentPinned.indexOf(appId) === -1) {
      currentPinned.push(appId)
      setPinnedApps(currentPinned)
    }
  }

  function removePinnedApp(appId) {
    if (!appId)
      return
    var currentPinned = pinnedApps.filter(id => id !== appId)
    setPinnedApps(currentPinned)
  }

  function isPinnedApp(appId) {
    return appId && pinnedApps.indexOf(appId) !== -1
  }

  function setSelectedGpuIndex(index) {
    selectedGpuIndex = index
    saveSettings()
  }

  FileView {
    id: settingsFile

    path: StandardPaths.writableLocation(
            StandardPaths.GenericStateLocation) + "/DankMaterialShell/session.json"
    blockLoading: true
    blockWrites: true
    watchChanges: true
    onLoaded: {
      parseSettings(settingsFile.text())
    }
    onLoadFailed: error => {}
  }

  IpcHandler {
    target: "wallpaper"

    function get(): string {
      return root.wallpaperPath || ""
    }

    function set(path: string): string {
      if (!path) {
        return "ERROR: No path provided"
      }

      var absolutePath = path.startsWith(
            "/") ? path : StandardPaths.writableLocation(
                     StandardPaths.HomeLocation) + "/" + path

      try {
        root.setWallpaper(absolutePath)
        return "SUCCESS: Wallpaper set to " + absolutePath
      } catch (e) {
        return "ERROR: Failed to set wallpaper: " + e.toString()
      }
    }

    function clear(): string {
      root.setWallpaper("")
      return "SUCCESS: Wallpaper cleared"
    }
  }

  IpcHandler {
    target: "theme"

    function toggle(): string {
      root.setLightMode(!root.isLightMode)
      return root.isLightMode ? "light" : "dark"
    }

    function light(): string {
      root.setLightMode(true)
      return "light"
    }

    function dark(): string {
      root.setLightMode(false)
      return "dark"
    }

    function getMode(): string {
      return root.isLightMode ? "light" : "dark"
    }
  }
}
