# Kookwekker (Toon QML-app)

Bestanden:
- KookwekkerApp.qml: timerlogica (hoofdbestand), opslag, alarm
- KookwekkerScreen.qml: hoofdscherm (lopende timers, snelkeuzes, eigen tijd)
- KookwekkerAlarmScreen.qml: knipperend scherm als een timer afloopt
- KookwekkerTile.qml: tile met de eerstvolgende afteltijd
- drawables/kookwekker.png

Testen op een geroote Toon:
1. Kopieer de map `kookwekker` naar `/qmf/qml/apps/kookwekker/` (zelfde plek als je andere apps). Via ToonStore: map `kookwekker-1.0.0` met symlink `kookwekker` -> `kookwekker-1.0.0`.
2. Herstart de GUI en voeg de tile toe via het tegel-overzicht.

Opslag: actieve timers staan in `/mnt/data/tsc/kookwekker_userSettings.json`
(werkt alleen als TSC schrijven via file:// toestaat, zoals bij andere apps).

Voor ToonStore: voeg `ToonRepo-entry.xml` toe aan ToonRepo.xml en lever de map aan als eigen app-repo.

Let op: deze versie is voor Toon 2 (QtQuick 2.1 / Qt5).
