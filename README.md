# Cursor Reset Script

这是一个用于重置 Cursor IDE 设备标识的 PowerShell 脚本。该脚本支持 Cursor 0.45.x 版本（已在 0.45.8 版本上测试通过）。

⚠️ 注意：macOS 版本的脚本由 Cursor AI 生成，尚未经过实际测试，可能存在问题。如果您在使用过程中遇到任何问题，欢迎提交 issue。

## ⚠️ 免责声明

本项目仅供学习和研究使用，旨在研究 Cursor IDE 的设备标识机制。**强烈建议您购买 [Cursor](https://cursor.sh/) 的正版授权**以支持开发者。

使用本脚本可能违反 Cursor 的使用条款。作者不对使用本脚本导致的任何问题负责，包括但不限于：

- 软件授权失效
- 账号封禁
- 其他未知风险

如果您认可 Cursor 的价值，请支持正版，为软件开发者的工作付费。

## 使用方法

⚠️ 为避免新账号立即失效，请严格按照以下步骤操作：

### Windows

1. 在 Cursor IDE 中退出当前登录的账号
2. 下载[PowerShell 7](https://github.com/PowerShell/PowerShell/releases) ,使用默认的PowerShel 5 Json格式会出问题

    ```powershell
        #查询PowerShell版本号
        $PSVersionTable.PSVersion
    ```

3. 以管理员身份打开 PowerShell
4. 复制粘贴执行以下命令：

   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; iwr -Uri "https://raw.githubusercontent.com/reidentify/cursor-reset/refs/heads/main/reset.ps1" -UseBasicParsing | iex
   ```

5. 重置完成后打开 Cursor IDE，使用新的账号登录（不要使用之前的账号）

### macOS

1. 在 Cursor IDE 中退出当前登录的账号
2. 完全关闭 Cursor IDE
3. 打开终端，执行以下命令：

   ```bash
   curl -o /tmp/reset.sh https://raw.githubusercontent.com/hamflx/cursor-reset/refs/heads/main/reset.sh && chmod +x /tmp/reset.sh && sudo /tmp/reset.sh
   ```

4. 启动 Cursor 并使用新账号登录（不要使用之前的账号）

如果脚本卡在"正在等待 Cursor 进程退出..."，可以在终端中执行以下命令强制结束 Cursor 进程：

```bash
pkill -9 Cursor
```

## ⚠️ 重要注意事项

### Windows

脚本会修改系统注册表中的 `HKLM\SOFTWARE\Microsoft\Cryptography\MachineGuid`，这个值可能被其他软件用作设备标识，如果你购买了 Cursor 的正版授权或其他使用此注册表项作为设备标识的正版软件，修改后可能会导致这些软件的授权失效。

原始的 MachineGuid 会被自动备份到 `%USERPROFILE%\MachineGuid_Backups` 目录下，如果需要恢复原始 MachineGuid，可以从备份目录中找到对应的备份文件，然后通过注册表编辑器恢复该值。

### macOS

脚本会创建一个假的 `ioreg` 命令来模拟不同的设备标识。原始的 IOPlatformUUID 会被备份到 `~/IOPlatformUUID_Backups` 目录下。这个方法不会永久修改系统设置，但需要保持 PATH 环境变量的修改才能持续生效。

## 执行结果

脚本执行成功后，会显示以下信息：

- 备份文件的位置
- 新生成的 MachineGuid
- 新的 telemetry.machineId
- 新的 telemetry.macMachineId
- 新的 telemetry.devDeviceId
- 新的 telemetry.sqmId

## 系统要求

### Windows

- Windows 操作系统
- PowerShell
- 管理员权限
- Cursor IDE 0.45.x 版本（已在 0.45.8 版本测试通过）

### macOS

- macOS 10.13 或更高版本
- Python 3
- sudo 权限
- Cursor IDE 0.45.x 版本
