using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using log4net;
using System.Web.Script.Serialization;

namespace AbsenApp
{
    public class Retriever
    {
        private static string ConnectionString = System.Configuration.ConfigurationManager.ConnectionStrings["TKPAbsen"].ConnectionString;
        private static ILog log = LogManager.GetLogger(typeof(Excuse));
        private static string className = "Retriever";

        public static string pendingApproval(string macAdds, DateTime from_date, DateTime to_date, string approve, string reason_type)
        {
            string methodName = "pendingApproval()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, from_date +","+to_date);

            List<Excuse> excuseList = new List<Excuse>();

            string Approvals = "";
            try
            {   using (SqlConnection conn = new SqlConnection(ConnectionString))
                {
                    using (SqlCommand cmd = new SqlCommand("getPendingExcuse", conn))
                    {
                       
                        if (macAdds != "")
                        {
                            cmd.Parameters.Add("@selectedMacString", SqlDbType.VarChar).SqlValue = macAdds;
                        }
                        else {
                            cmd.Parameters.AddWithValue("@selectedMacString", DBNull.Value);
                        }

                        cmd.Parameters.Add("@from", SqlDbType.DateTime).SqlValue = from_date;
                        cmd.Parameters.Add("@to", SqlDbType.DateTime).SqlValue = to_date;
                        cmd.Parameters.Add("@type", SqlDbType.VarChar).SqlValue = approve;
                        cmd.Parameters.Add("@excuse_type", SqlDbType.VarChar).SqlValue = reason_type;

                        cmd.CommandType = CommandType.StoredProcedure;
                        conn.Open();

                        using (SqlDataReader reader = cmd.ExecuteReader(CommandBehavior.CloseConnection))
                        {
                            Excuse x;
                            while (reader.Read())
                            {
                                x = new Excuse();
                                x.excuse_id = ((int)reader["id"]);
                                x.from_date = ((DateTime)reader["from_Date"]).ToString();
                                x.to_date = ((DateTime)reader["to_Date"]).ToString();
                                x.excuse_type = reader["type"].ToString();
                                x.excuse_reason = (string)reader["excuse_reason"];
                                x.approved = (string)reader["approved"];
                                x.logdate = ((DateTime)reader["createdate"]).ToString();
                                x.owner = (string)reader["name"];
                            
                                excuseList.Add(x);
                            }
                            
                        }
                        conn.Close();
                    }
                }
            }
            catch (Exception ex)
            {
                log.Error(ex);
            }

            Approvals = new JavaScriptSerializer().Serialize(excuseList);

            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, Approvals);
            return Approvals;
        }

        public static string RetrieveLoginData(string mac, string ip)
        {
            string methodName = "RetrieveLoginData()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");

            string loginData = "";
            Absen x = new Absen();

            try
            {   using (SqlConnection conn = new SqlConnection(ConnectionString))
                {
                    using (SqlCommand cmd = new SqlCommand("getUserLoginInformation", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.Parameters.Add("@mac", SqlDbType.VarChar).SqlValue = mac;
                        cmd.Parameters.Add("@ip_address", SqlDbType.VarChar).SqlValue = ip;
                        conn.Open();

                        using (SqlDataReader reader = cmd.ExecuteReader(CommandBehavior.CloseConnection))
                        {
                            log.DebugFormat("------------DATA---{0}-{1}-({2})-----------", className, methodName, reader.HasRows.ToString());
                            while (reader.Read())
                            {
                                x.firstlogin = ((DateTime)reader["first_login"]).ToString();
                                x.lastlogin = ((DateTime)reader["last_login"]).ToString();
                                x.isfull = ((Int16)reader["is_full"] == 1)? true : false;
                                x.lateCount = (int)reader["late_count"];
                                x.isLate = ((Int16)reader["is_late"] == 1) ? true : false;
                            }
                        }
                        conn.Close();
                    }
                }
            }
            catch (Exception ex) { log.Error(ex); }

            loginData = new JavaScriptSerializer().Serialize(x);
            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, "");
            return loginData;
        }


        public static string getAllExcuseType() {

            string methodName = "getAllExcuseType()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");

            string result = "";
            ExcuseType x = new ExcuseType();

            try
            {
                using (SqlConnection conn = new SqlConnection(ConnectionString))
                {
                    using (SqlCommand cmd = new SqlCommand("getExucesTypes", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        conn.Open();

                        using (SqlDataReader reader = cmd.ExecuteReader(CommandBehavior.CloseConnection))
                        {
                            log.DebugFormat("------------DATA---{0}-{1}-({2})-----------", className, methodName, reader.HasRows.ToString());
                            while (reader.Read())
                            {
                                x.excuse_id = (int)reader["id"];
                                x.excuse_type = (string)reader["typeName"];
                            }
                        }
                        conn.Close();
                    }
                }
            }
            catch (Exception ex) { log.Error(ex); }

            result = new JavaScriptSerializer().Serialize(x);
            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, "");
            return result;        
        }

        public static string getDailyReport(string mac, DateTime from, DateTime to, string mac_list, string type_list, string status_list)
        {
            string methodName = "getDailyReport()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");

            string result = "";
            List<DailyReport> xx = new List<DailyReport>();
            int count = to.Subtract(from).Days;

            log.DebugFormat("------------START---{0}-{1}-({2})--({3})--({4})------", className, methodName, to.ToString(), from.ToString(), count);
          
            try
            {
                using (SqlConnection conn = new SqlConnection(ConnectionString))
                {
                    using (SqlCommand cmd = new SqlCommand("getReportDaily", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.Parameters.Add("@mac", SqlDbType.VarChar).SqlValue = mac;
                        cmd.Parameters.Add("@from_date", SqlDbType.DateTime).SqlValue = from;
                        cmd.Parameters.Add("@to_date", SqlDbType.DateTime).SqlValue = to;
                        cmd.Parameters.Add("@mac_list", SqlDbType.VarChar).SqlValue = mac_list;
                        cmd.Parameters.Add("@type_list", SqlDbType.VarChar).SqlValue = type_list;
                        cmd.Parameters.Add("@statusFilter", SqlDbType.VarChar).SqlValue = status_list;
                        conn.Open();

                        using (SqlDataReader reader = cmd.ExecuteReader(CommandBehavior.CloseConnection))
                        {

                            DailyReport x;
                      
                            while(reader.Read()){
                         
                                log.DebugFormat("------------DATA---{0}-{1}-({2})-----------", className, methodName, xx.Count);

                                x = new DailyReport();

                                x.name = (string)reader["user_name"];
                                x.first_login = ((DateTime)reader["first_login"]).ToString();
                                x.last_login = ((DateTime)reader["last_login"]).ToString();
                                x.logout_time = ((DateTime)reader["logout_time"]).ToString();
                                x.login_elapse_time = ((int)reader["login_elapse_time"]).ToString();
                                x.start_overtime = ((DateTime)reader["start_overtime"]).ToString();
                                x.overtime_elapse_time = ((int)reader["overtime_elapse_time"]).ToString();
                                x.is_late = ((Int16)reader["is_late"] == 1) ? true : false;
                                x.is_full = ((Int16)reader["is_full"] == 1) ? true : false;
                                x.login_type = (string)reader["login_type"];

                                xx.Add(x);
                            } 
                            
                        }
                        conn.Close();
                    }
                } 
            }
            catch (Exception ex) { log.Error(ex); }

            log.DebugFormat("------------DATA---{0}-{1}-({2})-----------", className, methodName, xx.Count);
                          
            result = new JavaScriptSerializer().Serialize(xx);
            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, "");
            return result;
        }

        public static string getMonthlyReport(string mac , DateTime from, DateTime to, string mac_list)
        { 

            string methodName = "getMonthlyReport()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");

            string result = "";
            List<MonthlyReport> xx = new List<MonthlyReport>();
           
            try
            {
                using (SqlConnection conn = new SqlConnection(ConnectionString))
                {
                    using (SqlCommand cmd = new SqlCommand("getReportMonthly", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.Parameters.Add("@mac", SqlDbType.VarChar).SqlValue = mac;
                        cmd.Parameters.Add("@from_date", SqlDbType.DateTime).SqlValue = from;
                        cmd.Parameters.Add("@to_date", SqlDbType.DateTime).SqlValue = to;
                        cmd.Parameters.Add("@mac_list", SqlDbType.VarChar).SqlValue = mac_list;
                        conn.Open();

                        using (SqlDataReader reader = cmd.ExecuteReader(CommandBehavior.CloseConnection))
                        {
                            MonthlyReport x;
            
                            log.DebugFormat("------------DATA---{0}-{1}-({2})-----------", className, methodName, reader.HasRows.ToString());
                            while (reader.Read())
                            {
                                x = new MonthlyReport();

                                x.user_id = ((int)reader["user_id"]).ToString();
                                x.name = (string)reader["name"];
                                x.report_year = ((int)reader["report_year"]).ToString();
                                x.report_month = ((int)reader["report_month"]).ToString();
                                x.count_late = ((int)reader["count_late"]).ToString();
                                x.count_not_full = ((int)reader["count_not_full"]).ToString();
                                x.count_full = ((int)reader["count_full"]).ToString();
                                x.count_sick = ((int)reader["count_sick"]).ToString();
                                x.count_leave = ((int)reader["count_leave"]).ToString();
                                x.count_AllowedLate = ((int)reader["count_AllowedLate"]).ToString();
                                x.count_earlyLeave = ((int)reader["count_earlyLeave"]).ToString();
                                x.count_not_login = ((int)reader["count_not_login"]).ToString();
                                x.count_login = ((int)reader["count_login"]).ToString();
                                x.total_login = ((int)reader["total_login"]).ToString();
                                x.overtime_elapse_time = (reader["overtime_elapse_time"]).ToString();
                                x.login_elapse_time = (reader["login_elapse_time"]).ToString();

                                xx.Add(x);
                            }
                        }
                        conn.Close();
                    }
                }
            }
            catch (Exception ex) { log.Error(ex); }

            result = new JavaScriptSerializer().Serialize(xx);
            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, xx.ToString());
            return result;
        }


        public static string getDeviceLog(string mac_list, DateTime from, DateTime to)
        {

            string methodName = "getDeviceLog()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");

            string result = "";
            Logs x = new Logs();

            try
            {

                using (SqlConnection conn = new SqlConnection(ConnectionString))
                {
                    using (SqlCommand cmd = new SqlCommand("getDeviceLog", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                       
                        cmd.Parameters.Add("@from_date", SqlDbType.DateTime).SqlValue = from;
                        cmd.Parameters.Add("@to_date", SqlDbType.DateTime).SqlValue = to;
                        cmd.Parameters.Add("@mac_list", SqlDbType.VarChar).SqlValue = mac_list;
                        conn.Open();

                        using (SqlDataReader reader = cmd.ExecuteReader(CommandBehavior.CloseConnection))
                        {
                            log.DebugFormat("------------DATA---{0}-{1}-({2})-----------", className, methodName, reader.HasRows.ToString());
                            while (reader.Read())
                            {
                                x.mac = (string)reader["mac"];
                                x.username = (string)reader["name"];
                                x.logdate = (DateTime)reader["logdate"];
                                x.message = (string)reader["message"];
                                x.stacktrace = (string)reader["stacktrace"];
                                x.timestamp = (DateTime)reader["timestamp"];
                              
                            }
                        }
                        conn.Close();
                    }
                }
            }
            catch (Exception ex) { log.Error(ex); }

            result = new JavaScriptSerializer().Serialize(x);
            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, "");
            return result;
        }


        public static string getUsersMacs(string mac)
        {
            string methodName = "getUsersMacs()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");

            string result = "";

            List<users> xx = new List<users>();
            
            try
            {
                using (SqlConnection conn = new SqlConnection(ConnectionString))
                {
                    using (SqlCommand cmd = new SqlCommand("getUserList", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;

                        cmd.Parameters.Add("@mac", SqlDbType.VarChar).SqlValue = mac;

                        users x;
                        conn.Open();

                        using (SqlDataReader reader = cmd.ExecuteReader(CommandBehavior.CloseConnection))
                        {
                            log.DebugFormat("------------DATA---{0}-{1}-({2})-----------", className, methodName, reader.HasRows.ToString());
                            while (reader.Read())
                            {
                                x = new users();
                                x.mac = (string)reader["mac"];
                                x.username = (string)reader["name"];

                                xx.Add(x);
                            }
                        }
                        conn.Close();
                    }
                }
            }
            catch (Exception ex) { log.Error(ex); }

            result = new JavaScriptSerializer().Serialize(xx);
            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, "");
            return result;

        }

        public static string updatePassword(string mac, string old_pass, string new_pass)
        {
            string methodName = "insertPassword()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");

            string result = "";

             using (SqlConnection conn = new SqlConnection(ConnectionString))
            {
                using (SqlCommand cmd = new SqlCommand("updatePassword", conn))
                {
                    cmd.Parameters.Add("@mac", SqlDbType.VarChar).SqlValue = mac;
                    cmd.Parameters.Add("@old_password", SqlDbType.VarChar).SqlValue = old_pass;
                    cmd.Parameters.Add("@new_password", SqlDbType.VarChar).SqlValue = new_pass;
             

                    SqlParameter x = new SqlParameter();
                    x.ParameterName = "@result";
                    x.SqlDbType = SqlDbType.VarChar;
                    x.Size = 250;
                    x.Direction = ParameterDirection.Output;
                    cmd.Parameters.Add(x);

                    cmd.CommandType = CommandType.StoredProcedure;
                    conn.Open();

                    cmd.UpdatedRowSource = UpdateRowSource.OutputParameters;
                    cmd.ExecuteNonQuery();

                    result = (string)cmd.Parameters["@result"].Value;

                    conn.Close();
                }
            }

            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, "");
            return result;

        }

        public static string resetPassword(string mac)
        {
            string methodName = "resetPassword()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");

            string result = "";

            using (SqlConnection conn = new SqlConnection(ConnectionString))
            {
                using (SqlCommand cmd = new SqlCommand("resetPassword", conn))
                {
                    cmd.Parameters.Add("@mac", SqlDbType.VarChar).SqlValue = mac;
                   

                    SqlParameter x = new SqlParameter();
                    x.ParameterName = "@result";
                    x.SqlDbType = SqlDbType.VarChar;
                    x.Size = 250;
                    x.Direction = ParameterDirection.Output;
                    cmd.Parameters.Add(x);

                    cmd.CommandType = CommandType.StoredProcedure;
                    conn.Open();

                    cmd.UpdatedRowSource = UpdateRowSource.OutputParameters;
                    cmd.ExecuteNonQuery();

                    result = (string)cmd.Parameters["@result"].Value;

                    conn.Close();
                }
            }

            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, "");
            return result;

        }



        public static bool allAccess(string mac)
        {
            string methodName = "allAccess()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");

            bool result = false;

            using (SqlConnection conn = new SqlConnection(ConnectionString))
            {
                using (SqlCommand cmd = new SqlCommand("getHasVerificationRights", conn))
                {
                    cmd.Parameters.Add("@mac", SqlDbType.VarChar).SqlValue = mac;

                    SqlParameter x = new SqlParameter();
                    x.ParameterName = "@result";
                    x.SqlDbType = SqlDbType.VarChar;
                    x.Size = 250;
                    x.Direction = ParameterDirection.Output;
                    cmd.Parameters.Add(x);

                    cmd.CommandType = CommandType.StoredProcedure;
                    conn.Open();

                    cmd.UpdatedRowSource = UpdateRowSource.OutputParameters;
                    cmd.ExecuteNonQuery();

                    result = (((string)cmd.Parameters["@result"].Value) == "true");

                    conn.Close();
                }
            }

            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, "");
            return result;

        }

        public static string getWifiList(string mac)
        {
            string methodName = "getUsersMacs()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");

            string result = "";

            try
            {
                using (SqlConnection conn = new SqlConnection(ConnectionString))
                {
                    using (SqlCommand cmd = new SqlCommand("getBssidAndSsidList", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        
                        cmd.Parameters.Add("@mac", SqlDbType.VarChar).SqlValue = mac;
                        conn.Open();

                       
                        using (SqlDataReader reader = cmd.ExecuteReader(CommandBehavior.CloseConnection))
                        {
                            log.DebugFormat("------------DATA---{0}-{1}-({2})-----------", className, methodName, reader.HasRows.ToString());
                            int counter = 0;
                            while (reader.Read())
                            {
                                if(counter > 0){
                                    result = result + "|";
                                }
                                result = result + (string)reader["ssidAndBssid"];

                                counter++;
                            }
                        }
                        conn.Close();
                    }
                }
            }
            catch (Exception ex) { log.Error(ex); }

            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, result);
            return result;

        }

    }
}