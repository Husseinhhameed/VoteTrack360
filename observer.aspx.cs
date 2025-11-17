using System;
using System.Configuration;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace Election
{
    public partial class observer : Page
    {
        private const string UploadFolderRelative = "~/Uploads/Recipts/";

        protected void Page_Load(object sender, EventArgs e)
        {
            ValidationSettings.UnobtrusiveValidationMode = UnobtrusiveValidationMode.None;
            string physical = Server.MapPath(UploadFolderRelative);
            if (!Directory.Exists(physical))
                Directory.CreateDirectory(physical);
        }

        protected void btnSave_Click(object sender, EventArgs e)
        {
            try
            {
                if (!Page.IsValid)
                {
                    ShowAlert("خطأ", "يرجى تعبئة جميع الحقول المطلوبة.", "error");
                    return;
                }

                string name = txtName.Text.Trim();
                string center = txtCenter.Text.Trim();

                // Convert Arabic/Persian digits to ASCII
                string stationText = ToAsciiDigitsOnly(txtStation.Text.Trim());
                string boxText = ToAsciiDigitsOnly(txtBox.Text.Trim());
                string votesText = ToAsciiDigitsOnly(txtVotes.Text.Trim());

                // Validate numeric fields
                if (!int.TryParse(stationText, out int station) ||
                    !int.TryParse(boxText, out int box) ||
                    !int.TryParse(votesText, out int votes))
                {
                    ShowAlert("قيمة غير صحيحة", "يجب أن تكون الحقول (المحطة، الصندوق، وعدد الأصوات) أرقامًا صحيحة.", "error");
                    return;
                }

                // File validation
                if (!fuRecipt.HasFile)
                {
                    ShowAlert("الصورة مطلوبة", "يرجى رفع صورة نتائج الاقتراع قبل الحفظ.", "error");
                    return;
                }

                string[] allowed = { ".jpg", ".jpeg", ".png" };
                string ext = Path.GetExtension(fuRecipt.FileName).ToLowerInvariant();
                if (!allowed.Contains(ext))
                {
                    ShowAlert("امتداد غير مسموح", "الامتدادات المسموحة: JPG, JPEG, PNG.", "error");
                    return;
                }

                // Safe file name
                string baseName = $"{MakeSafeFilePart(name)}-{MakeSafeFilePart(center)}-{station}-{box}";
                string fileName = baseName + ".jpg";
                string savePath = Path.Combine(Server.MapPath(UploadFolderRelative), fileName);

                int counter = 1;
                while (File.Exists(savePath))
                {
                    fileName = $"{baseName}({counter}).jpg";
                    savePath = Path.Combine(Server.MapPath(UploadFolderRelative), fileName);
                    counter++;
                }

                // Save compressed image
                CompressAndSaveImage(fuRecipt.PostedFile, savePath, 1280, 80);
                string reciptPath = UploadFolderRelative + fileName;

                string cs = ConfigurationManager.ConnectionStrings["ObservConn"].ConnectionString;

                // Duplicate check (normalized)
                bool isDuplicate = false;
                string centerNorm = NormalizeKey(center);
                string stationNorm = station.ToString();
                string boxNorm = box.ToString();

                using (SqlConnection conn = new SqlConnection(cs))
                {
                    conn.Open();
                    string checkQuery = @"
                        SELECT COUNT(*) FROM Obsrvt
                        WHERE LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(Center)), CHAR(160), ''),' ',''),CHAR(9),''),CHAR(13),''),CHAR(10),'')) = @CenterNorm
                          AND LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(Station)), CHAR(160), ''),' ',''),CHAR(9),''),CHAR(13),''),CHAR(10),'')) = @StationNorm
                          AND LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(Box)), CHAR(160), ''),' ',''),CHAR(9),''),CHAR(13),''),CHAR(10),'')) = @BoxNorm";

                    using (SqlCommand checkCmd = new SqlCommand(checkQuery, conn))
                    {
                        checkCmd.Parameters.AddWithValue("@CenterNorm", centerNorm);
                        checkCmd.Parameters.AddWithValue("@StationNorm", stationNorm);
                        checkCmd.Parameters.AddWithValue("@BoxNorm", boxNorm);
                        int exists = (int)checkCmd.ExecuteScalar();
                        if (exists > 0)
                        {
                            isDuplicate = true;
                        }
                    }

                    if (isDuplicate)
                    {
                        ShowAlert("بيانات مكررة", "⚠️ هذا السجل موجود مسبقًا (نفس المركز والمحطة والصندوق).", "warning");
                        return;
                    }

                    // Insert new record
                    string query = @"INSERT INTO Obsrvt (Name, Center, Station, Box, Dattime, Votes, Recipt)
                                     VALUES (@Name, @Center, @Station, @Box, @Dattime, @Votes, @Recipt)";
                    using (SqlCommand cmd = new SqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("@Name", name);
                        cmd.Parameters.AddWithValue("@Center", center);
                        cmd.Parameters.AddWithValue("@Station", station);
                        cmd.Parameters.AddWithValue("@Box", box);
                        cmd.Parameters.AddWithValue("@Dattime", DateTime.Now);
                        cmd.Parameters.AddWithValue("@Votes", votes);
                        cmd.Parameters.AddWithValue("@Recipt", reciptPath);
                        cmd.ExecuteNonQuery();
                    }
                }

                // Success message
                string successScript = @"
                    Swal.fire({
                        icon: 'success',
                        title: 'تم الحفظ بنجاح!',
                        text: 'تم إرسال البيانات بنجاح.',
                        confirmButtonText: 'إغلاق'
                    }).then(() => {
                        document.getElementById('" + form1.ClientID + @"').reset();
                        document.getElementById('fileNameDisplay').textContent = 'لم يتم اختيار أي ملف';
                        const img = document.getElementById('previewImg');
                        if (img) img.classList.add('d-none');
                    });
                ";
                ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString(), successScript, true);

                ClearFields();
            }
            catch (Exception ex)
            {
                ShowAlert("خطأ أثناء الحفظ", ex.Message.Replace("'", ""), "error");
            }
        }

        // === Helpers ===
        private static string NormalizeKey(string input)
        {
            if (string.IsNullOrWhiteSpace(input)) return string.Empty;
            string s = input.Trim();
            s = s.Replace("\u200E", "").Replace("\u200F", "").Replace("\u061C", "").Replace("\u0640", "");
            s = s.Replace('\u00A0', ' ');
            s = Regex.Replace(s, @"\s+", "");
            return s.ToLowerInvariant();
        }

        private static char MapToAsciiDigit(char ch)
        {
            if (ch >= '0' && ch <= '9') return ch;
            if (ch >= '\u0660' && ch <= '\u0669') return (char)('0' + (ch - '\u0660')); // Arabic
            if (ch >= '\u06F0' && ch <= '\u06F9') return (char)('0' + (ch - '\u06F0')); // Persian
            return '\0';
        }

        private static string ToAsciiDigitsOnly(string input)
        {
            if (string.IsNullOrEmpty(input)) return string.Empty;
            var toSkip = new[] { '\u200E', '\u200F', '\u061C', '\u066C', '\u066B', ',', ' ', '\u00A0' };
            var sb = new StringBuilder(input.Length);
            foreach (var ch in input)
            {
                if (toSkip.Contains(ch)) continue;
                var mapped = MapToAsciiDigit(ch);
                if (mapped != '\0')
                    sb.Append(mapped);
                else if (char.IsDigit(ch))
                    sb.Append(ch);
            }
            return sb.ToString();
        }

        private void CompressAndSaveImage(HttpPostedFile file, string savePath, int maxWidth, int quality)
        {
            using (var srcImage = Image.FromStream(file.InputStream))
            {
                int newWidth = srcImage.Width;
                int newHeight = srcImage.Height;

                if (srcImage.Width > maxWidth)
                {
                    newWidth = maxWidth;
                    newHeight = (int)(srcImage.Height * (maxWidth / (float)srcImage.Width));
                }

                using (var newImage = new Bitmap(newWidth, newHeight))
                {
                    using (var g = Graphics.FromImage(newImage))
                    {
                        g.CompositingQuality = CompositingQuality.HighQuality;
                        g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                        g.SmoothingMode = SmoothingMode.HighQuality;
                        g.DrawImage(srcImage, 0, 0, newWidth, newHeight);
                    }

                    var jpegEncoder = ImageCodecInfo.GetImageDecoders().First(c => c.FormatID == ImageFormat.Jpeg.Guid);
                    var encParams = new EncoderParameters(1);
                    encParams.Param[0] = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, quality);
                    newImage.Save(savePath, jpegEncoder, encParams);
                }
            }
        }

        private string MakeSafeFilePart(string input)
        {
            foreach (var c in Path.GetInvalidFileNameChars())
                input = input.Replace(c, '-');
            return input.Replace(" ", "-");
        }

        private void ShowAlert(string title, string text, string icon)
        {
            string script = $@"
                Swal.fire({{
                    title: '{title}',
                    text: '{text}',
                    icon: '{icon}',
                    confirmButtonText: 'حسنًا'
                }});";
            ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString(), script, true);
        }

        private void ClearFields()
        {
            txtName.Text = txtCenter.Text = txtStation.Text = txtBox.Text = txtVotes.Text = "";
        }
    }
}
