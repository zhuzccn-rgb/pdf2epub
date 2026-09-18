# Folio · pdf2epub — Manning 风格技术书籍 PDF → EPUB 转换器

可用于Manning 排版风格(Verdana 正文 / Consolas 代码 / 灰底代码框)的 PDF 书籍。
本地运行,不上传任何文件。

## 项目状态与贡献

本项目处于原型阶段，针对特定技术书籍排版进行转换。项目构想由我提出，具体实现大量借助生成式 AI；仍需要更多样本验证。以下是现有代码覆盖的处理路径，不代表对任意 PDF 的准确性保证。

## 功能

- **去除页眉页脚冗余**:自动移除页码、`© Manning Publications Co. To comment go to liveBook`
  和 `Licensed to ... <邮箱>` 授权水印(版权页正文保留)
- **图文提取**:按页面块与排版规则组织图片和图注，尝试对图片去重；复杂布局仍需人工检查
- **代码块处理**:识别等宽字体 + 灰底区域，尝试保留缩进与对齐注释,
  输出 `<pre><code>`,长行自动软换行,适合手机阅读
- **结构化章节**:按 PDF 书签切分章节,生成三级嵌套导航目录(带页内锚点跳转)
- **智能排版**:H1–H4 标题、图注、侧边栏灰框、行内代码/斜体/粗体/上标,
  自动处理行尾断字与跨页段落合并
- **Web 界面**:大都会博物馆式沉静典雅设计,毛玻璃动效,拖拽上传、实时进度、一键下载

## 一键启动(推荐)

| 平台 | 命令 |
|---|---|
| Windows | 双击 `start.bat`,或 `powershell -ExecutionPolicy Bypass -File deploy.ps1` |
| macOS / Linux | `chmod +x deploy.sh && ./deploy.sh` |
| Docker | `docker build -t folio-pdf2epub . && docker run -p 5000:5000 folio-pdf2epub` |

脚本会自动:检测 Python → 创建虚拟环境 → 安装依赖 → 启动服务 → 打开浏览器。
然后访问 <http://127.0.0.1:5000>,拖入 PDF 即可。

## 命令行用法

```bash
pip install -r requirements.txt

# 基本转换
python pdf2epub.py input.pdf output.epub

# 只转换部分页面(调试用,页码从 0 开始)
python pdf2epub.py input.pdf output.epub --start 21 --end 64

# 验证输出质量(页脚残留 / 代码块 / 图片完整性)
python verify_epub.py output.epub

# 手动启动 Web 服务
python server.py --host 0.0.0.0 --port 5000
```

## 目录结构

```
pdf2epub/
├── pdf2epub.py      # 核心转换器(CLI + 库)
├── verify_epub.py   # EPUB 质量验证
├── server.py        # Flask Web 后端(上传 / SSE 进度 / 下载)
├── web/             # 前端(单页,无框架依赖)
│   ├── index.html
│   ├── style.css
│   └── app.js
├── deploy.ps1       # Windows 一键部署
├── start.bat        # Windows 双击启动
├── deploy.sh        # macOS / Linux 一键部署
├── Dockerfile       # 容器部署
└── requirements.txt
```

## 已知限制

- 表格按普通文本路径处理，没有完整表格重建；内容和阅读顺序需要人工核对
- 针对 Manning 排版字体规则调优;用于其他出版社 PDF 时可能需要调整
  `pdf2epub.py` 中的字体分类规则(`classify_text_block`)

- 扫描件没有专门 OCR 路径；不能视为通用扫描 PDF 转换器。
- 章节依赖书签区间，首个一级书签前的内容可能不进入输出章节。
- 当前 EPUB 语言元数据固定为英语。
- `verify_epub.py` 输出检查统计和样例，不等于完整自动化回归测试或质量保证。

## 下一步

补充可公开复现的自制输入/输出样例、前后对照截图和失败案例，再验证章节覆盖、图片引用和代码块缩进。Web 服务按本地工具设计，公开部署前需要另行评估上传限制和任务管理。
