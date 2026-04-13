# ComfortCues v1.0.0 发布说明

发布日期：2026-04-14

`ComfortCues v1.0.0` 是项目的首个公开 Windows x64 发布版本。当前发布形态为便携式原生运行目录压缩包，解压后即可直接运行，无需安装。

## 版本概览

- 以原生 Qt/QML 实现作为当前主线运行版本
- 保留 Python 参考实现，便于行为对照、测试和后续维护
- 提供完整的构建、部署、冒烟验证与发布打包脚本
- 完成项目结构整理，文档、脚本、打包入口和构建入口已统一收口

## 本次包含内容

- 原生桌面应用主线
- `scripts/build_native.ps1` 原生构建链
- `scripts/deploy_native.ps1` 运行目录部署链
- `scripts/smoke_native_runtime.ps1` 自动状态级冒烟验证
- `scripts/make_release.ps1` 发布压缩包生成流程
- 项目结构说明与开发延续文档

## 发布包形式

- 平台：Windows x64
- 形式：portable zip
- 运行方式：解压后直接启动 `ComfortCues.exe`
- 安装器：当前版本不提供
- 单文件 exe：当前版本不提供

## 使用方式

1. 下载并解压发布包到可写目录。
2. 双击 `ComfortCues.exe` 启动程序。
3. 首次运行后程序默认可驻留系统托盘。
4. 如主窗口关闭，可通过托盘图标重新打开。

## 支持范围

- 支持窗口化与无边框窗口化 3D 游戏场景
- 当前不支持独占全屏
- 当前版本仍定位为外部辅助覆盖层，不进行注入、读写游戏内存或自动输入

## 验证结果

本次发布前已完成以下验证：

- `uv run pytest`
- `scripts\build_native.ps1 -Configuration Release`
- `scripts\deploy_native.ps1 -Configuration Release`
- `scripts\smoke_native_runtime.ps1 -Configuration Release`

自动冒烟验证已通过，主要覆盖首次运行状态、配置持久化、启用/禁用状态往返等核心状态链路。

## 已知说明

- 当前发布包不是单文件可执行程序，而是包含 Qt 运行时依赖的原生运行目录
- 若后续需要单文件 exe，仍需静态 Qt SDK 支持
- 用户运行状态保存在 `%APPDATA%\Comfort Cues\`

## 仓库与版本标记

- 仓库：`xqct0001/cut_3d_game`
- Git tag：`v1.0.0`

