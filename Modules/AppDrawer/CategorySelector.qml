import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets

Item {
  id: root

  property var categories: []
  property string selectedCategory: "All"
  property bool compact: false // For different layout styles

  signal categorySelected(string category)

  height: compact ? 36 : (72 + Theme.spacingS) // Single row vs two rows

  Row {
    visible: compact
    width: parent.width
    spacing: Theme.spacingS

    Repeater {
      model: categories.slice(0, Math.min(categories.length,
                                          8)) // Limit for space

      Rectangle {
        height: 36
        width: (parent.width - (Math.min(categories.length,
                                         8) - 1) * Theme.spacingS) / Math.min(
                 categories.length, 8)
        radius: Theme.cornerRadius
        color: selectedCategory === modelData ? Theme.primary : "transparent"
        border.color: selectedCategory === modelData ? "transparent" : Qt.rgba(
                                                         Theme.outline.r,
                                                         Theme.outline.g,
                                                         Theme.outline.b, 0.3)

        StyledText {
          anchors.centerIn: parent
          text: modelData
          color: selectedCategory === modelData ? Theme.surface : Theme.surfaceText
          font.pixelSize: Theme.fontSizeMedium
          font.weight: selectedCategory === modelData ? Font.Medium : Font.Normal
          elide: Text.ElideRight
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            selectedCategory = modelData
            categorySelected(modelData)
          }
        }
      }
    }
  }

  Column {
    visible: !compact
    width: parent.width
    spacing: Theme.spacingS

    Row {
      property var topRowCategories: ["All", "Development", "Graphics", "Games"]

      width: parent.width
      spacing: Theme.spacingS

      Repeater {
        model: parent.topRowCategories.filter(cat => {
                                                return categories.includes(cat)
                                              })

        Rectangle {
          height: 36
          width: (parent.width - (parent.topRowCategories.length - 1)
                  * Theme.spacingS) / parent.topRowCategories.length
          radius: Theme.cornerRadius
          color: selectedCategory === modelData ? Theme.primary : "transparent"
          border.color: selectedCategory === modelData ? "transparent" : Qt.rgba(
                                                           Theme.outline.r,
                                                           Theme.outline.g,
                                                           Theme.outline.b, 0.3)

          StyledText {
            anchors.centerIn: parent
            text: modelData
            color: selectedCategory === modelData ? Theme.surface : Theme.surfaceText
            font.pixelSize: Theme.fontSizeMedium
            font.weight: selectedCategory === modelData ? Font.Medium : Font.Normal
            elide: Text.ElideRight
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              selectedCategory = modelData
              categorySelected(modelData)
            }
          }
        }
      }
    }

    Row {
      property var bottomRowCategories: ["Internet", "Media", "Office", "Settings", "System"]

      width: parent.width
      spacing: Theme.spacingS

      Repeater {
        model: parent.bottomRowCategories.filter(cat => {
                                                   return categories.includes(
                                                     cat)
                                                 })

        Rectangle {
          height: 36
          width: (parent.width - (parent.bottomRowCategories.length - 1)
                  * Theme.spacingS) / parent.bottomRowCategories.length
          radius: Theme.cornerRadius
          color: selectedCategory === modelData ? Theme.primary : "transparent"
          border.color: selectedCategory === modelData ? "transparent" : Qt.rgba(
                                                           Theme.outline.r,
                                                           Theme.outline.g,
                                                           Theme.outline.b, 0.3)

          StyledText {
            anchors.centerIn: parent
            text: modelData
            color: selectedCategory === modelData ? Theme.surface : Theme.surfaceText
            font.pixelSize: Theme.fontSizeMedium
            font.weight: selectedCategory === modelData ? Font.Medium : Font.Normal
            elide: Text.ElideRight
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              selectedCategory = modelData
              categorySelected(modelData)
            }
          }
        }
      }
    }
  }
}
