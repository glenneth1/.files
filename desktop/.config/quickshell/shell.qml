import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property color bg: "#0c0b0c"
    property color fg: "#fafcfb"
    property color accent: "#b59790"
    property color muted: "#6f6664"
    property color danger: "#a55555"

    property string fontName: "JetBrainsMono Nerd Font"

    property int activeWorkspace: 1

    property string wifiText: "wifi"
    property string btText: "bt"
    property string volText: "vol"
    property string cpuText: "cpu"
    property string ncText: "nc:?"
    property string varText: "var"

    function run(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd])
    }

    component LispButton: Text {
        property string command: ""
        property string rightCommand: ""

        color: root.fg
        font.family: root.fontName
        font.pixelSize: 13
        verticalAlignment: Text.AlignVCenter

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton && parent.rightCommand !== "") {
                    root.run(parent.rightCommand)
                } else if (parent.command !== "") {
                    root.run(parent.command)
                }
            }
        }
    }

    PanelWindow {
        id: bar

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: 38
        color: "transparent"

        Rectangle {
            anchors {
                fill: parent
                leftMargin: 6
                rightMargin: 6
                topMargin: 4
                bottomMargin: 2
            }

            radius: 10

            color: root.bg
            opacity: 0.88

            border.color: root.accent
            border.width: 1
        }

        /*
          Left side:
          λ + workspaces 1-9
        */
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 22
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Text {
                text: "λ"
                color: root.accent
                font.family: root.fontName
                font.pixelSize: 16
                verticalAlignment: Text.AlignVCenter
            }

            Row {
                spacing: 5
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: 9

                    delegate: Rectangle {
                        required property int index

                        width: 22
                        height: 22
                        radius: 6

                        color: root.activeWorkspace === index + 1
                            ? root.accent
                            : "transparent"

                        border.color: root.activeWorkspace === index + 1
                            ? root.accent
                            : root.muted

                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: index + 1

                            color: root.activeWorkspace === index + 1
                                ? root.bg
                                : root.fg

                            font.family: root.fontName
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }

        /*
          Centre:
          clickable clock/date toggle
        */
        Text {
            id: clock

            property bool showDate: false

            anchors.centerIn: parent

            text: showDate
                ? Qt.formatDateTime(new Date(), "(ddd dd MMM yyyy)")
                : Qt.formatDateTime(new Date(), "(ddd HH:mm)")

            color: root.fg
            font.family: root.fontName
            font.pixelSize: 13

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    clock.showDate = !clock.showDate
                    clock.text = clock.showDate
                        ? Qt.formatDateTime(new Date(), "(ddd dd MMM yyyy)")
                        : Qt.formatDateTime(new Date(), "(ddd HH:mm)")
                }
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true

            onTriggered: {
                clock.text = clock.showDate
                    ? Qt.formatDateTime(new Date(), "(ddd dd MMM yyyy)")
                    : Qt.formatDateTime(new Date(), "(ddd HH:mm)")
            }
        }

        /*
          Right side:
          clickable status units
        */
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 22
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            LispButton {
                text: "(" + root.ncText + ")"
                command: "xdg-open /home/glenn/Nextcloud"
                rightCommand: "nextcloud --background"
            }

            LispButton {
                text: "(" + root.varText + ")"
                command: "variety --next"
                rightCommand: "variety --preferences"
            }

            LispButton {
                text: "(" + root.wifiText + ")"
                command: "omarchy-launch-wifi"
            }

            LispButton {
                text: "(" + root.btText + ")"
                command: "omarchy-launch-bluetooth"
            }

            LispButton {
                text: "(" + root.volText + ")"
                command: "omarchy-launch-audio"
                rightCommand: "pamixer -t"
            }

            LispButton {
                text: "(" + root.cpuText + ")"
                command: "ghostty -e btop"
            }

            LispButton {
                text: "⏻"
                color: root.accent
                command: "/home/glenn/.local/bin/niri-power-menu"
            }
        }
    }

    /*
      Fast workspace polling.
    */
    Timer {
        interval: 150
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            workspaceProc.exec(["sh", "-c", "niri msg --json workspaces"])
        }
    }

    /*
      Nextcloud polling.
      Kept separate and fast so nc:on/off does not get stale.
    */
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            ncProc.exec(["sh", "-c", "if pgrep -f '^/usr/bin/nextcloud( |$)' >/dev/null; then echo nc:on; else echo nc:off; fi"])
        }
    }

    /*
      Slower system polling.
    */
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            wifiProc.exec(["sh", "-c", "iw dev wlan0 link 2>/dev/null | awk -F': ' '/SSID/ {print $2; exit}'"])

            btProc.exec(["sh", "-c", "count=0; for dev in $(busctl tree org.bluez 2>/dev/null | awk '/dev_/ {print $2}'); do busctl get-property org.bluez \"$dev\" org.bluez.Device1 Connected 2>/dev/null | grep -q true && count=$((count+1)); done; echo $count"])

            volProc.exec(["sh", "-c", "pamixer --get-volume-human 2>/dev/null || echo vol"])

            cpuProc.exec(["sh", "-c", "read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat; total=$((user+nice+system+idle+iowait+irq+softirq+steal)); idle_all=$((idle+iowait)); prev=/tmp/quickshell-cpu; if [ -f $prev ]; then read ptotal pidle < $prev; dt=$((total-ptotal)); di=$((idle_all-pidle)); if [ $dt -gt 0 ]; then echo $((100*(dt-di)/dt))%; else echo 0%; fi; else echo cpu; fi; echo $total $idle_all > $prev"])

            varProc.exec(["sh", "-c", "pgrep -f '^/usr/bin/python /usr/bin/variety' >/dev/null && echo var:on || echo var:off"])
        }
    }

    Process {
        id: workspaceProc

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const workspaces = JSON.parse(this.text)

                    for (let i = 0; i < workspaces.length; i++) {
                        const ws = workspaces[i]

                        if (ws.is_active || ws.is_focused) {
                            root.activeWorkspace = ws.idx || 1
                            return
                        }
                    }
                } catch (e) {
                    // Keep previous workspace highlight.
                }
            }
        }
    }

    Process {
        id: wifiProc

        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim()
                root.wifiText = text.length > 0 ? "wifi:" + text : "wifi:off"
            }
        }
    }

    Process {
        id: btProc

        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim()
                root.btText = text.length > 0 ? "bt:" + text : "bt:0"
            }
        }
    }

    Process {
        id: volProc

        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim()
                root.volText = text.length > 0 ? "vol:" + text : "vol"
            }
        }
    }

    Process {
        id: cpuProc

        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim()
                root.cpuText = text.length > 0 ? "cpu:" + text : "cpu"
            }
        }
    }

    Process {
        id: ncProc

        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim()
                root.ncText = text.length > 0 ? text : "nc:off"
            }
        }
    }

    Process {
        id: varProc

        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim()
                root.varText = text.length > 0 ? text : "var:off"
            }
        }
    }
}
