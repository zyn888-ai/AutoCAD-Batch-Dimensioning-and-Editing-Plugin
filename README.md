# SmartRoad CAD Dimension Tools

> **AutoCAD 2019–2022 道路工程批量尺寸标注插件**
> 面向道路工程 CAD 图纸批量处理场景，实现图框动态识别、Excel 数据匹配、道路几何分析、标注习惯学习、尺寸自动生成、执行前预检与 DWG 强制备份。

![Version](https://img.shields.io/badge/version-v1.3.1-blue)
![AutoCAD](https://img.shields.io/badge/AutoCAD-2019--2022-red)
![Platform](https://img.shields.io/badge/platform-Windows%2064--bit-lightgrey)

**Version:** `v1.3.1`
**Platform:** Windows 64-bit
**AutoCAD:** 2019 / 2020 / 2021 / 2022

---

## 项目简介

SmartRoad CAD Dimension Tools 是一款基于 AutoCAD .NET 接口开发的道路工程 CAD 批量尺寸标注插件。

插件针对道路工程图纸中大量重复的道路长度、宽度标注工作，通过读取 Excel 道路数据，并分析当前 DWG 中的图框、道路名称、图号及道路几何信息，实现道路尺寸数据的自动匹配和批量标注。

v1.3.1 主要支持：

* DWG 图框数量动态识别
* Excel 道路数据自动匹配
* 道路名称唯一匹配
* `JT-1-xx` 图号辅助校验
* CAD 道路几何自动定位
* 标注习惯学习
* 跨 DWG 标注模板复用
* 执行前完整性预检
* DWG 强制备份
* AutoCAD 多版本运行时自动适配
* “未知命令”自动修复

整体工作流程：

```text
Excel 道路数据
      ↓
DWG 图框识别
      ↓
道路名称匹配
      ↓
图号辅助校验
      ↓
CAD 几何定位
      ↓
标注习惯学习
      ↓
完整性预检
      ↓
DWG 自动备份
      ↓
批量尺寸标注
```

---

# 核心功能

## 1. DWG 图框动态识别

插件不会固定假设当前 DWG 中存在 260 张图纸。

程序会自动识别当前 DWG 中的有效图框数量。

例如：

```text
当前 DWG 图框：5
Excel 道路数据：768
成功匹配：5 / 5
```

当前文件中存在多少张有效图框，插件就处理多少张。

例如：

```text
5 张
20 张
120 张
260 张
```

均可根据实际 DWG 内容动态处理。

---

## 2. Excel 道路数据自动匹配

插件支持读取：

```text
.xlsx
.xls
```

格式的道路信息表。

Excel 不需要提前打开，也不需要复制到 CAD 中。

插件采用：

```text
道路名称匹配
      ↓
JT-1-xx 图号辅助校验
      ↓
唯一性验证
```

完成道路数据匹配。

因此，即使 Excel 中存在远多于当前 DWG 的道路数据，程序也只会提取与当前图纸对应的数据。

---

## 3. CAD 道路几何自动识别

插件不是简单将 Excel 数据写入 CAD。

程序会首先分析道路几何结构，再确定尺寸标注锚点。

### 长度标注

自动识别道路左右端对应边界，并生成道路长度尺寸。

### 宽度标注

根据道路上下边线以及学习到的标注位置，生成道路宽度尺寸。

基本逻辑：

```text
CAD 几何
   │
   ├── 决定尺寸锚点
   ├── 决定尺寸线位置
   └── 决定标注方向

Excel 数据
   │
   ├── 道路名称
   ├── 道路长度
   └── 道路宽度
```

即：

> **标注位置来自 CAD，工程数据来自 Excel。**

---

# 标注习惯学习

SmartRoad v1.3.1 支持从已有正确尺寸中学习当前项目的标注习惯。

建议在 DWG 前 **2～5 张图** 中保留人工完成的正确尺寸标注。

插件可学习：

* 长度标注位置
* 宽度标注位置
* 尺寸线偏移
* 标注文字位置
* 宽度锚点比例
* Dimension Style
* 标注图层
* 当前项目尺寸布局

---

## 自动学习

执行：

```text
ZHDIMAUTOEXCELCHECK
```

时，如果当前 DWG 中存在完整标注样本，插件会自动进行分析。

推荐样本：

```text
2～5 张图

每张至少包含：

1 条正确道路长度标注
+
1 条正确道路宽度标注
```

---

## 手动学习

执行：

```text
ZHDIMLEARN
```

依次选择：

```text
正确的长度尺寸
+
正确的宽度尺寸
```

即可保存当前项目的标注模板。

---

## 查看学习模板

执行：

```text
ZHDIMPROFILE
```

可查看：

* 模板来源
* 保存时间
* 标注样式
* 标注图层
* 锚点比例
* 相关学习参数

学习模板默认保存于：

```text
%LOCALAPPDATA%\SEU-NiZongyu\SmartRoad\annotation-profile.json
```

因此可以在不同 DWG 文件之间复用。

---

# 推荐使用流程

建议始终按照：

```text
预检
 ↓
确认
 ↓
正式执行
```

的方式使用。

---

## Step 1：打开 DWG

打开需要批量处理的道路工程 DWG 文件。

建议先保存当前图纸。

---

## Step 2：执行预检

在 AutoCAD 命令行输入：

```text
ZHDIMAUTOEXCELCHECK
```

随后选择对应的 Excel 数据文件。

程序会检查：

```text
DWG 图框数量
Excel 候选数据数量
道路名称匹配情况
图号校验情况
CAD 几何定位情况
标注学习样本数量
```

推荐确认：

```text
道路匹配：N / N
几何定位：N / N
```

全部通过。

### 预检模式不会：

* 修改 DWG
* 新建尺寸
* 删除对象
* 修改现有标注
* 执行正式写入

因此可以安全重复运行。

---

## Step 3：正式执行

预检通过后输入：

```text
ZHDIMAUTOEXCEL
```

重新选择对应 Excel。

确认检查结果无误后输入：

```text
Y
```

开始正式批量标注。

---

# Excel 数据格式

推荐 Excel 表格结构：

| 列 | 字段      | 示例     |
| - | ------- | ------ |
| A | 序号      | 1      |
| B | 道路名称    | XX路    |
| C | 起点地址    | XX大道   |
| D | 止点地址    | XX路    |
| E | 车行道长(m) | 286.50 |
| F | 车行道宽(m) | 12.00  |

核心字段：

```text
道路名称
车行道长度
车行道宽度
```

如果宽度填写为：

```text
/
```

则对应 CAD 标注可以显示：

```text
/
```

Excel 文件仅用于读取数据。

插件不会修改原 Excel 文件。

---

# 安全机制

## DWG 强制备份

正式修改 DWG 之前，插件必须先成功创建备份。

备份目录：

```text
原 DWG 文件夹
└── SmartRoad_Backups
    └── 原图名_before_ZHDIM_时间戳.dwg
```

例如：

```text
道路施工图.dwg

↓

SmartRoad_Backups/
└── 道路施工图_before_ZHDIM_20260901_153012_125.dwg
```

如果备份失败：

> **插件立即终止，不会开始修改 DWG。**

---

## 完整匹配保护

如果出现：

```text
道路漏匹配
道路重复匹配
CAD 几何识别失败
图框识别异常
```

程序会阻止正式执行。

例如：

```text
识别图框：120
成功匹配：119 / 120
```

建议先检查对应图框中的：

```text
道路名称
JT-1-xx 图号
道路边线
图框结构
```

不要强制执行。

---

## AutoCAD 事务保护

批量修改通过 AutoCAD 事务机制执行。

执行完成后，可使用：

```text
UNDO
```

撤销相关操作。

---

# 支持版本

| AutoCAD             | Runtime | 支持 |
| ------------------- | ------- | -- |
| AutoCAD 2019 64-bit | R23     | ✅  |
| AutoCAD 2020 64-bit | R23     | ✅  |
| AutoCAD 2021 64-bit | R24     | ✅  |
| AutoCAD 2022 64-bit | R24     | ✅  |
| AutoCAD LT          | -       | ❌  |

> AutoCAD LT 不支持本插件所需的完整 .NET 插件接口。

---

# 项目结构

```text
SmartRoad-CAD-Dimension-Tools-v1.3.1/
│
├── src/
│   │
│   ├── Install-SmartRoad.ps1
│   ├── Repair-CommandRegistration.ps1
│   │
│   └── SmartRoad.CadDimensionTools.bundle/
│       │
│       ├── PackageContents.xml
│       │
│       └── Contents/
│           │
│           ├── Data/
│           │   └── traffic_1_260.json
│           │
│           └── Windows/
│               │
│               ├── R23/
│               │   └── SmartRoad.CadDimensionTools.R23.v1.3.1.dll
│               │
│               └── R24/
│                   └── SmartRoad.CadDimensionTools.R24.v1.3.1.dll
│
├── assets/
├── docs/
├── requirements.txt
├── main.py
├── README.md
├── LICENSE
├── .gitignore
├── 安装前检测CAD版本.bat
├── 一键安装插件.bat
└── 修复未知命令.bat
```

---

# 安装方法

## 1. 下载项目

点击 GitHub 页面右上方：

```text
Code
 ↓
Download ZIP
```

下载项目。

---

## 2. 完整解压

将 ZIP 完整解压到本地目录。

例如：

```text
D:\SmartRoad-CAD-Dimension-Tools\
```

不要直接在压缩包预览界面中运行安装程序。

---

## 3. 关闭 AutoCAD

安装前请：

1. 保存所有 DWG；
2. 关闭全部 AutoCAD 窗口；
3. 确认后台没有 AutoCAD 进程。

---

## 4. 检测 CAD 版本

双击：

```text
安装前检测CAD版本.bat
```

程序会自动检测当前电脑上安装的 AutoCAD。

该操作：

> **只检测，不安装。**

---

## 5. 一键安装

双击：

```text
一键安装插件.bat
```

如果 Windows 弹出管理员权限请求，请选择：

```text
是
```

安装程序会自动：

```text
检测 AutoCAD
      ↓
读取 AcadLocation
      ↓
判断 R23 / R24
      ↓
复制插件
      ↓
写入加载配置
      ↓
注册 ZHDIM 命令
      ↓
校验 DLL
      ↓
生成安装日志
```

---

# 插件安装位置

安装程序通过 Autodesk 注册表读取：

```text
AcadLocation
```

因此不是固定安装到 C 盘。

插件通常安装于：

```text
<AutoCAD安装目录>\
└── SmartRoadPlugins\
    └── SmartRoad.CadDimensionTools\
```

例如：

```text
D:\Autodesk\AutoCAD 2022\
```

则插件会安装至对应 AutoCAD 目录。

---

# 验证安装

安装完成后：

1. 完全关闭 AutoCAD；
2. 重新启动 AutoCAD；
3. 输入：

```text
ZHDIMHELP
```

如果能够正常显示 SmartRoad 命令列表，则插件加载成功。

也可以输入：

```text
ZHDIMABOUT
```

查看插件版本和运行信息。

---

# 主要命令

## 批量标注

| 命令                    | 功能           |
| --------------------- | ------------ |
| `ZHDIMAUTOEXCELCHECK` | Excel 批量标注预检 |
| `ZHDIMAUTOEXCEL`      | Excel 批量自动标注 |
| `ZHDIMAUTO260CHECK`   | 内置道路数据预检     |
| `ZHDIMAUTO260`        | 使用内置道路数据执行标注 |

推荐使用：

```text
ZHDIMAUTOEXCELCHECK
        ↓
ZHDIMAUTOEXCEL
```

---

## 学习与分析

| 命令                | 功能           |
| ----------------- | ------------ |
| `ZHDIMLEARN`      | 学习正确尺寸标注     |
| `ZHDIMPROFILE`    | 查看标注学习模板     |
| `ZHDIMANALYZE`    | 分析 CAD 图形    |
| `ZHDIMOLEINSPECT` | OLE / 表格对象检查 |

---

## 尺寸命令

| 命令              | 功能   |
| --------------- | ---- |
| `ZHDIMALIGNED`  | 对齐尺寸 |
| `ZHDIMLINE`     | 线性尺寸 |
| `ZHDIMANGULAR`  | 角度尺寸 |
| `ZHDIMRADIUS`   | 半径尺寸 |
| `ZHDIMDIAMETER` | 直径尺寸 |

---

## 辅助命令

| 命令            | 功能        |
| ------------- | --------- |
| `ZHDIMSTYLE`  | 标注样式功能    |
| `ZHDIMTEXT`   | 标注文本功能    |
| `ZHDIMJSON`   | JSON 数据功能 |
| `ZHDIMBACKUP` | 创建 DWG 备份 |
| `ZHDIMHELP`   | 查看插件命令    |
| `ZHDIMABOUT`  | 查看插件信息    |

---

# R23 / R24 双运行时

为了兼容多个 AutoCAD 版本，插件包含两套 DLL。

## R23

适用于：

```text
AutoCAD 2019
AutoCAD 2020
```

DLL：

```text
src/
└── SmartRoad.CadDimensionTools.bundle/
    └── Contents/
        └── Windows/
            └── R23/
                └── SmartRoad.CadDimensionTools.R23.v1.3.1.dll
```

---

## R24

适用于：

```text
AutoCAD 2021
AutoCAD 2022
```

DLL：

```text
src/
└── SmartRoad.CadDimensionTools.bundle/
    └── Contents/
        └── Windows/
            └── R24/
                └── SmartRoad.CadDimensionTools.R24.v1.3.1.dll
```

安装程序会自动识别 AutoCAD 版本，并加载对应运行时。

---

# 手动 NETLOAD

如果插件没有自动加载，可以使用 AutoCAD：

```text
NETLOAD
```

手动测试 DLL。

## AutoCAD 2019 / 2020

选择：

```text
src\SmartRoad.CadDimensionTools.bundle\
Contents\Windows\R23\
SmartRoad.CadDimensionTools.R23.v1.3.1.dll
```

## AutoCAD 2021 / 2022

选择：

```text
src\SmartRoad.CadDimensionTools.bundle\
Contents\Windows\R24\
SmartRoad.CadDimensionTools.R24.v1.3.1.dll
```

加载完成后输入：

```text
ZHDIMHELP
```

如果命令能够运行，说明核心 DLL 正常。

---

# “未知命令”修复

如果安装完成后输入：

```text
ZHDIMHELP
```

提示：

```text
未知命令
```

请先完全退出 AutoCAD。

然后运行：

```text
修复未知命令.bat
```

完成后重新启动 AutoCAD。

如果仍然无法识别，可以在 AutoCAD 中输入：

```text
DEMANDLOAD
```

设置为：

```text
3
```

重新启动 AutoCAD 后再次尝试。

---

# 安装日志

安装结果：

```text
src\Install-Result.txt
```

修复结果：

```text
src\Repair-Result.txt
```

安装日志会记录：

```text
Plugin Version
PowerShell Version
AutoCAD Version
DLL Location
Registration Status
Verification Result
```

---

# 常见问题

## 安装后提示未知命令

推荐顺序：

```text
1. 完全关闭 AutoCAD
2. 重新运行 一键安装插件.bat
3. 重启 AutoCAD
4. 输入 ZHDIMHELP
```

如果仍失败：

```text
修复未知命令.bat
```

还可以通过：

```text
NETLOAD
```

手动验证 DLL。

---

## 道路匹配不是 N/N

例如：

```text
当前图框：120
成功匹配：119 / 120
```

不要正式执行。

检查：

```text
道路名称
JT-1-xx 图号
Excel 道路名称
Excel 序号
```

---

## 几何定位不是 N/N

例如：

```text
道路匹配：120 / 120
几何定位：118 / 120
```

说明 Excel 数据已经匹配，但部分道路 CAD 几何无法正常识别。

建议检查：

```text
道路上下边线
道路左右边界
图框结构
异常断线
异常多段线
与标准图纸的版式差异
```

---

## Excel 数据比 DWG 图框多

正常。

例如：

```text
DWG：5 张
Excel：768 条
```

程序只提取与当前 5 张图匹配的数据。

---

## 插件会修改 Excel 吗？

不会。

Excel 仅作为数据输入源读取。

---

## 插件会删除原 DWG 吗？

不会。

正式执行前还会自动创建：

```text
SmartRoad_Backups
```

备份目录。

---

# 文件完整性校验

仓库提供：

```text
main.py
```

用于辅助检查插件发行文件。

> Python 不是插件运行依赖。

即使电脑没有安装 Python，也不影响 AutoCAD 插件正常安装和使用。

如果已安装 Python，可以运行：

```bash
python main.py verify
```

检查核心文件完整性。

也可以运行：

```bash
python main.py check
```

检查环境。

Windows 环境下还可以使用：

```bash
python main.py install
```

启动安装程序。

或：

```bash
python main.py repair
```

启动命令注册修复。

---

# v1.3.1 更新内容

### DWG 图框数量动态识别

取消固定 260 图限制。

当前 DWG 中有多少有效图框，就处理多少图框。

---

### Excel 大数据自动筛选

支持 Excel 中包含远多于当前 DWG 的道路数据。

插件只读取当前图纸实际需要的数据。

---

### 道路名称唯一匹配

基于道路名称完成数据定位，降低按图框顺序错误套用数据的风险。

---

### 图号辅助校验

支持结合：

```text
JT-1-xx
```

图号对道路数据进行辅助校验。

---

### 标注习惯学习

支持学习：

```text
尺寸锚点
尺寸线位置
文字位置
Dimension Style
标注图层
宽度比例
```

---

### 跨 DWG 学习模板

学习结果可保存在用户本地目录，在其他 DWG 中复用。

---

### 强制修改前备份

任何正式写入前均创建 DWG 备份。

备份失败则终止操作。

---

### 完整预检

匹配或几何定位不完整时阻止正式执行。

---

### 安装器兼容增强

增强 PowerShell 安装脚本在不同 Windows 环境下的兼容性。

---

### AutoCAD 命令注册增强

安装时自动写入 SmartRoad 命令映射，并提供：

```text
修复未知命令.bat
```

用于独立修复。

---

# 技术架构

```text
┌──────────────────────────────┐
│          AutoCAD DWG         │
│ 图框 / 道路 / 图号 / 几何对象 │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│        SmartRoad Engine      │
│                              │
│ 图框动态识别                 │
│ 道路名称分析                 │
│ 图号辅助校验                 │
│ CAD 几何定位                 │
│ 标注习惯学习                 │
│ 标注参数计算                 │
│ 安全检查                     │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│        Matching Engine       │
│                              │
│ Excel 道路数据               │
│ 名称唯一匹配                 │
│ 图号辅助验证                 │
│ 完整性检查                   │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│        Backup & Verify       │
│                              │
│ DWG 强制备份                 │
│ N/N 完整性验证               │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│      Auto Dimensioning       │
│                              │
│ 道路长度标注                 │
│ 道路宽度标注                 │
│ 原标注更新                   │
│ 缺失尺寸创建                 │
└──────────────────────────────┘
```

---

# 技术环境

核心技术栈：

```text
C#
.NET Framework
Autodesk AutoCAD .NET API
AutoCAD Managed Assemblies
PowerShell
Windows Batch
JSON
```

运行环境：

```text
Windows 64-bit
+
AutoCAD 2019–2022 Full Version
```

Python 仅作为仓库辅助工具，不是插件核心运行依赖。

---

# 注意事项

使用插件前建议：

1. 使用 AutoCAD 2019–2022 64 位完整版；
2. AutoCAD LT 不支持；
3. 安装前关闭所有 AutoCAD；
4. 下载 ZIP 后必须完整解压；
5. 首次处理建议先执行预检；
6. 匹配不是 `N/N` 时不要正式执行；
7. 几何定位不是 `N/N` 时先检查 DWG；
8. 不要随意移动 `.bundle` 内部文件；
9. 不要改变 R23 / R24 DLL 目录结构；
10. 不要随意修改 `PackageContents.xml` 中的 DLL 路径。

---

# 文档

详细说明位于：

```text
docs/
```

可用于存放：

```text
使用说明
版本说明
测试报告
安装说明
故障排查
SHA-256 文件校验
```

---

# Assets

项目运行截图、CAD 标注结果、安装过程图片等建议放置于：

```text
assets/
```

推荐：

```text
assets/
├── preview.png
├── workflow.png
├── autocad-command.png
├── excel-import.png
├── check-result.png
├── before.png
└── after.png
```

后续可以直接在 README 中引用这些图片。

---

# License

项目授权与版权说明请参阅：

```text
LICENSE
```

使用、修改或分发本项目时，请遵守仓库中的授权条款。

---

# 当前版本

```text
SmartRoad CAD Dimension Tools
v1.3.1
```

支持：

```text
AutoCAD 2019
AutoCAD 2020
AutoCAD 2021
AutoCAD 2022
```

运行时：

```text
R23
R24
```

---

## SmartRoad CAD Dimension Tools

**让道路工程中重复性的 CAD 尺寸标注工作，从人工逐图处理转变为可识别、可检查、可学习、可备份、可批量执行的自动化流程。**

```text
Excel
  ↓
道路数据匹配
  ↓
DWG 图框识别
  ↓
道路几何分析
  ↓
标注习惯学习
  ↓
安全预检
  ↓
DWG 自动备份
  ↓
批量尺寸标注
```
