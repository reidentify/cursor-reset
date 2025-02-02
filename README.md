# Cursor Reset Script

这是一个用于重置 Cursor IDE 设备标识的 PowerShell 脚本。该脚本支持 Cursor 0.45.x 版本（已在 0.45.8 版本上测试通过），仅支持 Windows 系统。

## ⚠️ 免责声明

本项目仅供学习和研究使用，旨在研究 Cursor IDE 的设备标识机制。**强烈建议您购买 [Cursor](https://cursor.sh/) 的正版授权**以支持开发者。

使用本脚本可能违反 Cursor 的使用条款。作者不对使用本脚本导致的任何问题负责，包括但不限于：

- 软件授权失效
- 账号封禁
- 其他未知风险

如果您认可 Cursor 的价值，请支持正版，为软件开发者的工作付费。

## 使用方法

1. 确保已关闭 Cursor IDE
2. 以管理员身份打开 PowerShell
3. 复制粘贴执行以下命令：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; iwr -Uri "https://raw.githubusercontent.com/hamflx/cursor-reset/refs/heads/main/reset.ps1" -UseBasicParsing | iex
```

如果脚本卡在"正在等待 Cursor 进程退出..."，可以在管理员权限的命令行中执行以下命令强制结束所有 Cursor 进程：

```powershell
taskkill /f /im cursor.exe
```

## ⚠️ 重要注意事项

脚本会修改系统注册表中的 `HKLM\SOFTWARE\Microsoft\Cryptography\MachineGuid`，这个值可能被其他软件用作设备标识，如果你购买了 Cursor 的正版授权或其他使用此注册表项作为设备标识的正版软件，修改后可能会导致这些软件的授权失效。

原始的 MachineGuid 会被自动备份到 `%USERPROFILE%\MachineGuid_Backups` 目录下，如果需要恢复原始 MachineGuid，可以从备份目录中找到对应的备份文件，然后通过注册表编辑器恢复该值。

## 执行结果

脚本执行成功后，会显示以下信息：

- 备份文件的位置
- 新生成的 MachineGuid
- 新的 telemetry.machineId
- 新的 telemetry.macMachineId
- 新的 telemetry.devDeviceId
- 新的 telemetry.sqmId

## 系统要求

- Windows 操作系统
- PowerShell
- 管理员权限
- Cursor IDE 0.45.x 版本（已在 0.45.8 版本测试通过）

---

This is a PowerShell script for resetting Cursor IDE device identifiers. The script supports Cursor 0.45.x (tested on version 0.45.8) and is Windows-only.

## ⚠️ Disclaimer

This project is for educational and research purposes only, aimed at studying the device identification mechanism of Cursor IDE. **It is strongly recommended to purchase a [Cursor](https://cursor.sh/) license** to support the developers.

Using this script may violate Cursor's terms of service. The author assumes no responsibility for any issues arising from the use of this script, including but not limited to:

- Software license invalidation
- Account suspension
- Other unknown risks

If you value Cursor, please support the official version and pay for the developers' work.

## Usage

1. Make sure Cursor IDE is closed
2. Open PowerShell as Administrator
3. Copy and paste the following command:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; iwr -Uri "https://raw.githubusercontent.com/hamflx/cursor-reset/refs/heads/main/reset.ps1" -UseBasicParsing | iex
```

If the script is stuck at "Waiting for Cursor process to exit...", you can force kill all Cursor processes by running the following command in an administrator command prompt:

```powershell
taskkill /f /im cursor.exe
```

## ⚠️ Important Notes

The script modifies the system registry key `HKLM\SOFTWARE\Microsoft\Cryptography\MachineGuid`, which may be used by other software as a device identifier. If you have purchased a license for Cursor or other software that uses this registry key for device identification, modifying it may invalidate these software licenses.

The original MachineGuid will be automatically backed up to the `%USERPROFILE%\MachineGuid_Backups` directory. If you need to restore the original MachineGuid, you can find the corresponding backup file in this directory and restore it using the registry editor.

## Execution Results

After successful execution, the script will display:

- Backup file location
- New MachineGuid
- New telemetry.machineId
- New telemetry.macMachineId
- New telemetry.devDeviceId
- New telemetry.sqmId

## System Requirements

- Windows OS
- PowerShell
- Administrator privileges
- Cursor IDE 0.45.x (tested on version 0.45.8)
