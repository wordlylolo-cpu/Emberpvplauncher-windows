// SPDX-License-Identifier: GPL-3.0-only
#include <QTest>
#include <QTemporaryDir>
#include "minecraft/InstanceSnapshot.h"
class InstanceSnapshotTest : public QObject {
    Q_OBJECT
private slots:
    void copiesWorldsAndSettingsWithoutChangingOriginal() {
        QTemporaryDir temp; QVERIFY(temp.isValid());
        const auto game=temp.path()+"/game", root=temp.path()+"/backups";
        QVERIFY(QDir().mkpath(game+"/saves/world"));
        QFile file(game+"/saves/world/level.dat"); QVERIFY(file.open(QIODevice::WriteOnly)); file.write("world-data"); file.close();
        QVERIFY(Emberpvp::Snapshots::makeSnapshot(game,root).isEmpty());
        auto entries=QDir(root).entryList(QDir::Dirs|QDir::NoDotAndDotDot); QCOMPARE(entries.size(),1);
        QFile copy(root+'/'+entries.first()+"/saves/world/level.dat"); QVERIFY(copy.open(QIODevice::ReadOnly)); QCOMPARE(copy.readAll(),QByteArray("world-data"));
        QVERIFY(QFileInfo::exists(root+'/'+entries.first()+"/snapshot.json"));
        QVERIFY(file.open(QIODevice::ReadOnly)); QCOMPARE(file.readAll(),QByteArray("world-data"));
    }
    void refusesLinksAndDoesNotPublishPartialSnapshot() {
        QTemporaryDir temp; QVERIFY(temp.isValid());
        QVERIFY(QDir().mkpath(temp.path()+"/game/config"));
        QFile external(temp.path()+"/external"); QVERIFY(external.open(QIODevice::WriteOnly));external.write("private");external.close();
        QString link = temp.path()+"/game/config/link";
#ifdef Q_OS_WIN
        // Qt requires a .lnk extension for a Windows shortcut.
        link += ".lnk";
#endif
        QVERIFY(QFile::link(external.fileName(), link));
        QVERIFY(Emberpvp::Snapshots::isLink(QFileInfo(link)));
        QVERIFY(!Emberpvp::Snapshots::makeSnapshot(temp.path()+"/game",temp.path()+"/backups").isEmpty());
        QCOMPARE(QDir(temp.path()+"/backups").entryList(QDir::Dirs|QDir::NoDotAndDotDot).size(),0);
    }
};
QTEST_GUILESS_MAIN(InstanceSnapshotTest)
#include "InstanceSnapshot_test.moc"
