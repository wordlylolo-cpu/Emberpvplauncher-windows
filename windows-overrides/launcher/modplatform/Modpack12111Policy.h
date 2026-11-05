// SPDX-License-Identifier: GPL-3.0-only
#pragma once

#include <QJsonObject>
#include <QString>

namespace Modpack12111 {
inline QString validateDependencies(const QJsonObject& dependencies)
{
    if (dependencies.value(QStringLiteral("minecraft")).toString() != QLatin1String("1.21.11") ||
        dependencies.value(QStringLiteral("fabric-loader")).toString().isEmpty()) {
        return QStringLiteral("Modpack must target Minecraft 1.21.11 with Fabric Loader.");
    }
    for (auto it = dependencies.constBegin(); it != dependencies.constEnd(); ++it) {
        if (it.key() != QLatin1String("minecraft") && it.key() != QLatin1String("fabric-loader")) {
            return QStringLiteral("Unsupported modpack loader or dependency: %1").arg(it.key());
        }
    }
    return {};
}
}
