#!/bin/bash

# 检查是否为 root 权限
if [ "$EUID" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

# 获取实际用户信息
REAL_USER=$(who am i | awk '{print $1}')
if [ -z "$REAL_USER" ]; then
    REAL_USER=$(logname)
fi
if [ -z "$REAL_USER" ]; then
    echo "错误：无法确定实际用户"
    exit 1
fi
REAL_HOME=$(eval echo ~$REAL_USER)

# 检查必要的命令
for cmd in python3 uuidgen ioreg; do
    if ! command -v $cmd &> /dev/null; then
        echo "错误：需要 $cmd 但未找到"
        exit 1
    fi
done

# 生成类似 macMachineId 的格式
generate_mac_machine_id() {
    python3 -c '
import uuid
import sys
def generate():
    template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    uuid = ""
    for c in template:
        if c == "x":
            uuid += hex(random.randint(0, 15))[2:]
        elif c == "y":
            r = random.randint(0, 15)
            uuid += hex((r & 0x3) | 0x8)[2:]
        else:
            uuid += c
    return uuid
import random
print(generate())
' 2>/dev/null || {
    echo "错误：Python 脚本执行失败"
    exit 1
}
}

# 生成64位随机ID
generate_random_id() {
    uuid1=$(uuidgen | tr -d '-')
    uuid2=$(uuidgen | tr -d '-')
    echo "${uuid1}${uuid2}"
}

# 检查 Cursor 进程
while pgrep -x "Cursor" > /dev/null || pgrep -f "Cursor.app" > /dev/null; do
    echo "检测到 Cursor 正在运行。请关闭 Cursor 后继续..."
    echo "正在等待 Cursor 进程退出..."
    sleep 1
done

echo "Cursor 已关闭，继续执行..."

# 备份原始的 IOPlatformUUID
BACKUP_DIR="$REAL_HOME/IOPlatformUUID_Backups"
mkdir -p "$BACKUP_DIR" || {
    echo "错误：无法创建备份目录"
    exit 1
}

ORIGINAL_UUID=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformUUID/{print $4}')
if [ -z "$ORIGINAL_UUID" ]; then
    echo "警告：无法获取原始 UUID"
fi

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/IOPlatformUUID_$TIMESTAMP.txt"
COUNTER=0

while [ -f "$BACKUP_FILE" ]; do
    COUNTER=$((COUNTER + 1))
    BACKUP_FILE="$BACKUP_DIR/IOPlatformUUID_${TIMESTAMP}_$COUNTER.txt"
done

echo "$ORIGINAL_UUID" > "$BACKUP_FILE" || {
    echo "错误：无法创建备份文件"
    exit 1
}

# 创建假的 ioreg 命令
FAKE_COMMANDS_DIR="$REAL_HOME/fake-commands"
mkdir -p "$FAKE_COMMANDS_DIR" || {
    echo "错误：无法创建命令目录"
    exit 1
}

cat > "$FAKE_COMMANDS_DIR/ioreg" << 'EOF'
#!/bin/bash

if [[ "$*" == *"-rd1 -c IOPlatformExpertDevice"* ]]; then
    UUID=$(uuidgen)
    cat << INNEREOF
+-o Root  <class IORegistryEntry, id 0x100000100, retain 12>
  +-o IOPlatformExpertDevice  <class IOPlatformExpertDevice, id 0x100000110, registered, matched, active, busy 0 (0 ms), retain 35>
    | {
    |   "IOPlatformUUID" = "$UUID"
    | }
INNEREOF
else
    exec /usr/sbin/ioreg "$@"
fi
EOF

chmod +x "$FAKE_COMMANDS_DIR/ioreg" || {
    echo "错误：无法设置命令文件权限"
    exit 1
}

# 更新 storage.json
STORAGE_JSON="$REAL_HOME/Library/Application Support/Cursor/User/globalStorage/storage.json"
NEW_MACHINE_ID=$(generate_random_id)
NEW_MAC_MACHINE_ID=$(generate_mac_machine_id)
NEW_DEV_DEVICE_ID=$(uuidgen)
NEW_SQM_ID="{$(uuidgen | tr '[:lower:]' '[:upper:]')}"

if [ -f "$STORAGE_JSON" ]; then
    # 备份原始文件
    cp "$STORAGE_JSON" "${STORAGE_JSON}.bak" || {
        echo "错误：无法备份 storage.json"
        exit 1
    }
    
    # 使用 Python 更新 JSON 文件
    python3 -c "
import json
try:
    with open('$STORAGE_JSON', 'r') as f:
        data = json.load(f)
    data['telemetry.machineId'] = '$NEW_MACHINE_ID'
    data['telemetry.macMachineId'] = '$NEW_MAC_MACHINE_ID'
    data['telemetry.devDeviceId'] = '$NEW_DEV_DEVICE_ID'
    data['telemetry.sqmId'] = '$NEW_SQM_ID'
    with open('$STORAGE_JSON', 'w') as f:
        json.dump(data, f, indent=2)
except Exception as e:
    print('错误：更新 storage.json 失败 -', str(e))
    exit(1)
" || {
    echo "错误：Python 脚本执行失败"
    exit 1
}
fi

# 修改文件所有权
chown -R $REAL_USER:$(id -gn $REAL_USER) "$FAKE_COMMANDS_DIR" || {
    echo "警告：无法修改命令目录所有权"
}
chown -R $REAL_USER:$(id -gn $REAL_USER) "$BACKUP_DIR" || {
    echo "警告：无法修改备份目录所有权"
}

echo "Successfully updated all IDs:"
echo "Backup file created at: $BACKUP_FILE"
echo "Fake ioreg command created at: $FAKE_COMMANDS_DIR/ioreg"
echo "New telemetry.machineId: $NEW_MACHINE_ID"
echo "New telemetry.macMachineId: $NEW_MAC_MACHINE_ID"
echo "New telemetry.devDeviceId: $NEW_DEV_DEVICE_ID"
echo "New telemetry.sqmId: $NEW_SQM_ID"
echo ""

# 自动配置 PATH
SHELL_CONFIG=""
PATH_EXPORT="export PATH=\"$FAKE_COMMANDS_DIR:\$PATH\""

# 检测用户的默认 shell
USER_SHELL=$(basename "$SHELL")
if [ -z "$USER_SHELL" ]; then
    USER_SHELL=$(basename $(grep "^$REAL_USER:" /etc/passwd | cut -d: -f7))
fi

# 根据不同的 shell 选择配置文件
case "$USER_SHELL" in
    "zsh")
        SHELL_CONFIG="$REAL_HOME/.zshrc"
        ;;
    "bash")
        if [ -f "$REAL_HOME/.bash_profile" ]; then
            SHELL_CONFIG="$REAL_HOME/.bash_profile"
        else
            SHELL_CONFIG="$REAL_HOME/.bashrc"
        fi
        ;;
    *)
        # 默认使用 .profile
        SHELL_CONFIG="$REAL_HOME/.profile"
        ;;
esac

# 检查配置是否已存在
if ! grep -q "$FAKE_COMMANDS_DIR" "$SHELL_CONFIG" 2>/dev/null; then
    # 添加配置到 shell 配置文件
    sudo -u $REAL_USER bash -c "echo '' >> \"$SHELL_CONFIG\"" || {
        echo "警告：无法更新 shell 配置文件"
    }
    sudo -u $REAL_USER bash -c "echo '# Added by Cursor Reset Script' >> \"$SHELL_CONFIG\"" || {
        echo "警告：无法更新 shell 配置文件"
    }
    sudo -u $REAL_USER bash -c "echo '$PATH_EXPORT' >> \"$SHELL_CONFIG\"" || {
        echo "警告：无法更新 shell 配置文件"
    }
    
    # 立即应用配置
    sudo -u $REAL_USER bash -c "export PATH=\"$FAKE_COMMANDS_DIR:\$PATH\""
    
    echo "PATH 配置已自动添加到 $SHELL_CONFIG"
    echo "配置已生效，无需手动操作"
else
    echo "PATH 配置已存在于 $SHELL_CONFIG，无需重复添加"
fi

echo "重置完成！请直接启动 Cursor 并使用新账号登录" 