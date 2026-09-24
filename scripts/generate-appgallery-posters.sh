#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
poster_dir="$project_dir/release/appgallery/posters"
output_dir="$project_dir/release/appgallery/screenshots"
background="$poster_dir/source/brand-background.png"
app_icon="$project_dir/release/appgallery/app-icon-216.png"
font_file="/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/previewer/common/bin/fonts/HarmonyOS_Sans_SC.ttf"

raw_files=(
  "01-request-response.jpeg"
  "02-json-body.jpeg"
  "03-environments.jpeg"
  "04-history.jpeg"
  "05-settings.jpeg"
)

output_files=(
  "01-request-response.png"
  "02-collections.png"
  "03-environments.png"
  "04-history.png"
  "05-settings.png"
)

titles=(
  "发送请求，看见每一处细节"
  "像写代码一样编辑请求"
  "环境变量，切换自如"
  "历史请求，随时回溯"
  "轻量设置，专注工作"
)

subtitles=(
  "参数、状态、耗时与 JSON 响应，一屏完成"
  "原生 JSON 高亮、智能补全与流畅编辑体验"
  "开发、预发布、生产环境清晰分离"
  "状态、耗时与请求地址一目了然"
  "语言、主题、网络与数据偏好集中管理"
)

mkdir -p "$output_dir"

for index in "${!raw_files[@]}"; do
  ffmpeg -hide_banner -loglevel error -y \
    -i "$background" \
    -i "$poster_dir/raw/${raw_files[$index]}" \
    -i "$app_icon" \
    -filter_complex "
      [0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080[background];
      [1:v]crop=3120:1755:0:0,scale=1504:846:flags=lanczos[interface];
      [2:v]scale=64:64:flags=lanczos[logo];
      [background]drawbox=x=190:y=216:w=1540:h=882:color=0x27346A@0.12:t=fill,
        drawbox=x=196:y=222:w=1528:h=870:color=0xFFFFFF@0.72:t=fill[card];
      [card][interface]overlay=208:234[with_interface];
      [with_interface][logo]overlay=208:66[with_logo];
      [with_logo]drawtext=fontfile='$font_file':text='${titles[$index]}':x=292:y=57:
        fontsize=50:fontcolor=0x182039,
        drawtext=fontfile='$font_file':text='${subtitles[$index]}':x=292:y=126:
        fontsize=25:fontcolor=0x58617A[out]
    " \
    -map "[out]" \
    -frames:v 1 \
    -c:v png \
    -pred mixed \
    "$output_dir/${output_files[$index]}"
done

