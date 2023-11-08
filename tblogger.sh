#!/bin/bash
# 赋予脚本执行权限
# chmod +x tblogger.sh
# ./tblogger.sh

DESTINATION_DIR="./tb_logger"

mkdir -p "$DESTINATION_DIR"

# 在当前脚本目录下的experiments文件夹中查找所有名为tb_logger的文件夹
find experiments -type d -name tb_logger | while read -r tb_logger_dir; do
  # 获取tb_logger的完整路径
  full_path=$(realpath "$tb_logger_dir")
  # 获取路径的部分
  IFS='/' read -ra ADDR <<< "$full_path"
  for i in "${!ADDR[@]}"; do
    if [[ ${ADDR[i]} =~ ^(Done|Doing)$ ]]; then
      status=${ADDR[i]} # Done 或 Doing
      if [[ ${ADDR[i]} == "Done" ]]; then
        category=${ADDR[i+1]} # Classical
        resolution=${ADDR[i+2]} # X2, X3, etc.
        exp_number=${ADDR[i+3]} # 001_SwinIR_..., 002_SwinIR_..., etc.
      else
        category="Doing" # 没有额外分类的情况，直接使用Doing
        resolution=""    # Doing下没有分类
        exp_number=${ADDR[i+1]} # 001_SwinIR_..., 002_SwinIR_..., etc.
      fi

      # 提取实验编号
      if [[ $exp_number =~ ^([0-9]+)_ ]]; then
        link_number="${BASH_REMATCH[1]}"

        # 构建目标链接目录和链接名
        target_link_dir="$DESTINATION_DIR/$category/${resolution:+$resolution/}"
        link_name="${link_number}"

        # 创建目标链接目录
        mkdir -p "$target_link_dir"

        # 找到tb_logger下的唯一子目录
        unique_subdir=$(find "$tb_logger_dir" -mindepth 1 -maxdepth 1 -type d)

        # 获取子目录的真实路径
        unique_subdir_path=$(realpath "$unique_subdir")

        # 创建符号链接
        ln -sfn "$unique_subdir_path" "$target_link_dir/$link_name"
        echo "Linked $unique_subdir_path to $target_link_dir/$link_name"
        echo
      else
        echo "The directory $exp_number does not start with a number sequence. Skipping..."
        echo
      fi

      # 只处理一次匹配
      break
    fi
  done
done

echo "All tb_logger unique subdirectories have been linked within the appropriate category and resolution directories in $DESTINATION_DIR."
