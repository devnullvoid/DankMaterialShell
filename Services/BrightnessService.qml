pragma Singleton

pragma ComponentBehavior

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool brightnessAvailable: laptopBacklightAvailable || ddcAvailable
  property bool laptopBacklightAvailable: false
  property bool ddcAvailable: false
  property int brightnessLevel: 50
  property int maxBrightness: 100
  property int currentRawBrightness: 0
  property bool brightnessInitialized: false

  signal brightnessChanged

  function setBrightnessInternal(percentage) {
    brightnessLevel = Math.max(1, Math.min(100, percentage))

    if (laptopBacklightAvailable) {
      laptopBrightnessProcess.command = ["brightnessctl", "set", brightnessLevel + "%"]
      laptopBrightnessProcess.running = true
    } else if (ddcAvailable) {

      Quickshell.execDetached(
            ["ddcutil", "setvcp", "10", brightnessLevel.toString()])
    }
  }

  function setBrightness(percentage) {
    setBrightnessInternal(percentage)
    brightnessChanged()
  }

  Component.onCompleted: {
    ddcAvailabilityChecker.running = true
    laptopBacklightChecker.running = true
  }

  onLaptopBacklightAvailableChanged: {
    if (laptopBacklightAvailable && !brightnessInitialized) {
      laptopBrightnessInitProcess.running = true
    }
  }

  onDdcAvailableChanged: {
    if (ddcAvailable && !laptopBacklightAvailable && !brightnessInitialized) {
      ddcBrightnessInitProcess.running = true
    }
  }

  Process {
    id: ddcAvailabilityChecker
    command: ["which", "ddcutil"]
    onExited: function (exitCode) {
      ddcAvailable = (exitCode === 0)
    }
  }

  Process {
    id: laptopBacklightChecker
    command: ["brightnessctl", "--list"]
    onExited: function (exitCode) {
      laptopBacklightAvailable = (exitCode === 0)
    }
  }

  Process {
    id: laptopBrightnessProcess
    running: false

    onExited: function (exitCode) {
      if (exitCode !== 0) {

      }
    }
  }

  Process {
    id: laptopBrightnessInitProcess
    command: ["brightnessctl", "get"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        if (text.trim()) {
          currentRawBrightness = parseInt(text.trim())
          laptopMaxBrightnessProcess.running = true
        }
      }
    }

    onExited: function (exitCode) {
      if (exitCode !== 0) {
        console.warn("BrightnessService: Failed to read current brightness:",
                     exitCode)
      }
    }
  }

  Process {
    id: laptopMaxBrightnessProcess
    command: ["brightnessctl", "max"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        if (text.trim()) {
          maxBrightness = parseInt(text.trim())
          brightnessLevel = Math.round(
            (currentRawBrightness / maxBrightness) * 100)
          brightnessInitialized = true
          console.log("BrightnessService: Initialized with brightness level:",
                      brightnessLevel + "%")
        }
      }
    }

    onExited: function (exitCode) {
      if (exitCode !== 0) {
        console.warn("BrightnessService: Failed to read max brightness:",
                     exitCode)
      }
    }
  }

  Process {
    id: ddcBrightnessInitProcess
    command: ["ddcutil", "getvcp", "10", "--brief"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        if (text.trim()) {
          const parts = text.trim().split(" ")
          if (parts.length >= 5) {
            const current = parseInt(parts[3]) || 50
            const max = parseInt(parts[4]) || 100
            brightnessLevel = Math.round((current / max) * 100)
            brightnessInitialized = true
          }
        }
      }
    }

    onExited: function (exitCode) {
      if (exitCode !== 0) {
        if (!laptopBacklightAvailable) {
          console.warn("BrightnessService: DDC brightness read failed:",
                       exitCode)
        }
      }
    }
  }

  // IPC Handler for external control
  IpcHandler {
    target: "brightness"

    function set(percentage: string): string {
      if (!root.brightnessAvailable) {
        return "Brightness control not available"
      }

      const value = parseInt(percentage)
      const clampedValue = Math.max(1, Math.min(100, value))
      root.setBrightness(clampedValue)
      return "Brightness set to " + clampedValue + "%"
    }

    function increment(step: string): string {
      if (!root.brightnessAvailable) {
        return "Brightness control not available"
      }

      const currentLevel = root.brightnessLevel
      const newLevel = Math.max(1,
                                Math.min(100,
                                         currentLevel + parseInt(step || "10")))
      root.setBrightness(newLevel)
      return "Brightness increased to " + newLevel + "%"
    }

    function decrement(step: string): string {
      if (!root.brightnessAvailable) {
        return "Brightness control not available"
      }

      const currentLevel = root.brightnessLevel
      const newLevel = Math.max(1,
                                Math.min(100,
                                         currentLevel - parseInt(step || "10")))
      root.setBrightness(newLevel)
      return "Brightness decreased to " + newLevel + "%"
    }

    function status(): string {
      if (!root.brightnessAvailable) {
        return "Brightness control not available"
      }

      return "Brightness: " + root.brightnessLevel + "% ("
          + (root.laptopBacklightAvailable ? "laptop backlight" : "DDC") + ")"
    }
  }
}
