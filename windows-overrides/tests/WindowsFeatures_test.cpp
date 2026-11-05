// SPDX-License-Identifier: GPL-3.0-only
#include <QTest>
#include <QTemporaryDir>
#include "platform/windows/EmberWindowsFeatures.h"
#include <shellapi.h>
using namespace Emberpvp::WindowsFeatures;
class WindowsFeaturesTest final : public QObject {
    Q_OBJECT
private slots:
    void memoryAndHardwareUseWindowsApis() {
        QVERIFY(availableMemoryMiB() > 0);
        QVERIFY(residentBytes(QCoreApplication::applicationPid()) > 0);
        QCOMPARE(residentBytes(-1), qint64(-1));
        QVERIFY(memoryReport().contains("System physical RAM:"));
        QVERIFY(hardwareReport().contains("Logical processors:"));
    }
    void commandArgumentsRoundTrip() {
        const QStringList values { "", "simple", "two words", "a\"b", "C:\\with spaces\\", "\\\\server\\share\\", "two\\\"quotes", QString::fromUtf8("World \xE2\x98\x85") };
        QString command = "launcher.exe";
        for (const auto& value : values) command += ' ' + quoteArgument(value);
        int count = 0;
        auto** args = CommandLineToArgvW(command.toStdWString().c_str(), &count);
        QVERIFY(args);
        QStringList decoded;
        for (int i = 1; i < count; ++i) decoded.append(QString::fromWCharArray(args[i]));
        LocalFree(args);
        QCOMPARE(decoded, values);
    }
    void createsPerUserWorldShortcutWithoutElevation() {
        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        const auto path = dir.filePath("world.lnk");
        QString error;
        QVERIFY2(worldShortcut(path, "Instance with spaces", "World with spaces", &error), qPrintable(error));
        QVERIFY(QFileInfo::exists(path));
        const auto initialized = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
        IShellLinkW* link = nullptr;
        HRESULT result = CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER, IID_IShellLinkW, reinterpret_cast<void**>(&link));
        QString target, arguments;
        if (SUCCEEDED(result)) {
            IPersistFile* file = nullptr;
            result = link->QueryInterface(IID_IPersistFile, reinterpret_cast<void**>(&file));
            if (SUCCEEDED(result)) {
                result = file->Load(QDir::toNativeSeparators(path).toStdWString().c_str(), STGM_READ);
                file->Release();
            }
            wchar_t buffer[32768] {};
            if (SUCCEEDED(result)) result = link->GetPath(buffer, 32768, nullptr, SLGP_RAWPATH);
            if (SUCCEEDED(result)) target = QString::fromWCharArray(buffer);
            if (SUCCEEDED(result)) result = link->GetArguments(buffer, 32768);
            if (SUCCEEDED(result)) arguments = QString::fromWCharArray(buffer);
            link->Release();
        }
        if (SUCCEEDED(initialized)) CoUninitialize();
        QVERIFY(SUCCEEDED(result));
        QCOMPARE(QDir::fromNativeSeparators(target), QCoreApplication::applicationFilePath());
        QCOMPARE(arguments, QString("--launch \"Instance with spaces\" --world \"World with spaces\" --show-window"));
    }
};
QTEST_GUILESS_MAIN(WindowsFeaturesTest)
#include "WindowsFeatures_test.moc"
