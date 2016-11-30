using System;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Net;
using log4net;


namespace AbsenApp
{
    public class HolidayFeed
    {
        private static string Connectionstring = System.Configuration.ConfigurationManager.ConnectionStrings["TKPAbsen"].ConnectionString;
        private static ILog log = LogManager.GetLogger(typeof(Surogate));
        private static string className = "HolidayFeed";

        public static void getFeed(string yr)
        {
            HttpWebRequest myRequest = (HttpWebRequest)WebRequest.Create("http://www.officeholidays.com/ics/ics_country.php?tbl_country=Indonesia");
            myRequest.Method = "GET";
            WebResponse myResponse = myRequest.GetResponse();
            StreamReader sr = new StreamReader(myResponse.GetResponseStream(), System.Text.Encoding.UTF8);
            string result = sr.ReadToEnd();
            sr.Close();
            myResponse.Close();

            string yrPlusOne = (int.Parse(yr) + 1).ToString();
            string[] x = result.Split(new string[] { "UID:" }, StringSplitOptions.None);

            foreach (var item in x)
            {
                string o = item.Substring(item.LastIndexOf("DESCRIPTION:") + 1);
                if (o.Contains(yr) || o.Contains(yrPlusOne))
                {
                    string[] data = item.Split(new string[] { Environment.NewLine }, StringSplitOptions.None);
                    string holidate = null;
                    string holiday = null;

                    foreach (var items in data)
                    {
                        if (items.Contains("DTSTART"))
                        {
                            string hDay = items.Substring(items.LastIndexOf(':') + 1);
                            holidate = hDay.Insert(4,"-").Insert(7,"-");
                        }
                        else if (items.Contains("SUMMARY"))
                        {
                            holiday = items.Substring(items.LastIndexOf(':') + 1);
                        }
                    }

                    if (holidate != null)
                    {
                        upHolidayFeed(Convert.ToDateTime(holidate), holiday);
                    }
                }
            }

          
        }

        public static int upHolidayFeed(DateTime holidate, string holiday)
        {
            string methodName = "upHolidayFeed()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");
            int result = 0;

            try
            {
                using (SqlConnection conn = new SqlConnection(Connectionstring))
                {
                    using (SqlCommand cmd = new SqlCommand("holidayFeed", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.Parameters.Add("@holidate", SqlDbType.DateTime).SqlValue = holidate;
                        cmd.Parameters.Add("@holiday", SqlDbType.VarChar).SqlValue = holiday;
                        conn.Open();

                        result = cmd.ExecuteNonQuery();
                        conn.Close();
                    }
                }
            }
            catch (Exception ex) { log.Error(ex); }

            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, "");
            return result;
        }



    }
}