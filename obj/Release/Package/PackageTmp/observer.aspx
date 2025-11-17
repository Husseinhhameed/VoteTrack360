<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="observer.aspx.cs" Inherits="Election.observer" %>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>استمارة نتائج الاقتراع</title>

    <!-- Bootstrap RTL -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.rtl.min.css" />
    <!-- SweetAlert2 -->
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
    <!-- Arabic Font -->
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@500;600;700&display=swap" rel="stylesheet" />

    <style>
        body {
            font-family: 'Cairo', sans-serif;
            background-color: #f8f9fa;
            padding: 15px;
        }
        .card {
            border: none;
            border-radius: 16px;
            box-shadow: 0 6px 18px rgba(0,0,0,0.1);
        }
        label { font-weight: 600; }
        .required::after { content: " *"; color: #dc3545; }
        .form-control {
            border-radius: 10px;
            padding: 0.9rem 1rem;
            font-size: 1.1rem;
        }
        .btn-primary {
            border-radius: 12px;
            background: linear-gradient(90deg, #007bff, #0056b3);
            border: none;
            font-size: 1.2rem;
            padding: 0.9rem;
        }
        .btn-primary:hover {
            background: linear-gradient(90deg, #0056b3, #00408d);
        }
        .input-group-text {
            background-color: #e9ecef;
            border-radius: 10px 0 0 10px;
        }
        .upload-group { direction: ltr; }
        #fileNameDisplay {
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }
        #previewImg {
            max-width: 100%;
            border-radius: 10px;
        }
        @media (max-width: 576px) {
            .upload-group {
                flex-direction: column;
                align-items: stretch;
            }
            .upload-group button, #fileNameDisplay {
                width: 100%;
                margin-bottom: 8px;
            }
            .btn-primary {
                position: sticky;
                bottom: 15px;
                width: 100%;
                z-index: 999;
            }
        }
    </style>
</head>
<body>
<form id="form1" runat="server">
    <div class="container" style="max-width:700px;">
        <div class="card p-4 mb-5">
            <h3 class="text-center mb-4">🗳️ استمارة تسجيل نتائج الاقتراع</h3>

            <asp:ValidationSummary ID="ValidationSummary1" runat="server" CssClass="alert alert-danger" />

            <!-- Full Name -->
            <div class="mb-3">
                <label class="required">الاسم الكامل</label>
                <div class="input-group">
                    <span class="input-group-text">👤</span>
                    <asp:TextBox ID="txtName" runat="server" CssClass="form-control" placeholder="اكتب الاسم الكامل هنا" />
                </div>
                <asp:RequiredFieldValidator ID="rfvName" runat="server" ControlToValidate="txtName"
                    ErrorMessage="الاسم مطلوب" CssClass="text-danger" Display="Dynamic" />
            </div>

            <!-- Center Name -->
            <div class="mb-3">
                <label class="required">اسم مركز الاقتراع</label>
                <div class="input-group">
                    <span class="input-group-text">🏫</span>
                    <asp:TextBox ID="txtCenter" runat="server" CssClass="form-control" placeholder="اكتب اسم المركز" />
                </div>
                <asp:RequiredFieldValidator ID="rfvCenter" runat="server" ControlToValidate="txtCenter"
                    ErrorMessage="اسم المركز مطلوب" CssClass="text-danger" Display="Dynamic" />
            </div>

            <hr class="my-4" />
            <h5 class="text-muted mb-3">📍 بيانات المحطة والصندوق</h5>

            <div class="row g-3">
                <div class="col-md-4">
                    <label class="required">رقم المحطة</label>
                    <asp:TextBox ID="txtStation" runat="server" CssClass="form-control"
                        TextMode="SingleLine" inputmode="numeric" pattern="[0-9٠-٩۰-۹]+" placeholder="مثلاً 5" />
                    <asp:RequiredFieldValidator ID="rfvStation" runat="server" ControlToValidate="txtStation"
                        ErrorMessage="رقم المحطة مطلوب" CssClass="text-danger" Display="Dynamic" />
                </div>
                <div class="col-md-4">
                    <label class="required">رقم الصندوق</label>
                    <asp:TextBox ID="txtBox" runat="server" CssClass="form-control"
                        TextMode="SingleLine" inputmode="numeric" pattern="[0-9٠-٩۰-۹]+" placeholder="مثلاً 2" />
                    <asp:RequiredFieldValidator ID="rfvBox" runat="server" ControlToValidate="txtBox"
                        ErrorMessage="رقم الصندوق مطلوب" CssClass="text-danger" Display="Dynamic" />
                </div>
                <div class="col-md-4">
                    <label class="required">عدد الأصوات المسجلة</label>
                    <asp:TextBox ID="txtVotes" runat="server" CssClass="form-control"
                        TextMode="SingleLine" inputmode="numeric" pattern="[0-9٠-٩۰-۹]+" placeholder="أدخل العدد" />
                    <asp:RequiredFieldValidator ID="rfvVotes" runat="server" ControlToValidate="txtVotes"
                        ErrorMessage="عدد الأصوات مطلوب" CssClass="text-danger" Display="Dynamic" />
                </div>
            </div>

            <hr class="my-4" />
            <h5 class="text-muted mb-3">📷 صورة النتائج</h5>

            <div class="mb-3">
                <label class="required">التقاط أو اختيار صورة النتائج</label>
                <div class="input-group upload-group">
                    <asp:FileUpload ID="fuRecipt" runat="server" CssClass="d-none"
                        accept="image/*" onchange="handleImageSelect(this)" />
                    <button type="button" class="btn btn-outline-primary"
                        onclick="document.getElementById('<%= fuRecipt.ClientID %>').click();">
                        📷 التقاط أو اختيار صورة
                    </button>
                    <span id="fileNameDisplay" class="form-control bg-light text-muted">لم يتم اختيار أي ملف</span>
                </div>
                <small class="text-muted">الامتدادات المسموحة: JPG, JPEG, PNG</small>
                <img id="previewImg" class="img-fluid mt-3 d-none" />
            </div>

            <div class="d-grid mt-4">
                <asp:Button ID="btnSave" runat="server" Text="📤 إرسال" CssClass="btn btn-primary"
                    OnClientClick="return checkFile();" OnClick="btnSave_Click" />
            </div>
        </div>
    </div>
</form>

<script>
    function canSubmitNow() {
        const limit = 2;
        const windowMs = 30 * 60 * 1000;
        const now = Date.now();
        const cookie = document.cookie.split('; ').find(r => r.startsWith('reportHistory='));
        let history = [];
        if (cookie) {
            try { history = JSON.parse(decodeURIComponent(cookie.split('=')[1])); } catch { history = []; }
        }
        history = history.filter(t => now - t < windowMs);
        if (history.length >= limit) {
            Swal.fire({ icon: 'error', title: 'تم تجاوز الحد', text: 'لقد تجاوزت الحد المسموح لإرسال التقارير، أرسل تقريرك الجديد بعد نصف ساعة.', confirmButtonText: 'حسنًا' });
            return false;
        }
        history.push(now);
        document.cookie = "reportHistory=" + encodeURIComponent(JSON.stringify(history)) + "; path=/; max-age=" + (60 * 60);
        return true;
    }

    async function handleImageSelect(input) {
        const label = document.getElementById('fileNameDisplay');
        const preview = document.getElementById('previewImg');
        if (input.files.length === 0) {
            label.textContent = 'لم يتم اختيار أي ملف';
            label.classList.add('text-muted');
            preview.classList.add('d-none');
            return;
        }
        const file = input.files[0];
        label.textContent = file.name;
        label.classList.remove('text-muted');
        const reader = new FileReader();
        reader.onload = e => { preview.src = e.target.result; preview.classList.remove('d-none'); };
        reader.readAsDataURL(file);
    }

    function showSavingDialog() {
        Swal.fire({ title: 'جارٍ حفظ البيانات...', text: 'يرجى الانتظار لحين اكتمال العملية', allowOutsideClick: false, allowEscapeKey: false, didOpen: () => Swal.showLoading() });
    }

    function checkFile() {
        const fu = document.getElementById('<%= fuRecipt.ClientID %>');
        if (fu.value === "") {
            Swal.fire({ icon: 'error', title: 'الصورة مطلوبة', text: 'يجب رفع صورة النتائج قبل الإرسال.', confirmButtonText: 'حسنًا' });
            return false;
        }
        if (!canSubmitNow()) return false;
        showSavingDialog();
        return true;
    }
</script>
</body>
</html>
