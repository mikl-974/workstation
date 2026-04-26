import QtQuick
import qs.Commons
import qs.Widgets

NIcon {
  id: root

  property bool crossed: false

  icon: "world"
  pointSize: Style.fontSizeXL
  applyUiScale: true

  Rectangle {
    visible: root.crossed
    anchors.centerIn: parent
    width: parent.width * 1.1
    height: Math.max(2, parent.height * 0.12)
    radius: height / 2
    color: root.color
    rotation: -45
  }
}
