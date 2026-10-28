import QtQuick 2.1
import qb.components 1.0

Tile {
	id: kookwekkerTile
	onClicked: stage.openFullscreen(app.screenUrl)

	property real sc: width / 200

	Text {
		id: tileLabel
		anchors.horizontalCenter: parent.horizontalCenter
		y: Math.round(parent.height * 0.14)
		width: parent.width - Math.round(16 * kookwekkerTile.sc)
		horizontalAlignment: Text.AlignHCenter
		elide: Text.ElideRight
		text: app.summaryLabel
		font.family: qfont.regular.name
		font.pixelSize: Math.round(18 * kookwekkerTile.sc)
		color: colors.tileTextColor
	}

	Text {
		id: tileTime
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.verticalCenter: parent.verticalCenter
		anchors.verticalCenterOffset: Math.round(10 * kookwekkerTile.sc)
		text: app.summaryTime
		font.family: qfont.bold.name
		font.pixelSize: Math.round(40 * kookwekkerTile.sc)
		color: app.anyDone ? "#d9534f" : colors.tileTextColor
	}
}
