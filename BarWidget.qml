import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Tea timer bar widget: a cup icon with the remaining time, plus the host
// for the selection panel. The countdown is based on an absolute end time,
// so timer jitter or a suspended shell cannot make it drift.
BarWidget {
  id: root
  moduleName: "saigkill.tea-timer"

  property int selectedMinutes: Model.DEFAULT_MINUTES
  property bool running: false
  property bool paused: false
  property bool finished: false

  property double endMs: 0
  property double totalMs: 0
  property double pausedRemainingMs: 0
  property double nowMs: Date.now()

  readonly property double remaining: running
    ? Model.remainingMs(endMs, nowMs)
    : (paused ? pausedRemainingMs : selectedMinutes * 60000)
  readonly property string remainingText: Model.formatRemaining(remaining)
  readonly property double progress: (running || paused) ? Model.progress(totalMs, remaining) : 0
  readonly property bool active: running || paused

  readonly property color stateColor: finished
    ? Color.urgent
    : (active ? Color.accent : (bar ? bar.barForeground : Color.foreground))

  readonly property string tooltipText: finished
    ? "Your tea is ready"
    : (running ? "Tea: " + remainingText + " left"
      : (paused ? "Tea paused: " + remainingText + " left"
        : "Tea timer: " + selectedMinutes + " min"))

  function selectMinutes(minutes) {
    if (root.active) return
    root.finished = false
    root.selectedMinutes = Model.clampMinutes(minutes)
  }

  function start() {
    root.finished = false
    root.paused = false
    root.totalMs = root.selectedMinutes * 60000
    root.nowMs = Date.now()
    root.endMs = root.nowMs + root.totalMs
    root.running = true
  }

  function pause() {
    if (!root.running) return
    root.pausedRemainingMs = Model.remainingMs(root.endMs, Date.now())
    root.running = false
    root.paused = true
  }

  function resume() {
    if (!root.paused) return
    root.nowMs = Date.now()
    root.endMs = root.nowMs + root.pausedRemainingMs
    root.paused = false
    root.running = true
  }

  function stop() {
    root.running = false
    root.paused = false
    root.finished = false
  }

  function dismiss() {
    root.finished = false
  }

  function tick() {
    root.nowMs = Date.now()
    if (root.running && Model.remainingMs(root.endMs, root.nowMs) <= 0) complete()
  }

  function complete() {
    root.running = false
    root.paused = false
    root.finished = true
    var msg = Model.readyMessage(Math.round(root.totalMs / 60000))
    notifyProc.command = ["omarchy-notification-send", "-g", "", "-u", "critical",
      "-r", "4242", msg.title, msg.body]
    notifyProc.running = true
  }

  // ---- panel lifecycle (shape contract for shell summon/hide/toggle) ---
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  implicitWidth: row.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  Timer {
    interval: 250
    running: root.running
    repeat: true
    onTriggered: root.tick()
  }

  IpcHandler {
    target: "saigkill.tea-timer"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function start(): void { root.start() }
    function stop(): void { root.stop() }
    function setMinutes(minutes: int): void { root.selectMinutes(minutes) }
  }

  Row {
    id: row
    anchors.fill: parent
    spacing: Style.space(4)

    BarIconButton {
      id: button
      bar: root.bar
      text: ""
      slotSize: Style.bar.statusSlot
      fontSize: Style.font.caption
      active: root.finished
      enabled: true
      foreground: root.stateColor
      tooltipText: root.tooltipText

      onPressed: function(mouseButton) {
        if (mouseButton === Qt.LeftButton) {
          if (root.finished) root.dismiss()
          root.toggle()
        } else if (mouseButton === Qt.RightButton && root.active) {
          root.stop()
        }
      }
    }

    Text {
      visible: root.active || root.finished
      anchors.verticalCenter: parent.verticalCenter
      text: root.finished ? "Ready!" : root.remainingText
      color: root.stateColor
      font.family: bar ? bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.caption
      font.bold: true
    }
  }

  Process {
    id: notifyProc
    onExited: function(exitCode) {
      if (exitCode !== 0) console.warn("saigkill.tea-timer: notification not delivered (exit " + exitCode + ")")
    }
  }
}
