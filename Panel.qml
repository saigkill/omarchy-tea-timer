import QtQuick
import Quickshell
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Tea timer panel: pick 3-10 minutes, start / pause / stop. All state
// lives on the host bar widget; this panel reads and calls through it.
Panel {
  id: root
  moduleName: "saigkill.tea-timer"
  ipcTarget: "saigkill.tea-timer"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null

  readonly property bool running: hostWidget ? hostWidget.running : false
  readonly property bool paused: hostWidget ? hostWidget.paused : false
  readonly property bool finished: hostWidget ? hostWidget.finished : false
  readonly property bool active: running || paused
  readonly property int selected: hostWidget ? hostWidget.selectedMinutes : Model.DEFAULT_MINUTES

  readonly property color contentForeground: bar ? bar.barForeground : Color.foreground
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  function open() { root.controller.show() }
  function close() { root.controller.hide() }
  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(480))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(12)

        PanelSectionHeader {
          foreground: root.contentForeground
          fontFamily: root.contentFontFamily
          text: "TEA TIMER"
        }

        // ---- countdown display ------------------------------------------
        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: root.finished ? "Your tea is ready" : (root.hostWidget ? root.hostWidget.remainingText : "")
          color: root.finished ? Color.urgent : (root.active ? Color.accent : root.contentForeground)
          font.family: root.contentFontFamily
          font.pixelSize: root.finished ? Style.font.body : Style.font.body * 2.4
          font.bold: true
        }

        Rectangle {
          width: parent.width
          height: Style.space(4)
          radius: height / 2
          color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.15)

          Rectangle {
            width: parent.width * (root.hostWidget ? root.hostWidget.progress : 0)
            height: parent.height
            radius: parent.radius
            color: Color.accent
          }
        }

        // ---- minute selection -------------------------------------------
        Flow {
          width: parent.width
          spacing: Style.space(6)

          Repeater {
            model: Model.durations()

            delegate: Rectangle {
              required property int modelData
              readonly property bool chosen: modelData === root.selected
              width: (column.width - Style.space(6) * 3) / 4
              height: Style.space(36)
              radius: Style.cornerRadius
              opacity: root.active ? 0.4 : 1
              color: chosen
                ? Qt.rgba(Color.accent.r, Color.accent.g, Color.accent.b, 0.30)
                : Style.controlFill(false, mouse.containsMouse, root.contentForeground, Color.accent)

              Text {
                anchors.centerIn: parent
                text: modelData + " min"
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: parent.chosen
              }

              MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: !root.active
                onClicked: if (root.hostWidget) root.hostWidget.selectMinutes(modelData)
              }
            }
          }
        }

        // ---- controls -----------------------------------------------------
        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Style.space(8)

          PanelActionButton {
            visible: !root.active
            iconText: ""
            tooltipText: "Start"
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
            onClicked: if (root.hostWidget) root.hostWidget.start()
          }

          PanelActionButton {
            visible: root.running
            iconText: ""
            tooltipText: "Pause"
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
            onClicked: if (root.hostWidget) root.hostWidget.pause()
          }

          PanelActionButton {
            visible: root.paused
            iconText: ""
            tooltipText: "Resume"
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
            onClicked: if (root.hostWidget) root.hostWidget.resume()
          }

          PanelActionButton {
            visible: root.active
            iconText: ""
            tooltipText: "Stop"
            foreground: root.contentForeground
            fontFamily: root.contentFontFamily
            onClicked: if (root.hostWidget) root.hostWidget.stop()
          }
        }
      }
    }
  }
}
