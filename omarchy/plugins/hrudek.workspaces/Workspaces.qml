import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  function workspaceIds() {
    var ids = []
    var values = Hyprland.workspaces.values
    var focusedId = Hyprland.focusedWorkspace !== null ? Hyprland.focusedWorkspace.id : -1

    for (var i = 0; i < values.length; i++) {
      var workspace = values[i]
      var id = workspace.id
      var occupied = workspace.toplevels.values.length > 0
      if (id > 0 && id <= 10 && (occupied || id === focusedId)) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      WidgetButton {
        id: workspaceButton

        required property int modelData

        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

        bar: root.bar
        text: modelData === 10 ? "0" : String(modelData)
        labelVisible: false
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        onPressed: function() { root.focusWorkspace(modelData) }

        Rectangle {
          anchors.fill: parent
          visible: workspaceButton.focused
          color: "#313244"
        }

        Text {
          anchors.centerIn: parent
          text: workspaceButton.text
          color: workspaceButton.focused ? "#b4befe" : workspaceButton.foreground
          font.family: workspaceButton.fontFamily
          font.pixelSize: workspaceButton.fontSize
          font.weight: workspaceButton.focused ? Font.DemiBold : Font.Normal
          renderType: Text.NativeRendering
        }
      }
    }
  }
}
