// SPDX-License-Identifier: GPL-3.0-only
#pragma once
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QDateTime>
#include <QJsonDocument>
#include <QJsonObject>
#include <QUuid>
namespace Emberpvp::Snapshots {
inline bool isLink(const QFileInfo& info) {
    return info.isSymLink() || info.isShortcut() || info.isJunction();
}
inline QString copyTree(const QString& from, const QString& to) {
    if (!QFileInfo(from).isDir()) return QStringLiteral("Cannot read source directory: ")+from;
    if (isLink(QFileInfo(from))) return QStringLiteral("Symbolic links are not included in snapshots: ")+from;
    if (!QDir().mkpath(to)) return QStringLiteral("Cannot create snapshot directory: ")+to;
    QDir source(from);
    for (const auto& f: source.entryInfoList(QDir::Files|QDir::Dirs|QDir::NoDotAndDotDot|QDir::Hidden|QDir::System)) {
        if (isLink(f)) return QStringLiteral("Symbolic links are not included in snapshots: ")+f.fileName();
        const auto target=to+'/'+f.fileName();
        if (f.isDir()) { auto e=copyTree(f.filePath(),target); if (!e.isEmpty()) return e; }
        else if (!QFile::copy(f.filePath(),target)) return QStringLiteral("Cannot copy ")+f.fileName();
    }
    return {};
}
inline QString makeSnapshot(const QString& game,const QString& root) {
    const auto name=QDateTime::currentDateTimeUtc().toString("yyyyMMdd-HHmmss-zzz")+'-'+QUuid::createUuid().toString(QUuid::Id128).left(8);
    const auto staging=root+'/'+name+".partial";
    if(!QDir().mkpath(staging))return "Cannot create snapshot directory.";
    for (const QString entry: {"saves","config","mods","options.txt","servers.dat"}) {
        const auto source=game+'/'+entry;
        if (!QFileInfo::exists(source)) continue;
        QString error;
        if (isLink(QFileInfo(source))) error="Snapshot entry is a symbolic link: "+entry;
        else if (QFileInfo(source).isDir()) error=copyTree(source,staging+'/'+entry);
        else if (!QFile::copy(source,staging+'/'+entry)) error="Cannot copy "+entry;
        if (!error.isEmpty()) { QDir(staging).removeRecursively(); return error; }
    }
    QFile manifest(staging+"/snapshot.json");
    if (!manifest.open(QIODevice::WriteOnly)) return "Cannot write snapshot manifest.";
    manifest.write(QJsonDocument(QJsonObject{{"format",1},{"minecraft","1.21.11"},{"loader","fabric"}}).toJson()); manifest.close();
    if (!QDir().rename(staging,root+'/'+name)) return "Cannot finish snapshot.";
    return {};
}
}
