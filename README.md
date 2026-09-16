# Folio · pdf2epub — Manning 风格技术书籍 PDF → EPUB 转换器

可用于Manning 排版风格(Verdana 正文 / Consolas 代码 / 灰底代码框)的 PDF 书籍。
本地运行,不上传任何文件。

## 功能

- **去除页眉页脚冗余**:自动移除页码、`© Manning Publications Co. To comment go to liveBook`
  和 `Licensed to ... <邮箱>` 授权水印(版权页正文保留)
- **图文准确**:按阅读顺序提取全部内嵌图片(自动去重),图片与图注一一对应
- **代码块精准还原**:识别等宽字体 + 灰底区域,完整保留缩进与对齐注释,
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

- 表格会按普通段落文本保留(内容不丢,但无表格结构)
- 针对 Manning 排版字体规则调优;用于其他出版社 PDF 时可能需要调整
  `pdf2epub.py` 中的字体分类规则(`classify_text_block`)
