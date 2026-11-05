// SPDX-License-Identifier: GPL-3.0-only
#include "EmberWindowsFeatures.h"
#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QSettings>
#include <QSet>
#include <QSysInfo>
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <qt_windows.h>
#include <psapi.h>
#include <tlhelp32.h>
#include <shobjidl.h>
#include <shlguid.h>
#include <objbase.h>
namespace Emberpvp::WindowsFeatures {
qint64 availableMemoryMiB() {
    MEMORYSTATUSEX memory{}; memory.dwLength=sizeof(memory);
    return GlobalMemoryStatusEx(&memory)?qint64(memory.ullAvailPhys/1024/1024):0;
}
qint64 residentBytes(qint64 pid) {
    HANDLE process=OpenProcess(PROCESS_QUERY_INFORMATION|PROCESS_VM_READ,FALSE,DWORD(pid));
    if(!process)return -1;
    PROCESS_MEMORY_COUNTERS counters{};counters.cb=sizeof(counters);
    const bool ok=GetProcessMemoryInfo(process,&counters,sizeof(counters));CloseHandle(process);
    return ok?qint64(counters.WorkingSetSize):-1;
}
QList<qint64> javaProcesses() {
    QList<qint64> result; HANDLE snapshot=CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0);
    if(snapshot==INVALID_HANDLE_VALUE)return result;
    PROCESSENTRY32W entry{};entry.dwSize=sizeof(entry);
    if(Process32FirstW(snapshot,&entry)) do {
        auto name=QString::fromWCharArray(entry.szExeFile).toLower();
        if(name=="java.exe" || name=="javaw.exe")result.append(entry.th32ProcessID);
    }while(Process32NextW(snapshot,&entry));
    CloseHandle(snapshot);return result;
}
QString memoryReport() {
    QString report=QString("Launcher resident RAM: %1 MiB\n").arg(residentBytes(QCoreApplication::applicationPid())/1024/1024);
    for(auto pid:javaProcesses()) {
        auto bytes=residentBytes(pid);
        report+=bytes<0?QString("Java PID %1: memory unavailable for this process\n").arg(pid):QString("Java PID %1: %2 MiB\n").arg(pid).arg(bytes/1024/1024);
    }
    MEMORYSTATUSEX memory{};memory.dwLength=sizeof(memory);
    if(GlobalMemoryStatusEx(&memory))report+=QString("\nSystem physical RAM: %1 MiB\nAvailable physical RAM: %2 MiB\nSystem memory load: %3%\n").arg(memory.ullTotalPhys/1024/1024).arg(memory.ullAvailPhys/1024/1024).arg(memory.dwMemoryLoad);
    return report;
}
QString hardwareReport() {
    QSettings cpu("HKEY_LOCAL_MACHINE\\HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0",QSettings::NativeFormat);
    SYSTEM_INFO system{};GetNativeSystemInfo(&system);
    QString report=QSysInfo::prettyProductName()+"\nArchitecture: "+QSysInfo::currentCpuArchitecture()+"\nCPU: "+cpu.value("ProcessorNameString","Not reported").toString().trimmed()+QString("\nLogical processors: %1\n").arg(system.dwNumberOfProcessors);
    QSet<QString> adapters;
    for(DWORD index=0;;++index) {
        DISPLAY_DEVICEW device{};device.cb=sizeof(device);
        if(!EnumDisplayDevicesW(nullptr,index,&device,0))break;
        auto name=QString::fromWCharArray(device.DeviceString);
        if(!name.isEmpty() && !(device.StateFlags & DISPLAY_DEVICE_MIRRORING_DRIVER))adapters.insert(name);
    }
    for(const auto& adapter:adapters)report+="Display adapter: "+adapter+'\n';
    return report;
}
QString quoteArgument(const QString& input) {
    QString result="\"";int backslashes=0;
    for(auto c:input) {
        if(c=='\\'){++backslashes;continue;}
        if(c=='"')result+=QString(backslashes*2+1,'\\')+'"';
        else result+=QString(backslashes,'\\')+c;
        backslashes=0;
    }
    return result+QString(backslashes*2,'\\')+'"';
}
bool worldShortcut(const QString& destination,const QString& instance,const QString& world,QString* error) {
    const HRESULT initialized=CoInitializeEx(nullptr,COINIT_APARTMENTTHREADED);
    IShellLinkW* link=nullptr;HRESULT hr=CoCreateInstance(CLSID_ShellLink,nullptr,CLSCTX_INPROC_SERVER,IID_IShellLinkW,reinterpret_cast<void**>(&link));
    if(SUCCEEDED(hr)) {
        const auto executable=QDir::toNativeSeparators(QCoreApplication::applicationFilePath());
        const auto args="--launch "+quoteArgument(instance)+" --world "+quoteArgument(world)+" --show-window";
        hr=link->SetPath(executable.toStdWString().c_str());
        if(SUCCEEDED(hr))hr=link->SetArguments(args.toStdWString().c_str());
        if(SUCCEEDED(hr))hr=link->SetWorkingDirectory(QFileInfo(executable).absolutePath().toStdWString().c_str());
        if(SUCCEEDED(hr))hr=link->SetDescription(("Emberpvp / "+world).toStdWString().c_str());
        IPersistFile* file=nullptr;
        if(SUCCEEDED(hr))hr=link->QueryInterface(IID_IPersistFile,reinterpret_cast<void**>(&file));
        if(SUCCEEDED(hr)) {hr=file->Save(QDir::toNativeSeparators(destination).toStdWString().c_str(),TRUE);file->Release();}
        link->Release();
    }
    if(SUCCEEDED(initialized))CoUninitialize();
    if(FAILED(hr) && error)*error=QString("Windows could not create the shortcut (HRESULT 0x%1).").arg(quint32(hr),8,16,QChar('0'));
    return SUCCEEDED(hr);
}
}
