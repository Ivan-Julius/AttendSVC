using System;
using System.Data;
using System.Data.SqlClient;
using log4net;
using MiniFramework.Configuration;

namespace AbsenApp
{
    public class Logs
    {
        private static string ConnectionString = System.Configuration.ConfigurationManager.ConnectionStrings["TKPAbsen"].ConnectionString;
        private static ILog log = LogManager.GetLogger(typeof(Surogate));
        private static string className = "Logs";
         
        public string mac;
        public DateTime logdate;
        public string message;
        public string stacktrace;
        public DateTime timestamp;
        public string username;
           
        public static void LocalLogRetrieval(string logs, string mac, string ip)
        {            
            string methodName = "LocalLogRetreival()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");

            try
            {   using (SqlConnection conn = new SqlConnection(ConnectionString))
                {
                    using (SqlCommand cmd = new SqlCommand("insertLocalLogs", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.Parameters.Add("@logs", SqlDbType.VarChar).SqlValue = logs;
                        cmd.Parameters.Add("@Mac", SqlDbType.VarChar).SqlValue = mac;
                        cmd.Parameters.Add("@ip_Address", SqlDbType.VarChar).SqlValue = ip;                        
                        conn.Open();

                        using (SqlDataReader reader = cmd.ExecuteReader(CommandBehavior.CloseConnection)) { }
                        conn.Close();
                    }
                }
            }
            catch (Exception ex)
            {
                log.Error(ex);
            }

            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, "");

        }




    }
}