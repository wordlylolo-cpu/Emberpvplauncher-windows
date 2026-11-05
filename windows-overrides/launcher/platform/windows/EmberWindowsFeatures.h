// SPDX-License-Identifier: GPL-3.0-only
#pragma once
#include <QList>
#include <QString>
#ifdef Q_OS_WIN
namespace Emberpvp::WindowsFeatures {
qint64 availableMemoryMiB();
qint64 residentBytes(qint64 pid);
QList<qint64> javaProcesses();
QString memoryReport();
QString hardwareReport();
QString quoteArgument(const QString& input);
bool worldShortcut(const QString& destination, const QString& instance, const QString& world, QString* error);
}
#endif
