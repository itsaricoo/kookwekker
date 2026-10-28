import QtQuick 2.1
import qb.components 1.0
import qb.base 1.0

App {
	id: kookwekkerApp

	property url tileUrl: "KookwekkerTile.qml"
	property url screenUrl: "KookwekkerScreen.qml"
	property url alarmScreenUrl: "KookwekkerAlarmScreen.qml"
	property url thumbnailIcon: "qrc:/tsc/flameSmall.png"

	property KookwekkerTile kookwekkerTile
	property KookwekkerScreen kookwekkerScreen
	property KookwekkerAlarmScreen kookwekkerAlarmScreen

	property alias timers: timersModel
	property int maxTimers: 4
	property string settingsPath: "file:///mnt/data/tsc/kookwekker_userSettings.json"

	// Snelkeuzes: pas gerust aan
	property variant presets: [
		{label: "Ei zacht", minutes: 6},
		{label: "Ei hard", minutes: 9},
		{label: "Thee", minutes: 3},
		{label: "Pasta", minutes: 10},
		{label: "Rijst", minutes: 12},
		{label: "Oven", minutes: 20}
	]

	// Samenvatting voor de tile en het alarmscherm
	property string summaryTime: "Start"
	property string summaryLabel: "Kookwekker"
	property string doneText: ""
	property bool anyDone: false
	property int activeCount: 0

	property bool ringing: false
	property variant audioObj: null
	property bool soundBroken: false

	ListModel {
		id: timersModel
	}

	Timer {
		id: tickTimer
		interval: 1000
		repeat: true
		running: timersModel.count > 0
		onTriggered: kookwekkerApp.tick()
	}

	// Herhaalt het geluid zolang het alarm afgaat
	Timer {
		id: soundRepeat
		interval: 2500
		repeat: true
		running: false
		onTriggered: {
			try {
				kookwekkerApp.audioObj.stop();
				kookwekkerApp.audioObj.play();
			} catch (e) {}
		}
	}

	// Geluid stopt vanzelf na 90 seconden
	Timer {
		id: soundLimit
		interval: 90000
		repeat: false
		running: false
		onTriggered: kookwekkerApp.stopSound()
	}

	function init() {
		registry.registerWidget("tile", tileUrl, this, "kookwekkerTile", {
			thumbLabel: "Kookwekker",
			thumbIcon: thumbnailIcon,
			thumbCategory: "general",
			thumbWeight: 30,
			baseTileWeight: 10,
			baseTileSolarWeight: 10,
			thumbIconVAlignment: "center"
		});
		registry.registerWidget("screen", screenUrl, this, "kookwekkerScreen");
		registry.registerWidget("screen", alarmScreenUrl, this, "kookwekkerAlarmScreen");
		loadTimers();
	}

	function nowSec() {
		return Math.floor(new Date().getTime() / 1000);
	}

	function pad(n) {
		return (n < 10 ? "0" : "") + n;
	}

	function fmt(sec) {
		var h = Math.floor(sec / 3600);
		var m = Math.floor((sec % 3600) / 60);
		var s = sec % 60;
		if (h > 0)
			return h + ":" + pad(m) + ":" + pad(s);
		return pad(m) + ":" + pad(s);
	}

	function addTimer(label, seconds) {
		if (timersModel.count >= maxTimers)
			return false;
		timersModel.append({
			"label": label,
			"endSec": nowSec() + seconds,
			"totalSec": seconds,
			"remaining": seconds,
			"done": false
		});
		saveTimers();
		updateSummary();
		return true;
	}

	function removeTimer(index) {
		if (index < 0 || index >= timersModel.count)
			return;
		timersModel.remove(index);
		saveTimers();
		updateSummary();
	}

	function extendTimer(index, seconds) {
		if (index < 0 || index >= timersModel.count)
			return;
		var t = timersModel.get(index);
		var now = nowSec();
		if (t.done || t.endSec <= now) {
			timersModel.setProperty(index, "endSec", now + seconds);
			timersModel.setProperty(index, "totalSec", seconds);
			timersModel.setProperty(index, "remaining", seconds);
		} else {
			timersModel.setProperty(index, "endSec", t.endSec + seconds);
			timersModel.setProperty(index, "totalSec", t.totalSec + seconds);
			timersModel.setProperty(index, "remaining", t.endSec + seconds - now);
		}
		timersModel.setProperty(index, "done", false);
		saveTimers();
		updateSummary();
	}

	function dismissDone() {
		for (var i = timersModel.count - 1; i >= 0; i--) {
			if (timersModel.get(i).done)
				timersModel.remove(i);
		}
		saveTimers();
		updateSummary();
	}

	function tick() {
		var now = nowSec();
		var newlyDone = 0;
		for (var i = 0; i < timersModel.count; i++) {
			var t = timersModel.get(i);
			var rem = t.endSec - now;
			if (rem < 0)
				rem = 0;
			if (t.remaining !== rem)
				timersModel.setProperty(i, "remaining", rem);
			if (rem === 0 && !t.done) {
				timersModel.setProperty(i, "done", true);
				newlyDone++;
			}
		}
		updateSummary();
		if (newlyDone > 0)
			startAlarm();
	}

	function updateSummary() {
		var best = -1;
		var bestRem = 0;
		var done = 0;
		var names = [];
		for (var i = 0; i < timersModel.count; i++) {
			var t = timersModel.get(i);
			if (t.done) {
				done++;
				names.push(t.label);
			} else if (best < 0 || t.remaining < bestRem) {
				best = i;
				bestRem = t.remaining;
			}
		}
		anyDone = done > 0;
		doneText = names.join(", ");
		activeCount = timersModel.count - done;
		if (done > 0) {
			summaryTime = "Klaar!";
			summaryLabel = doneText;
		} else if (best >= 0) {
			summaryTime = fmt(bestRem);
			summaryLabel = timersModel.get(best).label + (activeCount > 1 ? " (+" + (activeCount - 1) + ")" : "");
		} else {
			summaryTime = "Start";
			summaryLabel = "Kookwekker";
		}
	}

	function startAlarm() {
		if (ringing)
			return;
		ringing = true;
		try {
			if (typeof screenStateController !== "undefined")
				screenStateController.wakeup();
		} catch (e) {}
		stage.openFullscreen(alarmScreenUrl);
	}

	// Wordt aangeroepen als het alarmscherm sluit (Stop of wegnavigeren)
	function alarmClosed() {
		ringing = false;
		stopSound();
	}

	function startSound() {
		if (soundBroken)
			return;
		try {
			if (audioObj === null) {
				audioObj = Qt.createQmlObject(
					'import QtQuick 2.1\nimport QtMultimedia 5.0\nAudio { source: "' + Qt.resolvedUrl("sounds/alarm.wav") + '" }',
					kookwekkerApp, "kookwekkerAudio");
			}
			audioObj.play();
			soundRepeat.restart();
			soundLimit.restart();
		} catch (e) {
			// Geen audio-module beschikbaar: alleen visueel alarm
			soundBroken = true;
		}
	}

	function stopSound() {
		soundRepeat.stop();
		soundLimit.stop();
		try {
			if (audioObj !== null)
				audioObj.stop();
		} catch (e) {}
	}

	function saveTimers() {
		var arr = [];
		for (var i = 0; i < timersModel.count; i++) {
			var t = timersModel.get(i);
			arr.push({label: t.label, endSec: t.endSec, totalSec: t.totalSec});
		}
		try {
			var doc = new XMLHttpRequest();
			doc.open("PUT", settingsPath);
			doc.send(JSON.stringify({timers: arr}));
		} catch (e) {}
	}

	function loadTimers() {
		try {
			var doc = new XMLHttpRequest();
			doc.onreadystatechange = function() {
				if (doc.readyState === 4 && doc.responseText) {
					try {
						var data = JSON.parse(doc.responseText);
						var now = nowSec();
						for (var i = 0; i < data.timers.length && timersModel.count < maxTimers; i++) {
							var t = data.timers[i];
							if (t.endSec > now) {
								timersModel.append({
									"label": t.label,
									"endSec": t.endSec,
									"totalSec": t.totalSec,
									"remaining": t.endSec - now,
									"done": false
								});
							}
						}
					} catch (e) {}
					updateSummary();
				}
			};
			doc.open("GET", settingsPath, true);
			doc.send();
		} catch (e) {}
	}
}
