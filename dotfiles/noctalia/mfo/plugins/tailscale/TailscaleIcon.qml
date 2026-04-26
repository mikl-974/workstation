import QtQuick
import qs.Commons
import qs.Widgets

NIcon {
  id: root

  property bool crossed: false

  icon: "network"
  pointSize: Style.fontSizeL
  applyUiScale: true

  Rectangle {
    visible: root.crossed
    anchors.centerIn: parent
    width: parent.width * 1.2
    height: Math.max(2, parent.height * 0.15)
    radius: height / 2
    color: root.color
    rotation: -45
  }
}
