#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
server.py — pdf2epub Web 界面后端

本地运行, 不上传任何文件到外部:
  POST /api/convert   上传 PDF, 返回 job_id
  GET  /api/progress  SSE 推送转换进度
  GET  /api/download  下载生成的 EPUB
"""

import argparse
import json
import os
import queue
import re
import tempfile
import threading
import time
import uuid

from flask import Flask, request, jsonify, Response, send_file, send_from_directory

from pdf2epub import build_epub

WEB_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "web")
JOBS_DIR = os.path.join(tempfile.gettempdir(), "pdf2epub_jobs")
os.makedirs(JOBS_DIR, exist_ok=True)

app = Flask(__name__, static_folder=WEB_DIR, static_url_path="")

JOBS = {}          # job_id -> {"queue": Queue, "epub": path, "name": str, "ts": float}
JOB_TTL = 30 * 60  # 30 分钟过期


def cleanup_jobs():
    now = time.time()
    for jid, job in list(JOBS.items()):
        if now - job["ts"] > JOB_TTL:
            for p in (job.get("epub"), job.get("pdf")):
                if p and os.path.exists(p):
                    try:
                        os.remove(p)
                    except OSError:
                        pass
            JOBS.pop(jid, None)


def run_conversion(jid, pdf_path, display_name):
    job = JOBS[jid]
    q = job["queue"]
    epub_path = os.path.join(JOBS_DIR, f"{jid}.epub")
    try:
        def cb(pct, msg):
            q.put({"type": "progress", "percent": pct, "message": msg})

        t0 = time.time()
        ext, chapters = build_epub(pdf_path, epub_path, progress_cb=cb)
        job["epub"] = epub_path
        size = os.path.getsize(epub_path)
        q.put({
            "type": "done",
            "percent": 100,
            "message": "转换完成",
            "download": f"/api/download/{jid}",
            "filename": re.sub(r"\.pdf$", "", display_name, flags=re.I) + ".epub",
            "size": size,
            "chapters": len(chapters),
            "images": len(ext.images),
            "seconds": round(time.time() - t0, 1),
        })
    except Exception as exc:  # noqa: BLE001 - 把任何异常透传给前端
        q.put({"type": "error", "message": f"{type(exc).__name__}: {exc}"})
    finally:
        job["ts"] = time.time()
        if os.path.exists(pdf_path):
            try:
                os.remove(pdf_path)
            except OSError:
                pass


@app.route("/")
def index():
    return send_from_directory(WEB_DIR, "index.html")


@app.route("/api/convert", methods=["POST"])
def convert():
    cleanup_jobs()
    f = request.files.get("file")
    if not f or not f.filename:
        return jsonify({"error": "未收到文件"}), 400
    if not f.filename.lower().endswith(".pdf"):
        return jsonify({"error": "仅支持 PDF 文件"}), 400

    jid = uuid.uuid4().hex[:12]
    pdf_path = os.path.join(JOBS_DIR, f"{jid}.pdf")
    f.save(pdf_path)
    JOBS[jid] = {"queue": queue.Queue(), "epub": None, "pdf": pdf_path,
                 "name": f.filename, "ts": time.time()}
    threading.Thread(target=run_conversion, args=(jid, pdf_path, f.filename),
                     daemon=True).start()
    return jsonify({"job_id": jid})


@app.route("/api/progress/<jid>")
def progress(jid):
    job = JOBS.get(jid)
    if not job:
        return jsonify({"error": "任务不存在或已过期"}), 404

    def stream():
        q = job["queue"]
        while True:
            try:
                evt = q.get(timeout=120)
            except queue.Empty:
                yield "event: ping\ndata: {}\n\n"
                continue
            yield f"data: {json.dumps(evt, ensure_ascii=False)}\n\n"
            if evt["type"] in ("done", "error"):
                break

    return Response(stream(), mimetype="text/event-stream",
                    headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"})


@app.route("/api/download/<jid>")
def download(jid):
    job = JOBS.get(jid)
    if not job or not job.get("epub") or not os.path.exists(job["epub"]):
        return jsonify({"error": "文件不存在或已过期"}), 404
    name = re.sub(r"\.pdf$", "", job["name"], flags=re.I) + ".epub"
    return send_file(job["epub"], as_attachment=True, download_name=name,
                     mimetype="application/epub+zip")


def main():
    ap = argparse.ArgumentParser(description="pdf2epub Web 服务")
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--port", type=int, default=5000)
    args = ap.parse_args()
    print(f"  pdf2epub 转换工坊:  http://{args.host}:{args.port}")
    app.run(host=args.host, port=args.port, threaded=True)


if __name__ == "__main__":
    main()
