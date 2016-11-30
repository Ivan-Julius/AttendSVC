using System;
using System.Data;
using System.Data.SqlClient;
using log4net;
using System.Web.Script.Serialization;

namespace AbsenApp
{
    public class Excuse
    {
        private static string ConnectionString = System.Configuration.ConfigurationManager.ConnectionStrings["TKPAbsen"].ConnectionString;
        private static ILog log = LogManager.GetLogger(typeof(Excuse));
        private static string className = "Excuse";

        public string from_date { get; set; }

        public string to_date { get; set; }

        public string excuse_type { get; set; }

        public string excuse_reason { get; set; }

        public string owner { get; set; }

        public int excuse_id { get; set; }

        public string mac_id { get; set; }

        public string approved { get; set; }

        public string logdate { get; set; }

        public static string approveExcuse(string mac, string pass, string excuse_id, string approve, string ip)
        {
            string methodName = "approvePermit()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");

            string result = "";

            using (SqlConnection conn = new SqlConnection(ConnectionString))
            {
                using (SqlCommand cmd = new SqlCommand("excuseApproval", conn))
                {
                    cmd.Parameters.Add("@excuse_id", SqlDbType.VarChar).SqlValue = excuse_id;
                    cmd.Parameters.Add("@ip", SqlDbType.VarChar).SqlValue = ip;
                    cmd.Parameters.Add("@mac", SqlDbType.VarChar).SqlValue = mac;
                    cmd.Parameters.Add("@pass", SqlDbType.VarChar).SqlValue = pass;
                    cmd.Parameters.Add("@approval", SqlDbType.VarChar).SqlValue = approve;

                    log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, excuse_id.ToString() + "," + mac + "," + ip + "," + approve.ToString());

                    SqlParameter x = new SqlParameter();
                    x.ParameterName = "@res";
                    x.SqlDbType = SqlDbType.VarChar;
                    x.Size = 250;
                    x.Direction = ParameterDirection.Output;
                    cmd.Parameters.Add(x);

                    cmd.CommandType = CommandType.StoredProcedure;
                    conn.Open();

                    cmd.UpdatedRowSource = UpdateRowSource.OutputParameters;
                    cmd.ExecuteNonQuery();
                    
                    result = (string)cmd.Parameters["@res"].Value;
                    conn.Close();                    
                }
            }

            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, result);

            return result;
        }


        public static string insertExcuse(string mac, DateTime from_date, DateTime to_date, string reason, int type_id, String latitude, String longitude)
        {
            string methodName = "insertExcuse()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");

            string result = "";

            using (SqlConnection conn = new SqlConnection(ConnectionString))
            {
                using (SqlCommand cmd = new SqlCommand("insertExcuse", conn))
                {
                    cmd.Parameters.Add("@mac", SqlDbType.VarChar).SqlValue = mac;
                    cmd.Parameters.Add("@from_date", SqlDbType.DateTime).SqlValue = from_date;
                    cmd.Parameters.Add("@to_date", SqlDbType.DateTime).SqlValue = to_date;
                    cmd.Parameters.Add("@reason", SqlDbType.VarChar).SqlValue = reason;
                    cmd.Parameters.Add("@type_id", SqlDbType.Int).SqlValue = type_id;
                    cmd.Parameters.Add("@sender_latitude", SqlDbType.VarChar).SqlValue = latitude;
                    cmd.Parameters.Add("@sender_longitude", SqlDbType.VarChar).SqlValue = longitude;

                    SqlParameter x = new SqlParameter();
                    x.ParameterName = "@Pass";
                    x.SqlDbType = SqlDbType.VarChar;
                    x.Size = 250;
                    x.Direction = ParameterDirection.Output;
                    cmd.Parameters.Add(x);

                    cmd.CommandType = CommandType.StoredProcedure;
                    conn.Open();

                    cmd.UpdatedRowSource = UpdateRowSource.OutputParameters;
                    cmd.ExecuteNonQuery();

                    result = (string)cmd.Parameters["@Pass"].Value;

                    conn.Close();
                }
            }

            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, result);
            return result;
        }
    }
}