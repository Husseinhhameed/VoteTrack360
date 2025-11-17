using System;
using System.Configuration;
using System.Data.SqlClient;
using System.Text;
using System.Web;
using System.Web.Services;
using System.Web.Script.Services;
using System.Web.UI;

namespace Election
{
    [ScriptService]
    public partial class dashboard : Page
    {
        protected void Page_Load(object sender, EventArgs e) { }

        public class DashboardData
        {
            public int TotalVotes { get; set; }
            public int TotalBoxes { get; set; }
            public int LastMaxId { get; set; }
            public string LastEntryTime { get; set; }
            public string TableRowsHtml { get; set; }
            public string Top5Html { get; set; }
        }

        [WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json, UseHttpGet = false)]
        public static DashboardData GetDashboardData(string nameFilter, string centerFilter)
        {
            var data = new DashboardData();
            string cs = ConfigurationManager.ConnectionStrings["ObservConn"].ConnectionString;

            try
            {
                using (SqlConnection conn = new SqlConnection(cs))
                {
                    conn.Open();

                    // ===== 1. Totals =====
                    using (SqlCommand cmd = new SqlCommand(@"
                        SELECT 
                            ISNULL(SUM(Votes),0) AS TotalVotes,
                            COUNT(*) AS TotalBoxes, 
                            ISNULL(MAX(Id),0) AS LastMaxId,
                            (SELECT TOP 1 Dattime FROM Obsrvt ORDER BY Dattime DESC) AS LastEntryTime
                        FROM Obsrvt;", conn))
                    using (SqlDataReader r = cmd.ExecuteReader())
                    {
                        if (r.Read())
                        {
                            data.TotalVotes = Convert.ToInt32(r["TotalVotes"]);
                            data.TotalBoxes = Convert.ToInt32(r["TotalBoxes"]);
                            data.LastMaxId = Convert.ToInt32(r["LastMaxId"]);
                            data.LastEntryTime = r["LastEntryTime"] == DBNull.Value
                                ? "—"
                                : Convert.ToDateTime(r["LastEntryTime"]).ToString("yyyy-MM-dd HH:mm");
                        }
                    }

                    // ===== 2. Main Table =====
                    using (SqlCommand cmd = new SqlCommand(@"
                        SELECT TOP 300 Id, Name, Center, Station, Box, Votes, Dattime, Recipt 
                        FROM Obsrvt
                        WHERE (@Name='' OR Name LIKE '%' + @Name + '%')
                          AND (@Center='' OR Center LIKE '%' + @Center + '%')
                        ORDER BY Dattime DESC;", conn))
                    {
                        cmd.Parameters.AddWithValue("@Name", nameFilter ?? "");
                        cmd.Parameters.AddWithValue("@Center", centerFilter ?? "");

                        using (SqlDataReader rd = cmd.ExecuteReader())
                        {
                            var sb = new StringBuilder();
                            while (rd.Read())
                            {
                                int id = Convert.ToInt32(rd["Id"]);
                                string name = rd["Name"] as string ?? "";
                                string center = rd["Center"] as string ?? "";
                                string station = rd["Station"]?.ToString() ?? "";
                                string box = rd["Box"]?.ToString() ?? "";
                                int votes = rd["Votes"] == DBNull.Value ? 0 : Convert.ToInt32(rd["Votes"]);
                                DateTime dt = rd["Dattime"] == DBNull.Value ? DateTime.MinValue : Convert.ToDateTime(rd["Dattime"]);
                                string imgPath = rd["Recipt"] as string ?? "";

                                string normalizedImg = "";
                                if (!string.IsNullOrWhiteSpace(imgPath))
                                {
                                    if (imgPath.StartsWith("~") || imgPath.StartsWith("/"))
                                        normalizedImg = VirtualPathUtility.ToAbsolute(imgPath);
                                    else
                                        normalizedImg = "/Uploads/Recipts/" + imgPath.TrimStart('/', '\\');
                                }

                                sb.AppendFormat("<tr data-id='{0}' data-img='{1}' data-votes='{2}'>",
                                    id, HttpUtility.HtmlAttributeEncode(normalizedImg), votes);
                                sb.AppendFormat("<td>{0}</td>", HttpUtility.HtmlEncode(name));
                                sb.AppendFormat("<td>{0}</td>", HttpUtility.HtmlEncode(center));
                                sb.AppendFormat("<td>{0}</td>", HttpUtility.HtmlEncode(station));
                                sb.AppendFormat("<td>{0}</td>", HttpUtility.HtmlEncode(box));
                                sb.AppendFormat("<td>{0}</td>", votes);
                                sb.AppendFormat("<td>{0:yyyy-MM-dd HH:mm}</td>", dt);
                                sb.Append("</tr>");
                            }

                            data.TableRowsHtml = sb.Length > 0
                                ? sb.ToString()
                                : "<tr><td colspan='6'>لا توجد نتائج مطابقة</td></tr>";
                        }
                    }

                    // ===== 3. Top 5 =====
                    using (SqlCommand cmd = new SqlCommand(@"
                        SELECT TOP 5 Center, Station, Box, Votes 
                        FROM Obsrvt 
                        ORDER BY Votes DESC;", conn))
                    using (SqlDataReader rd = cmd.ExecuteReader())
                    {
                        var sbTop = new StringBuilder();
                        while (rd.Read())
                        {
                            sbTop.Append("<tr>");
                            sbTop.AppendFormat("<td>{0}</td>", HttpUtility.HtmlEncode(rd["Center"]));
                            sbTop.AppendFormat("<td>{0}</td>", HttpUtility.HtmlEncode(rd["Station"]));
                            sbTop.AppendFormat("<td>{0}</td>", HttpUtility.HtmlEncode(rd["Box"]));
                            sbTop.AppendFormat("<td><b>{0}</b></td>", rd["Votes"]);
                            sbTop.Append("</tr>");
                        }

                        data.Top5Html = sbTop.Length > 0
                            ? sbTop.ToString()
                            : "<tr><td colspan='4'>لا توجد بيانات</td></tr>";
                    }
                }
            }
            catch (Exception ex)
            {
                data.TableRowsHtml = $"<tr><td colspan='6' style='color:#b00020'>⚠ Error: {HttpUtility.HtmlEncode(ex.Message)}</td></tr>";
                data.Top5Html = "<tr><td colspan='4'>—</td></tr>";
            }

            return data;
        }

        // ✅ Inline update method
        [WebMethod]
        [ScriptMethod(ResponseFormat = ResponseFormat.Json, UseHttpGet = false)]
        public static string UpdateBoxData(string id, string center, string station, string box, string votes)
        {
            string cs = ConfigurationManager.ConnectionStrings["ObservConn"].ConnectionString;
            try
            {
                using (SqlConnection conn = new SqlConnection(cs))
                {
                    conn.Open();
                    using (SqlCommand cmd = new SqlCommand(@"
                        UPDATE Obsrvt
                        SET Center=@Center, Station=@Station, Box=@Box, Votes=@Votes
                        WHERE Id=@Id", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", Convert.ToInt32(id));
                        cmd.Parameters.AddWithValue("@Center", center ?? "");
                        cmd.Parameters.AddWithValue("@Station", station ?? "");
                        cmd.Parameters.AddWithValue("@Box", box ?? "");
                        cmd.Parameters.AddWithValue("@Votes", Convert.ToInt32(votes));
                        cmd.ExecuteNonQuery();
                    }
                }
                return "ok";
            }
            catch (Exception ex)
            {
                return "error: " + ex.Message;
            }
        }
    }
}
