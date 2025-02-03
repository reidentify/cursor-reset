# 导入需要的类型
Add-Type -AssemblyName System.Web.Extensions

# 生成类似 macMachineId 的格式
function New-MacMachineId {
    $template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    $result = ""
    $random = [Random]::new()
    
    foreach ($char in $template.ToCharArray()) {
        if ($char -eq 'x' -or $char -eq 'y') {
            $r = $random.Next(16)
            $v = if ($char -eq "x") { $r } else { ($r -band 0x3) -bor 0x8 }
            $result += $v.ToString("x")
        } else {
            $result += $char
        }
    }
    return $result
}

# 生成64位随机ID
function New-RandomId {
    $uuid1 = [guid]::NewGuid().ToString("N")
    $uuid2 = [guid]::NewGuid().ToString("N")
    return $uuid1 + $uuid2
}

# 等待 Cursor 进程退出
$cursorProcesses = Get-Process "cursor" -ErrorAction SilentlyContinue
if ($cursorProcesses) {
    Write-Host "检测到 Cursor 正在运行。请关闭 Cursor 后继续..."
    Write-Host "正在等待 Cursor 进程退出..."
    
    # Force stop all Cursor processes
    Stop-Process -Name "cursor" -Force -ErrorAction SilentlyContinue
    
    while ($true) {
        $cursorProcesses = Get-Process "cursor" -ErrorAction SilentlyContinue
        if (-not $cursorProcesses) {
            Write-Host "Cursor 已关闭，继续执行..."
            break
        }
        Start-Sleep -Seconds 1
    }
}

# 备份 MachineGuid
$backupDir = Join-Path $HOME "MachineGuid_Backups"
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}

$currentValue = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name MachineGuid
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = Join-Path $backupDir "MachineGuid_$timestamp.txt"
$counter = 0

while (Test-Path $backupFile) {
    $counter++
    $backupFile = Join-Path $backupDir "MachineGuid_${timestamp}_$counter.txt"
}

$currentValue.MachineGuid | Out-File $backupFile

# 使用环境变量构建 storage.json 路径
$storageJsonPath = Join-Path $env:APPDATA "Cursor\User\globalStorage\storage.json"
$newMachineId = New-RandomId
$newMacMachineId = New-MacMachineId
$newDevDeviceId = [guid]::NewGuid().ToString()
$newSqmId = "{$([guid]::NewGuid().ToString().ToUpper())}"

if (Test-Path $storageJsonPath) {
    # 创建备份
    $backupDir = Join-Path $HOME "storage_json_backups"
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir | Out-Null
    }
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $storageBackupPath = Join-Path $backupDir "storage_$timestamp.json"
    Copy-Item -Path $storageJsonPath -Destination $storageBackupPath -Force

    try {
		# 设置为普通属性
		$file = Get-Item $storageJsonPath
		$file.Attributes = $file.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)

        # 读取并解析 JSON
        $jsonContent = Get-Content $storageJsonPath -Raw | ConvertFrom-Json
        
        # 只更新存在的字段
        if ($jsonContent.PSObject.Properties["telemetry.machineId"]) {
            $jsonContent."telemetry.machineId" = $newMachineId
        }
        if ($jsonContent.PSObject.Properties["telemetry.macMachineId"]) {
            $jsonContent."telemetry.macMachineId" = $newMacMachineId
        }
        if ($jsonContent.PSObject.Properties["telemetry.devDeviceId"]) {
            $jsonContent."telemetry.devDeviceId" = $newDevDeviceId
        }
        if ($jsonContent.PSObject.Properties["telemetry.sqmId"]) {
            $jsonContent."telemetry.sqmId" = $newSqmId
        }
        
        # 保存修改后的 JSON，保持原有格式和编码
        $jsonContent | ConvertTo-Json -Depth 10 | Out-File $storageJsonPath -Encoding UTF8
    
        # 强制设置只读属性
        $file = Get-Item $storageJsonPath
        $file.Attributes = $file.Attributes -bor [System.IO.FileAttributes]::ReadOnly
        
        Write-Host "storage.json 更新成功并设置为只读!"
        Write-Host "备份文件保存在: $storageBackupPath"
        
        # 验证只读属性
        $finalAttributes = (Get-Item $storageJsonPath).Attributes
        if ($finalAttributes.HasFlag([System.IO.FileAttributes]::ReadOnly)) {
            Write-Host "只读属性设置成功"
        } else {
            Write-Host "警告：只读属性设置失败"
        }
    }
    catch {
        Write-Host "错误: storage.json 解析失败，正在恢复备份..."
        Copy-Item -Path $storageBackupPath -Destination $storageJsonPath -Force
        Write-Host "已从备份恢复: $storageBackupPath"
    }
}

# 更新注册表 MachineGuid
$newMachineGuid = [guid]::NewGuid().ToString()
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Cryptography" -Name "MachineGuid" -Value $newMachineGuid

Write-Host "Successfully updated all IDs:"
Write-Host "Backup file created at: $backupFile"
Write-Host "New MachineGuid: $newMachineGuid"
Write-Host "New telemetry.machineId: $newMachineId"
Write-Host "New telemetry.macMachineId: $newMacMachineId"
Write-Host "New telemetry.devDeviceId: $newDevDeviceId"
Write-Host "New telemetry.sqmId: $newSqmId"