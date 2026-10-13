# ============================================================
#  Makefile —— 《信息隐藏技术实验报告》完整编译流水线（XeLaTeX）
#
#  流水线：
#     ① xelatex            生成 .aux / .bcf / .idx / .glo 等控制文件
#     ② biber 或 bibtex    处理参考文献（按 .bcf / .aux 自动识别）
#     ③ makeindex / makeglossaries  处理索引与术语表（可选）
#     ④ xelatex × N        反复编译，直到 .log 中不再出现
#                          "Rerun / Please (re)run / undefined references"
#                          等提示（N 自动判断，上限 MAXPASSES，默认 5）
#
#  常用命令：
#     make                完整编译，生成 lab_report(zh_cn).pdf
#     make quick          只跑一遍 XeLaTeX（快速查语法错误，不处理文献）
#     make rebuild        先 distclean 再完整编译（忽略时间戳强制重编）
#     make latexmk        交给 latexmk -xelatex 全自动编排（含 biber、重跑判断）
#     make bib            单独跑文献后端（自动识别 biber / bibtex）
#     make index          单独跑索引（自动识别 makeindex / makeglossaries）
#     make view           打开生成的 PDF
#     make clean          清理中间产物（保留 PDF）
#     make distclean      清理中间产物并删除 PDF
#     make help           显示帮助
#
#  可覆盖变量：
#     MAIN=xxx                主文件名（不含 .tex），默认 lab_report(zh_cn)
#     BIBLIO=biber|bibtex|none 文献后端，默认 auto（自动识别）
#     IDX=makeindex|makeglossaries|none  索引工具，默认 auto
#     MAXPASSES=5             xelatex 最多编译几遍
#     V=1                     显示 XeLaTeX 原始输出（默认只显示进度与错误）
#     SHELL_ESCAPE=1          加 -shell-escape（minted 等需要调用外部程序的宏包）
#
#  例：
#     make                        # 平时就用这个
#     make BIBLIO=bibtex          # 强制走 bibtex（传统 \bibliography）
#     make V=1                    # 排查问题时看引擎完整输出
#     make MAXPASSES=8            # 交叉引用特别多时放宽上限
# ============================================================

# ---------------- 基本配置 ----------------
MAIN      ?= lab_report(zh_cn)
TEX       := $(MAIN).tex
PDF       := $(MAIN).pdf
AUX       := $(MAIN).aux
BCF       := $(MAIN).bcf
# 引擎原始输出文件（安静模式下 XeLaTeX 的 stdout/stderr 落到这里，*.log 已被 .gitignore 忽略）
ENGLOG    := $(MAIN).make.log

XELATEX        ?= xelatex
BIBER          ?= biber
BIBTEX         ?= bibtex
MAKEINDEX      ?= makeindex
MAKEGLOSSARIES ?= makeglossaries
LATEXMK        ?= latexmk

BIBLIO       ?= auto
IDX          ?= auto
MAXPASSES    ?= 5
SHELL_ESCAPE ?= 0
V            ?= 0

# -interaction=nonstopmode : 出错不中断，便于一次性看完日志
# -file-line-error         : 报错形如 file.tex:58: ...，便于定位
# -synctex=1               : 支持编辑器的正反向跳转
FLAGS := -interaction=nonstopmode -file-line-error -synctex=1
ifeq ($(SHELL_ESCAPE),1)
FLAGS += -shell-escape
endif

# 日志中出现这些提示，说明还需要再跑一遍 xelatex
RERUN_PAT = Rerun to get|Label\(s\) may have changed|Please \(re\)run|Please rerun|undefined references|Citation .* undefined|Table widths have changed|Package rerunfilecheck Warning

# ---------------- 依赖与中间产物 ----------------
DEPS := $(TEX) \
        $(wildcard *.cls) $(wildcard *.sty) \
        $(wildcard *.bib) $(wildcard refs/*.bib) \
        $(wildcard imgs/*) $(wildcard figures/*)

AUXEXT := aux log out toc lof lot \
          nav snm vrb idx ind ilg glo gls glg ist \
          bbl blg bcf run.xml sbb \
          acn acr alg nlo nls nlg \
          fls fdb_latexmk synctex synctex.gz xdv dvi \
          spl brf loa soc xwm thm maf mtc mtc0 ptc \
          upa upb auxlock bibtoolrsc pdfsync comment.cut \
          make.log

# ============================================================
#  对外目标
# ============================================================
.PHONY: all pdf quick once rebuild latexmk xelatex bib index view clean distclean help
.PHONY: _pipeline _xelatex _bib _index

all: $(PDF)
pdf: $(PDF)
once: quick

# ---------------- 主目标 ----------------
$(PDF): $(DEPS)
	@echo ">>> 目标 $(PDF)（引擎 $(XELATEX)，文献 $(BIBLIO)，索引 $(IDX)）"
	@$(MAKE) --no-print-directory _pipeline
	@test -f "$(PDF)" || { echo "!! 未生成 $(PDF)，请检查 $(MAIN).log"; exit 1; }
	@tail -n 60 "$(MAIN).log" 2>/dev/null | grep -E 'Output written on' | tail -n 1 | sed 's/^ */>>> /' || true

# ---------------- 完整流水线（内部）----------------
_pipeline:
	@echo ">>> ① 第 1 遍 XeLaTeX：生成控制文件"
	@$(MAKE) --no-print-directory _xelatex
	@$(MAKE) --no-print-directory _bib
	@$(MAKE) --no-print-directory _index
	@echo ">>> ④ 迭代编译，直到引用/目录/文献稳定"
	@pass=1; stable=0; \
	while : ; do \
		if ! grep -qE '$(RERUN_PAT)' "$(MAIN).log" 2>/dev/null; then stable=1; break; fi; \
		if [ $$pass -ge $(MAXPASSES) ]; then break; fi; \
		pass=$$((pass+1)); \
		echo ">>> 第 $$pass 遍 XeLaTeX（日志中仍有重跑提示）"; \
		$(MAKE) --no-print-directory _xelatex || exit 1; \
	done; \
	if [ $$stable -eq 1 ]; then \
		echo ">>> 引用已稳定，共执行 $$pass 遍 XeLaTeX"; \
	else \
		echo ">>> 警告：已达 MAXPASSES=$(MAXPASSES)，日志中仍存在重跑提示，请检查 $(MAIN).log"; \
	fi

# ---------------- 单遍 XeLaTeX（内部，供上面复用）----------------
_xelatex:
	@if [ "$(V)" = "1" ]; then \
		$(XELATEX) $(FLAGS) "$(TEX)" || { echo "!! XeLaTeX 出错，详见 $(MAIN).log"; exit 1; }; \
	else \
		$(XELATEX) $(FLAGS) "$(TEX)" > "$(ENGLOG)" 2>&1 || { \
			echo "!! XeLaTeX 出错（格式：文件:行号: 错误信息）"; \
			grep -E ':[0-9]+:|^! |Package .*Error|LaTeX Error|Emergency stop' "$(ENGLOG)" \
				| awk '!seen[$$0]++' | head -n 15; \
			echo "!! 完整日志：$(MAIN).log    引擎原始输出：$(ENGLOG)"; \
			exit 1; }; \
	fi

# ---------------- 文献后端（内部）----------------
# auto 判定顺序：有 .bcf → biber（biblatex）；.aux 里有 \bibdata → bibtex（传统）
_bib:
	@b="$(BIBLIO)"; forced=1; \
	if [ "$$b" = "auto" ]; then \
		forced=0; \
		if [ -f "$(BCF)" ]; then b=biber; \
		elif grep -qs 'bibdata' "$(AUX)" 2>/dev/null; then b=bibtex; \
		else b=skip; fi; \
	fi; \
	case "$$b" in \
		biber)  echo ">>> ② biber $(MAIN)（biblatex 后端）"; $(BIBER) "$(MAIN)";; \
		bibtex) echo ">>> ② bibtex $(MAIN)（传统 bibtex 后端）"; $(BIBTEX) "$(MAIN)";; \
		*) if [ $$forced -eq 1 ]; then \
			echo ">>> ② 按 BIBLIO=$(BIBLIO) 跳过文献处理"; \
		else \
			echo ">>> ② 未检测到参考文献文件，跳过（可用 BIBLIO=biber|bibtex 强制）"; \
		fi;; \
	esac

# ---------------- 索引 / 术语表（内部）----------------
# auto 判定顺序：有 .glo → makeglossaries；有 .idx → makeindex
_index:
	@i="$(IDX)"; forced=1; \
	if [ "$$i" = "auto" ]; then \
		forced=0; \
		if [ -f "$(MAIN).glo" ]; then i=makeglossaries; \
		elif [ -f "$(MAIN).idx" ]; then i=makeindex; \
		else i=skip; fi; \
	fi; \
	case "$$i" in \
		makeglossaries) echo ">>> ③ makeglossaries $(MAIN)"; $(MAKEGLOSSARIES) "$(MAIN)";; \
		makeindex)      echo ">>> ③ makeindex $(MAIN).idx"; $(MAKEINDEX) "$(MAIN).idx" -o "$(MAIN).ind";; \
		*) if [ $$forced -eq 1 ]; then \
			echo ">>> ③ 按 IDX=$(IDX) 跳过索引/术语表"; \
		else \
			echo ">>> ③ 未检测到索引/术语表，跳过"; \
		fi;; \
	esac

# ---------------- 单遍 / 快速检查 ----------------
xelatex:
	@echo ">>> 单遍 XeLaTeX（快速查语法错误，不处理文献与索引）"
	@$(MAKE) --no-print-directory _xelatex

quick: xelatex

# ---------------- 单独跑某一阶段 ----------------
bib: _bib
index: _index

# ---------------- latexmk 全自动编排 ----------------
latexmk:
	@echo ">>> latexmk -xelatex（自动处理 biber/bibtex 与重跑次数）"
	$(LATEXMK) -xelatex -synctex=1 -interaction=nonstopmode -file-line-error "$(TEX)"

# ---------------- 强制重编 ----------------
rebuild:
	@$(MAKE) --no-print-directory distclean
	@$(MAKE) --no-print-directory all

# ---------------- 预览 ----------------
view: $(PDF)
	@if command -v open >/dev/null 2>&1; then open "$(PDF)"; \
	elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$(PDF)"; \
	else echo "请手动打开 $(PDF)"; fi

# ---------------- 清理 ----------------
clean:
	@echo ">>> 清理编译中间产物"
	@rm -f $(addprefix $(MAIN).,$(AUXEXT))
	@rm -f "$(MAIN).synctex(busy)" "$(MAIN).synctex.gz(busy)"
	@rm -f *.aux *.log *.out *.toc *.lof *.lot *.nav *.snm *.vrb \
	       *.idx *.ind *.ilg *.glo *.gls *.glg *.bbl *.blg *.bcf *.run.xml \
	       *.fls *.fdb_latexmk *.synctex *.synctex.gz *.xdv *.dvi
	@rm -rf latex.out auto .texpadtmp
	@echo ">>> 完成"

distclean: clean
	@echo ">>> 删除生成的 PDF"
	@rm -f "$(PDF)"

# ---------------- 帮助 ----------------
help:
	@echo "编译流水线：xelatex → biber/bibtex → makeindex/makeglossaries → xelatex × N"
	@echo ""
	@echo "  make                完整编译（自动判断遍数，上限 MAXPASSES=$(MAXPASSES)）"
	@echo "  make quick          单遍 XeLaTeX，快速查语法错误"
	@echo "  make rebuild        强制从头完整编译"
	@echo "  make latexmk        用 latexmk -xelatex 全自动编排"
	@echo "  make bib            只跑文献后端（biber / bibtex）"
	@echo "  make index          只跑索引（makeindex / makeglossaries）"
	@echo "  make view           打开生成的 PDF"
	@echo "  make clean          清理中间产物（保留 PDF）"
	@echo "  make distclean      清理中间产物并删除 PDF"
	@echo "  make help           显示本帮助"
	@echo ""
	@echo "  MAIN=$(MAIN)  BIBLIO=$(BIBLIO)  IDX=$(IDX)  V=$(V)  SHELL_ESCAPE=$(SHELL_ESCAPE)"
