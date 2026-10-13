# WHU-Information-Hiding-Technology-Lab-Report-Template-LaTeX

武汉大学国家网络安全学院《信息隐藏技术》实验报告 LaTeX 模板。

模板基于 `ctexart` + XeLaTeX，自带封面页与实验报告章节骨架，并附代码、表格、图片、伪代码、
字体等示例章节，改完内容即可直接编译成 PDF。

> 模板内容与排版沿用原版，仅补充了 Makefile、`.gitignore`、README 等工程化文件。

## 特性

- **单文件源文件**：`lab_report(zh_cn).tex` 一个文件搞定封面与正文
- **中文排版开箱即用**：`ctex` / `xeCJK` / `fontspec`，XeLaTeX 直接编译
- **章节齐全**：实验名称、目的、原理、内容、环境、步骤、结果与分析、总结，另附各类示例
- **一键编译**：[Makefile](Makefile) 提供完整流水线 `xelatex → biber/bibtex → makeindex → xelatex × N`，
  自动判断需要编译几遍，不需要手敲 `xelatex` 反复跑
- **干净的仓库**：[.gitignore](.gitignore) 已忽略 macOS 系统文件与全部编译中间产物

## 环境要求

- TeX Live 2023 或更新（macOS 建议安装 MacTeX；Windows 可用 TeX Live / MiKTeX）
- 需要 `xelatex`，以及 `ctex`、`fontspec`、`xeCJK`、`algorithm`、`listings` 等宏包（完整版 TeX Live 均已包含）
- `make`（macOS 自带的 `/usr/bin/make` 即可）
- 可选：`biber` / `bibtex`（参考文献）、`makeindex` / `makeglossaries`（索引）、`latexmk`——本模板当前没有引用，
  这些阶段会自动跳过

## 快速开始

```bash
# SSH
git clone git@github.com:Frank-lab-hash/WHU-Information-Hiding-Technology-Lab-Report-Template-LaTeX.git

# 或 HTTPS
git clone https://github.com/Frank-lab-hash/WHU-Information-Hiding-Technology-Lab-Report-Template-LaTeX.git

cd WHU-Information-Hiding-Technology-Lab-Report-Template-LaTeX
make            # 编译，生成 lab_report(zh_cn).pdf
make view       # 用系统默认阅读器打开生成的 PDF
```

## 需要修改的地方

1. **封面**（`lab_report(zh_cn).tex` 第 180–186 行）：学号、姓名、实验名称、指导教师
2. **正文**（第 208 行起）：实验名称、实验目的、实验原理、实验内容、实验环境、实验步骤、实验结果与分析、总结
3. **插图**：图片放进 `imgs/` 目录，正文中用 `\includegraphics[width=\textwidth]{文件名}` 引用
   （导言区已设置 `\graphicspath{{imgs/}}`，不需要写路径）

## Makefile 命令

| 命令 | 作用 |
| --- | --- |
| `make` | 完整编译：`xelatex → biber/bibtex → makeindex → xelatex × N`，自动判断遍数 |
| `make quick` | 只跑一遍 XeLaTeX，快速查语法错误 |
| `make rebuild` | 先清理再完整重编（忽略时间戳） |
| `make latexmk` | 交给 `latexmk -xelatex` 全自动编排 |
| `make bib` / `make index` | 只跑文献后端 / 只跑索引 |
| `make view` | 打开生成的 PDF |
| `make clean` | 删除编译中间产物（保留 PDF） |
| `make distclean` | 删除编译中间产物与 PDF |
| `make help` | 显示帮助 |

可覆盖的变量：

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `MAIN` | `lab_report(zh_cn)` | 主文件名（不含 `.tex`） |
| `BIBLIO` | `auto` | 文献后端：`auto` / `biber` / `bibtex` / `none` |
| `IDX` | `auto` | 索引工具：`auto` / `makeindex` / `makeglossaries` / `none` |
| `MAXPASSES` | `5` | XeLaTeX 最多编译几遍 |
| `V` | `0` | `V=1` 显示引擎原始输出（默认只显示进度与错误摘要） |
| `SHELL_ESCAPE` | `0` | `SHELL_ESCAPE=1` 加 `-shell-escape`（使用 minted 等宏包时） |

例如改了主文件名：

```bash
make MAIN=my_report
```

## 字体

模板沿用原版的字体设置，使用的是一组 Windows / Office 字体：`Times New Roman`、`Consolas`、`宋体`、
`黑体`、`楷体`、`仿宋`、`微软雅黑`、`SimSun`、`SimHei`、`KaiTi`、`STXingkai`，定义在
`lab_report(zh_cn).tex` 第 56–72 行。在装有 Office 的 Windows 上一般可直接编译。

若你所处的环境缺少这些字体（例如 macOS），`xelatex` 会报
`Package fontspec Error: The font "xxx" cannot be found.`。模板保持原样不做改动，
具体怎么处理（安装对应字体，或按自己的排版需要改写这几行字体设置）由使用者自行决定；
定位问题时可以用 `make V=1` 查看引擎的完整输出。

## 项目结构

```
.
├── lab_report(zh_cn).tex   # 报告源文件（封面 + 正文，唯一需要改的文件）
├── imgs/
│   └── logo.png            # 图片素材（“图片示例”章节引用）
├── Makefile                # 编译流水线
├── .gitignore              # 忽略 macOS 系统文件与 LaTeX 编译产物
├── LICENSE                 # MIT 许可证
└── README.md               # 本文件
```

## 常见问题

**编译报 `Package fontspec Error: The font "xxx" cannot be found`**
环境缺少模板所需的字体，属于使用环境问题，处理方式见上文「字体」一节（模板本身不做改动）。
定位问题时可以先用 `make V=1` 查看引擎的完整输出。

**`make` 说 `Nothing to be done for 'all'`**
源文件没有改动、生成的 PDF 比源文件新。想强制重编用 `make rebuild`，或 `make clean` 后再 `make`。

**正文里引用显示 `??`**
`make` 会读日志自动多编译几遍；如果一直不消失，说明标签或引用键写错了，检查 `.log`。

**改动没有生效 / 编译结果很旧**
先 `make distclean` 再 `make`。

**根目录的 PDF 会被提交吗？**
不会。`.gitignore` 忽略了根目录下的 PDF，`lab_report(zh_cn).pdf` 属于编译产物。
注意 `make distclean` 会删除它，需要保留时请自行备份。

**图片怎么插入？**
把图片放进 `imgs/`，然后：

```latex
\begin{figure}[!htbp]
  \centering
  \includegraphics[width=\textwidth]{图片文件名}
  \caption{图注}
\end{figure}
```

## 许可证

本项目基于 [MIT License](LICENSE) 发布。
