/* Folio · 前端交互:拖拽上传 -> SSE 进度 -> 下载 */
(() => {
  "use strict";

  const dropzone    = document.getElementById("dropzone");
  const fileInput   = document.getElementById("fileInput");
  const progressCard = document.getElementById("progressCard");
  const progressBar = document.getElementById("progressBar");
  const phaseLabel  = document.getElementById("phaseLabel");
  const fileLabel   = document.getElementById("fileLabel");
  const resultCard  = document.getElementById("resultCard");
  const resultMeta  = document.getElementById("resultMeta");
  const downloadBtn = document.getElementById("downloadBtn");
  const againBtn    = document.getElementById("againBtn");
  const errorCard   = document.getElementById("errorCard");
  const errorMsg    = document.getElementById("errorMsg");
  const retryBtn    = document.getElementById("retryBtn");

  let busy = false;

  const show = (el) => { el.hidden = false; };
  const hide = (el) => { el.hidden = true; };

  function reset() {
    busy = false;
    hide(progressCard); hide(resultCard); hide(errorCard);
    show(dropzone);
    fileInput.value = "";
    progressBar.style.width = "0%";
  }

  function fmtSize(bytes) {
    if (bytes > 1048576) return (bytes / 1048576).toFixed(1) + " MB";
    return Math.round(bytes / 1024) + " KB";
  }

  /* ---------- 文件选择 ---------- */

  dropzone.addEventListener("click", () => !busy && fileInput.click());
  dropzone.addEventListener("keydown", (e) => {
    if ((e.key === "Enter" || e.key === " ") && !busy) {
      e.preventDefault();
      fileInput.click();
    }
  });
  fileInput.addEventListener("change", () => {
    if (fileInput.files.length) startConvert(fileInput.files[0]);
  });

  ["dragenter", "dragover"].forEach((ev) =>
    dropzone.addEventListener(ev, (e) => {
      e.preventDefault();
      if (!busy) dropzone.classList.add("dragover");
    })
  );
  ["dragleave", "drop"].forEach((ev) =>
    dropzone.addEventListener(ev, (e) => {
      e.preventDefault();
      dropzone.classList.remove("dragover");
    })
  );
  dropzone.addEventListener("drop", (e) => {
    if (busy) return;
    const f = e.dataTransfer.files && e.dataTransfer.files[0];
    if (!f) return;
    if (!/\.pdf$/i.test(f.name)) {
      showError("仅支持 PDF 文件");
      return;
    }
    startConvert(f);
  });

  /* ---------- 转换流程 ---------- */

  async function startConvert(file) {
    busy = true;
    hide(resultCard); hide(errorCard);
    hide(dropzone);
    fileLabel.textContent = file.name + " · " + fmtSize(file.size);
    phaseLabel.textContent = "正在上传…";
    progressBar.style.width = "3%";
    show(progressCard);

    let jobId;
    try {
      const fd = new FormData();
      fd.append("file", file);
      const resp = await fetch("/api/convert", { method: "POST", body: fd });
      const data = await resp.json();
      if (!resp.ok) throw new Error(data.error || "上传失败");
      jobId = data.job_id;
    } catch (err) {
      showError(err.message);
      return;
    }

    const es = new EventSource("/api/progress/" + jobId);
    es.onmessage = (m) => {
      let evt;
      try { evt = JSON.parse(m.data); } catch { return; }

      if (evt.type === "progress") {
        progressBar.style.width = evt.percent + "%";
        phaseLabel.style.opacity = 0;
        setTimeout(() => {
          phaseLabel.textContent = evt.message;
          phaseLabel.style.opacity = 1;
        }, 180);
      } else if (evt.type === "done") {
        es.close();
        progressBar.style.width = "100%";
        setTimeout(() => {
          hide(progressCard);
          resultMeta.textContent =
            `${evt.filename} · ${fmtSize(evt.size)} · ` +
            `${evt.chapters} 章 · ${evt.images} 幅插图 · 用时 ${evt.seconds} 秒`;
          downloadBtn.href = evt.download;
          downloadBtn.setAttribute("download", evt.filename);
          show(resultCard);
        }, 350);
      } else if (evt.type === "error") {
        es.close();
        showError(evt.message);
      }
    };
    es.onerror = () => {
      es.close();
      if (busy && resultCard.hidden && errorCard.hidden) {
        showError("与服务器的连接中断");
      }
    };
  }

  function showError(msg) {
    busy = false;
    hide(progressCard); hide(resultCard);
    errorMsg.textContent = msg;
    show(errorCard);
  }

  againBtn.addEventListener("click", reset);
  retryBtn.addEventListener("click", reset);
})();
