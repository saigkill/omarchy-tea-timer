# Tea timer (saigkill.tea-timer)

Brewing countdown for the Omarchy shell bar.

![picture](https://github.com/saigkill/omarchy-tea-timer/blob/master/preview.png?raw=true)

- Cup icon in the bar; while a brew runs it shows the remaining time (`3:42`).
- Click the icon to open the panel: pick **3–10 minutes**, then start, pause/resume or stop.
- At 0 a critical notification "Your tea is ready" is sent and the bar shows "Ready!" until clicked.
- Right-click the icon to cancel a running timer.

IPC target `saigkill.tea-timer`: `open`, `close`, `toggle`, `start`, `stop`, `setMinutes <3-10>`.

## Install

    ln -s "$PWD" ~/.config/omarchy/plugins/saigkill.tea-timer

then add the widget to the bar in the shell settings.

The countdown uses an absolute end time, so it does not drift. State is not persisted: restarting the shell cancels a running brew.
