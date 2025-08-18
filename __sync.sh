#!/bin/bash

# rsync增量同步脚本
# 用法: ./sync.sh [源文件夹] [目标文件夹]
# 默认源文件夹为当前路径，默认目标文件夹为指定的iCloud路径

# 设置默认参数
DEFAULT_SOURCE="."
DEFAULT_TARGET="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/ENGLISH"

# 获取参数，如果没有提供则使用默认值
SOURCE_DIR="${1:-$DEFAULT_SOURCE}"
TARGET_DIR="${2:-$DEFAULT_TARGET}"

# 检查源文件夹是否存在
if [ ! -d "$SOURCE_DIR" ]; then
    echo "错误: 源文件夹不存在: $SOURCE_DIR" >&2
    exit 1
fi

# 检查目标文件夹是否存在，如果不存在则创建
if [ ! -d "$TARGET_DIR" ]; then
    mkdir -p "$TARGET_DIR"
    if [ $? -ne 0 ]; then
        echo "错误: 无法创建目标文件夹: $TARGET_DIR" >&2
        exit 1
    fi
fi

# 执行rsync同步
# -a: 归档模式，保持文件属性
# -u: 只更新修改时间较新的文件（增量同步）
# --delete: 删除目标目录中源目录没有的文件
# --exclude: 排除.git文件夹
# -q: 静默模式，不输出详细信息
rsync -aqu \
    --delete \
    --exclude='.git/' \
    --exclude='.git' \
    "$SOURCE_DIR/" "$TARGET_DIR/"

# 检查rsync执行结果
if [ $? -ne 0 ]; then
    echo "错误: 同步过程中出现错误" >&2
    exit 1
fi
