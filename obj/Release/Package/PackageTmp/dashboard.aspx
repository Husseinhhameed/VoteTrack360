<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="dashboard.aspx.cs" Inherits="Election.dashboard" %>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head runat="server">
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>منصة الاشراف والمتابعة</title>

  <!-- Bootstrap RTL -->
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.rtl.min.css" />
  <!-- SweetAlert2 -->
  <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
  <!-- Arabic Font -->
  <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@500;600;700&display=swap" rel="stylesheet" />

  <style>
    body {
      font-family: 'Cairo', sans-serif;
      background: radial-gradient(circle at top left, #dbeafe 0%, #e0f2fe 40%, #ede9fe 100%);
      background-attachment: fixed;
      min-height: 100vh;
      padding: 15px;
    }

    #dashboard { display: none; }

    .header-bar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      background: rgba(255, 255, 255, 0.22);
      backdrop-filter: blur(20px) saturate(180%);
      -webkit-backdrop-filter: blur(20px) saturate(180%);
      border: 1px solid rgba(255, 255, 255, 0.3);
      color: #0d47a1;
      padding: 14px 20px;
      border-radius: 18px;
      margin-bottom: 30px;
      box-shadow: 0 6px 20px rgba(0, 0, 0, 0.12);
      transition: all 0.3s ease;
    }

    .header-bar h4 { margin: 0; font-size: 1.5rem; font-weight: 700; color: #0d47a1; }
    .header-status { font-weight: 600; font-size: 0.95rem; color: #0d47a1; display: flex; align-items: center; flex-wrap: wrap; gap: 8px; }
    .status-dot { width: 10px; height: 10px; border-radius: 50%; background: #28a745; margin-left: 6px; }
    .countdown { font-weight: 700; color: #007bff; }

    @media (max-width: 768px) {
      .header-bar { flex-direction: column; text-align: center; gap: 8px; }
    }

    .glass, .card.glass {
      background: rgba(255, 255, 255, 0.12);
      background-image: linear-gradient(135deg, rgba(255,255,255,0.15), rgba(200,220,255,0.1));
      border: 1px solid rgba(255, 255, 255, 0.25);
      backdrop-filter: blur(30px) saturate(200%) brightness(1.2);
      -webkit-backdrop-filter: blur(30px) saturate(200%) brightness(1.2);
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.25), inset 0 0 0.8px rgba(255, 255, 255, 0.6);
      border-radius: 20px;
      transition: all 0.3s ease;
    }

    .glass:hover, .card.glass:hover {
      background: rgba(255, 255, 255, 0.18);
      transform: translateY(-3px);
      box-shadow: 0 12px 40px rgba(0, 0, 0, 0.25), inset 0 0 1px rgba(255, 255, 255, 0.8);
    }

    .big-number { text-align: center; padding: 30px 15px; margin-bottom: 20px; }
    .big-number h1 { font-size: 6.2rem; color: #007bff; font-weight: 800; margin: 0; }
    .big-number h2 { font-size: 2rem; color: #212529; margin-top: 8px; }
    .big-number small { display: block; color: #555; font-size: 1.1rem; }
    .delta { font-size: 1.1rem; color: #00c853; font-weight: 600; margin-top: 5px; }

    .card { border: none; border-radius: 20px; box-shadow: 0 8px 30px rgba(0, 0, 0, 0.08); overflow: hidden; }

    .filters { text-align: center; margin-bottom: 15px; position: relative; padding: 15px; }
    .filters input {
      width: 200px; max-width: 45%; display: inline-block; margin: 5px;
      border-radius: 8px; padding: 6px 10px; border: 1px solid rgba(255,255,255,0.4);
      background: rgba(255, 255, 255, 0.5); backdrop-filter: blur(10px);
    }
    #searchStatus { position: absolute; bottom: -25px; left: 0; right: 0; text-align: center; color: #0d6efd; font-size: 0.9rem; }

    table th {
      background: rgba(0, 123, 255, 0.85);
      color: #fff;
      text-align: center;
      position: sticky;
      top: 0;
      z-index: 5;
      backdrop-filter: blur(6px);
    }
    table td { text-align: center; vertical-align: middle; }
    table tbody tr {   user-select: none;
transition: all 0.25s ease; cursor: pointer; }
    table tbody tr:hover { transform: scale(1.02); box-shadow: 0 3px 10px rgba(0, 0, 0, 0.1); z-index: 2; }

    #overlayLoading {
      position: fixed;
      top: 0; left: 0; right: 0; bottom: 0;
      background: rgba(255, 255, 255, 0.6);
      display: none;
      align-items: center;
      justify-content: center;
      font-size: 1.5rem;
      font-weight: 700;
      color: #0056b3;
      z-index: 9999;
      backdrop-filter: blur(12px);
    }

    #loadMoreBtn { display: block; margin: 15px auto 0 auto; }
    .update-time { text-align: center; color: #777; margin-top: 10px; }

    #fullscreenBtn {
      position: absolute; top: 10px; left: -35px;
      font-size: 1.3rem; color: #007bff;
      background: rgba(255, 255, 255, 0.8);
      border-radius: 8px; padding: 4px 10px;
      cursor: pointer; box-shadow: 0 3px 6px rgba(0, 0, 0, 0.2);
      transition: all 0.3s ease; backdrop-filter: blur(10px);
    }
    #fullscreenBtn:hover { transform: scale(1.1); background: #007bff; color: #fff; }

    @media (max-width: 768px) {
      .big-number h1 { font-size: 2.5rem; }
      .big-number h2 { font-size: 1.6rem; }
      .filters input { width: 100%; max-width: 100%; }
    }
  </style>
</head>

<body>
  <div id="overlayLoading">⏳ جاري التحديث...</div>
  <form id="form1" runat="server">
    <asp:ScriptManager ID="ScriptManager1" runat="server" EnablePageMethods="true" />

    <audio id="addSound" src="Newadd.wav" preload="auto"></audio>

    <div id="dashboard" class="container position-relative">
      <div id="fullscreenBtn" onclick="toggleFullscreen()">⛶</div>

      <div class="header-bar glass">
        <h4>📊 منصة الاشراف والمتابعة</h4>
        <div class="header-status">
          🕓 آخر تحديث: <span id="lblLastUpdate">—:—:—</span>
          <span class="status-dot" id="statusDot"></span>
          • ⏱ التحديث التالي خلال <span id="countdown" class="countdown">60</span> ثانية
        </div>
      </div>

      <div class="big-number glass">
        <small>العدد الكلي للأصوات حتى اللحظة</small>
        <h1 id="totalVotes">0</h1>
        <div class="delta" id="voteDelta"></div>
        <hr style="width:50%;margin:auto;" />
        <small>عدد الصناديق</small>
        <h2 id="totalBoxes">0</h2>
        <div class="text-muted mt-2">🕓 آخر تسجيل في: <span id="lastEntry">—</span></div>
      </div>

      <div class="filters glass">
        <input type="text" id="filterName" placeholder="🔍 بحث بالاسم" />
        <input type="text" id="filterCenter" placeholder="🏫 بحث بالمركز" />
        <div id="searchStatus"></div>
      </div>

      <div class="card glass p-3 table-wrapper">
        <h5 class="mb-3 text-muted">📋 التقارير المرسلة (الأحدث أولاً)</h5>
        <div class="table-responsive" style="max-height:60vh;overflow:auto;">
          <table class="table table-striped table-hover">
            <thead>
              <tr>
                <th>الاسم الكامل</th>
                <th>اسم المركز</th>
                <th>رقم المحطة</th>
                <th>رقم الصندوق</th>
                <th>عدد الأصوات</th>
                <th>تاريخ ووقت الإدخال</th>
              </tr>
            </thead>
            <tbody id="tbodyData"><tr><td colspan="6">جاري التحميل...</td></tr></tbody>
          </table>
        </div>
        <button id="loadMoreBtn" class="btn btn-outline-primary btn-sm">تحميل المزيد</button>
      </div>

      <div class="card glass p-3 mt-4">
        <h5 class="mb-3 text-muted">🏆 أعلى 5 صناديق من حيث عدد الأصوات</h5>
        <div class="table-responsive">
          <table class="table table-bordered">
            <thead><tr><th>المركز</th><th>المحطة</th><th>الصندوق</th><th>عدد الأصوات</th></tr></thead>
            <tbody id="tbodyTop5"><tr><td colspan="4">جاري التحميل...</td></tr></tbody>
          </table>
        </div>
      </div>

      <div class="update-time"><small class="text-muted">يتم التحديث تلقائيًا كل 60 ثانية.</small></div>
    </div>
  </form>

  <!-- ===== JavaScript Logic ===== -->
  <script>
      const _pass = atob("UmVjMTIzNDU="); // Password: Rec12345
      let remaining = 60, lastMaxId = 0, searchTimeout;
      let currentName = "", currentCenter = "";
      let prevTotalVotes = 0;
      let rowsShown = 100;

      function unlockAndStart() {
          sessionStorage.setItem("dashboardUnlocked", "1");
          document.getElementById("dashboard").style.display = "block";
          pullData(true);
          startLoop();
      }

      async function askPassword() {
          const { value: password } = await Swal.fire({
              title: "🔒 حماية الوصول",
              input: "password",
              inputLabel: "أدخل كلمة المرور للوصول إلى المنصة",
              inputPlaceholder: "********",
              confirmButtonText: "دخول",
              allowOutsideClick: false,
              allowEscapeKey: false,
              preConfirm: (val) => { if (val !== _pass) Swal.showValidationMessage("كلمة المرور غير صحيحة!"); }
          });
          if (password === _pass) unlockAndStart();
          else {
              await Swal.fire({ icon: "error", text: "تم رفض الوصول!" });
              location.href = "observer.aspx";
          }
      }

      function startLoop() {
          setInterval(() => {
              remaining--;
              if (remaining <= 0) { pullData(true); remaining = 60; }
              document.getElementById("countdown").textContent = remaining;
          }, 1000);
      }

      function animateNumber(id, newValue) {
          const el = document.getElementById(id);
          const current = parseInt(el.textContent.replace(/\D/g, "")) || 0;
          const diff = newValue - current;
          const steps = 20;
          let step = 0;
          const timer = setInterval(() => {
              step++;
              el.textContent = Math.round(current + (diff * step / steps)).toLocaleString('ar-IQ');
              if (step >= steps) clearInterval(timer);
          }, 40);
      }

      function setStatus(ok) {
          document.getElementById("statusDot").style.background = ok ? "#28a745" : "#dc3545";
      }

      function hexToRgba(hex, alpha) {
          const m = hex.replace('#', '');
          const r = parseInt(m.substring(0, 2), 16);
          const g = parseInt(m.substring(2, 4), 16);
          const b = parseInt(m.substring(4, 6), 16);
          return `rgba(${r}, ${g}, ${b}, ${alpha})`;
      }

      function tintRowByVotes(tr, votes) {
          let base = '#00c853';
          if (votes === 0) base = '#dc3545';
          else if (votes > 0 && votes <= 10) base = '#ffc107';
          const stop1 = hexToRgba(base, 0.18);
          const stop2 = hexToRgba(base, 0.40);
          tr.style.background = `linear-gradient(90deg, #ffffff 0%, ${stop1} 35%, ${stop2} 100%)`;
          tr.style.color = votes === 0 ? '#fff' : '#111';
          tr.querySelectorAll('td').forEach(td => td.style.background = 'transparent');
      }

      function applyRowColors() {
          document.querySelectorAll('#tbodyData tr').forEach(tr => {
              const v = parseInt(tr.getAttribute('data-votes')) || 0;
              tintRowByVotes(tr, v);
          });
      }

      function showOverlay(show) {
          document.getElementById('overlayLoading').style.display = show ? 'flex' : 'none';
      }

      // ✅ Updated: Smooth fade animation during refresh
      function pullData(full = true) {
          const table = document.getElementById("tbodyData");
          const top5 = document.getElementById("tbodyTop5");
          const overlay = document.getElementById('overlayLoading');

          if (full) overlay.style.display = 'flex'; // show overlay only for full updates
          setStatus(true);

          // start fade out
          table.style.transition = "opacity 0.5s ease";
          top5.style.transition = "opacity 0.5s ease";
          table.style.opacity = 0.3;
          top5.style.opacity = 0.3;

          PageMethods.GetDashboardData(currentName, currentCenter,
              res => {
                  setTimeout(() => {
                      table.innerHTML = res.TableRowsHtml;
                      applyRowColors();
                      document.getElementById("lblLastUpdate").textContent = new Date().toLocaleTimeString('ar-IQ');
                      top5.innerHTML = res.Top5Html;

                      const allRows = table.querySelectorAll('tr');
                      allRows.forEach((r, i) => { if (i >= rowsShown) r.style.display = 'none'; });
                      document.getElementById("loadMoreBtn").style.display = allRows.length > rowsShown ? 'block' : 'none';

                      if (full) {
                          animateNumber("totalVotes", res.TotalVotes);
                          animateNumber("totalBoxes", res.TotalBoxes);
                          document.getElementById("lastEntry").textContent = res.LastEntryTime || "—";
                          const delta = res.TotalVotes - prevTotalVotes;
                          if (prevTotalVotes > 0 && delta !== 0) {
                              const d = document.getElementById("voteDelta");
                              d.textContent = (delta > 0 ? `+${delta.toLocaleString('ar-IQ')} منذ آخر تحديث` : "");
                              d.style.color = "#00c853";
                              d.style.opacity = 1;
                              setTimeout(() => d.style.opacity = 0.4, 4000);
                          }
                          prevTotalVotes = res.TotalVotes;
                      }

                      if (lastMaxId !== 0 && res.LastMaxId > lastMaxId && full) {
                          Swal.fire({
                              toast: true,
                              position: 'top',
                              icon: 'success',
                              title: '✅ تم إضافة بيانات جديدة للتو',
                              showConfirmButton: false,
                              timer: 2500
                          });
                          const snd = document.getElementById('addSound');
                          if (snd) { try { snd.currentTime = 0; snd.play(); } catch (e) { } }
                      }
                      lastMaxId = res.LastMaxId;

                      table.style.opacity = 1;
                      top5.style.opacity = 1;
                      if (full) overlay.style.display = 'none';
                      document.getElementById('searchStatus').textContent = "";
                  }, 250);
              },
              err => {
                  console.error(err);
                  setStatus(false);
                  if (full) overlay.style.display = 'none';
              }
          );
      }

      document.addEventListener("input", e => {
          if (e.target.id === "filterName" || e.target.id === "filterCenter") {
              clearTimeout(searchTimeout);
              document.getElementById('searchStatus').textContent = "🔍 جاري البحث...";
              searchTimeout = setTimeout(() => {
                  currentName = document.getElementById("filterName").value.trim();
                  currentCenter = document.getElementById("filterCenter").value.trim();
                  pullData(false);
              }, 1000);
          }
      });

      document.addEventListener("keydown", e => {
          if (e.key === "Enter" && (e.target.id === "filterName" || e.target.id === "filterCenter")) {
              e.preventDefault();
              clearTimeout(searchTimeout);
              document.getElementById('searchStatus').textContent = "🔍 جاري البحث...";
              currentName = document.getElementById("filterName").value.trim();
              currentCenter = document.getElementById("filterCenter").value.trim();
              pullData(false);
          }
      });

      document.getElementById("loadMoreBtn").addEventListener("click", () => {
          rowsShown += 100;
          const rows = document.querySelectorAll("#tbodyData tr");
          rows.forEach((r, i) => { if (i < rowsShown) r.style.display = ''; });
          if (rows.length <= rowsShown) document.getElementById("loadMoreBtn").style.display = 'none';
      });

      document.addEventListener("dblclick", e => {
          const row = e.target.closest("tr[data-img]");
          if (row) {
              const img = row.getAttribute("data-img");
              if (img) {
                  Swal.fire({ title: "📸 صورة النتائج", imageUrl: img, imageAlt: "صورة النتائج", width: "90%", imageWidth: "100%", showConfirmButton: true, confirmButtonText: "إغلاق" });
              }
          }
      });

      function toggleFullscreen() {
          const doc = document.documentElement;
          if (!document.fullscreenElement) doc.requestFullscreen();
          else document.exitFullscreen();
      }

      window.addEventListener('load', () => {
          if (sessionStorage.getItem("dashboardUnlocked") === "1") {
              document.getElementById("dashboard").style.display = "block";
              pullData(true);
              startLoop();
          } else askPassword();
      });

      // ================= INLINE EDIT FEATURE (improved alignment + instant total refresh) =================
      let rightClickedRow = null;

      // Create context menu
      const contextMenu = document.createElement("div");
      contextMenu.id = "contextMenu";
      contextMenu.style.cssText = `
  position:absolute;display:none;z-index:99999;
  background:rgba(255,255,255,0.97);
  border:1px solid #ccc;border-radius:8px;
  box-shadow:0 4px 12px rgba(0,0,0,0.25);
  padding:5px 0;width:120px;text-align:center;
  font-family:'Cairo',sans-serif;font-size:0.9rem;`;
      contextMenu.innerHTML = `<div id="editRowBtn" style="padding:8px;cursor:pointer;">✏️ تعديل</div>`;
      document.body.appendChild(contextMenu);

      // Hide menu when clicking elsewhere
      document.addEventListener("click", () => contextMenu.style.display = "none");

      // Right-click on table row
      document.addEventListener("contextmenu", (e) => {
          const tr = e.target.closest("#tbodyData tr");
          if (!tr) return;
          e.preventDefault();
          rightClickedRow = tr;
          contextMenu.style.left = `${e.pageX}px`;
          contextMenu.style.top = `${e.pageY}px`;
          contextMenu.style.display = "block";
      });

      // When user clicks تعديل
      document.getElementById("editRowBtn").addEventListener("click", () => {
          contextMenu.style.display = "none";
          if (!rightClickedRow) return;

          // Editable cells (center, station, box, votes)
          const editable = [1, 2, 3, 4];
          editable.forEach(i => {
              const td = rightClickedRow.children[i];
              const val = td.textContent.trim();
              td.innerHTML = `<input type="text" value="${val}" 
      class="form-control form-control-sm text-center" 
      style="min-width:90px;border-radius:6px;border:1px solid #ddd;">`;
          });

          // Create fixed-position save button aligned to row right
          let saveBtn = document.createElement("button");
          saveBtn.textContent = "💾 حفظ";
          saveBtn.className = "btn btn-success btn-sm";
          saveBtn.style.cssText = `
    position:absolute;
    transform:translateY(-50%);
    right:30px;
    height:32px;
    border-radius:12px;
    font-size:0.9rem;
    padding:0 14px;
    box-shadow:0 4px 10px rgba(0,0,0,0.15);
  `;

          // Append save button near the row (visually aligned)
          const rect = rightClickedRow.getBoundingClientRect();
          saveBtn.style.top = (window.scrollY + rect.top + rect.height / 2) + "px";
          document.body.appendChild(saveBtn);

          saveBtn.addEventListener("click", async () => {
              const id = rightClickedRow.getAttribute("data-id");
              const center = rightClickedRow.children[1].querySelector("input").value.trim();
              const station = rightClickedRow.children[2].querySelector("input").value.trim();
              const box = rightClickedRow.children[3].querySelector("input").value.trim();
              const votes = rightClickedRow.children[4].querySelector("input").value.trim();

              try {
                  await new Promise((resolve, reject) => {
                      PageMethods.UpdateBoxData(id, center, station, box, votes, res => resolve(res), err => reject(err));
                  });

                  Swal.fire({ icon: "success", title: "✅ تم حفظ التعديلات", timer: 1300, showConfirmButton: false });
                  rightClickedRow.children[1].textContent = center;
                  rightClickedRow.children[2].textContent = station;
                  rightClickedRow.children[3].textContent = box;
                  rightClickedRow.children[4].textContent = votes;

                  // ✅ instantly refresh totals and top5
                  pullData(true);

                  saveBtn.remove();

                  // Optional: small blue highlight after save
                  rightClickedRow.style.transition = "background 0.6s ease";
                  rightClickedRow.style.background = "linear-gradient(90deg,#e3f2fd,#bbdefb)";
                  setTimeout(() => { rightClickedRow.style.background = ""; }, 1200);

              } catch (e) {
                  Swal.fire({ icon: "error", text: "❌ فشل التحديث" });
                  console.error(e);
                  saveBtn.remove();
              }
          });
      });

  </script>
</body>
</html>
