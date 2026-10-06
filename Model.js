// Pure tea timer logic. No Qt, no IO: runs under node as well as QML.

var MIN_MINUTES = 3
var MAX_MINUTES = 10
var DEFAULT_MINUTES = 4

function durations() {
  var list = []
  for (var m = MIN_MINUTES; m <= MAX_MINUTES; m++) list.push(m)
  return list
}

function clampMinutes(value) {
  var n = Math.round(Number(value))
  if (!isFinite(n)) return DEFAULT_MINUTES
  return Math.max(MIN_MINUTES, Math.min(MAX_MINUTES, n))
}

// Milliseconds left until endMs, never negative.
function remainingMs(endMs, nowMs) {
  return Math.max(0, Number(endMs) - Number(nowMs))
}

// "4:05". Rounds up, so the display reads 0:01 until the very end and
// never shows 0:00 while the tea is still brewing.
function formatRemaining(ms) {
  var total = Math.ceil(Math.max(0, Number(ms) || 0) / 1000)
  var minutes = Math.floor(total / 60)
  var seconds = total % 60
  return minutes + ":" + (seconds < 10 ? "0" : "") + seconds
}

// 0..1 share of the brew that has elapsed.
function progress(totalMs, remaining) {
  if (!(totalMs > 0)) return 0
  return Math.max(0, Math.min(1, 1 - remaining / totalMs))
}

function readyMessage(minutes) {
  return {
    title: "Your tea is ready",
    body: "Brewing time of " + minutes + " minute" + (minutes === 1 ? "" : "s")
      + " is over. Enjoy your tea!"
  }
}
