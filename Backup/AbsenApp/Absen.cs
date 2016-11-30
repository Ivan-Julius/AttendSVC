using System;
using System.Data;
using System.Data.SqlClient;

namespace AbsenApp
{
    public class Absen
    {
        private static string className = typeof(Absen).ToString();
        private static string ConnectionString = System.Configuration.ConfigurationManager.ConnectionStrings["TKPAbsen"].ConnectionString;

        private static double limit_latitude = -6.1902203;
        private static double limit_longitude = 106.7977057;
        private static int limit_distance = 1000;

        public string firstlogin { get; set; }

        public string lastlogin { get; set; }

        public bool isfull { get; set; }

        public bool isLate { get; set; }

        public int lateCount { get; set; }

        public int Login(string macAddress, string ipAddress, double longitude, double latitude)
        {
            string methodName = String.Format("Login({0},{1},{2},{3})", macAddress, ipAddress, longitude, latitude);
            LogHelper.DebugFormat("{0}.{1}: --- start ---", className, methodName);
            int result = 0;
            double distance = getDistance(latitude, longitude, limit_latitude, limit_longitude);
            if (distance <= limit_distance) 
            {
                result = Login(macAddress, ipAddress);
            }
            LogHelper.DebugFormat("{0}.{1}: --- end ---", className, methodName);
            return result;
        }

        private int Login(string macAddress, string ipAddress) 
        {
            string methodName = String.Format("Login({0},{1})", macAddress, ipAddress);
            LogHelper.DebugFormat("{0}.{1}: --- start ---", className, methodName);
            int result = 0;

            try
            {   
                using (SqlConnection conn = new SqlConnection(ConnectionString))
                {
                    conn.Open();
                    using (SqlCommand cmd = new SqlCommand("DoLogin", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.Parameters.Add("@mac", SqlDbType.VarChar).SqlValue = macAddress;
                        cmd.Parameters.Add("@ip_address", SqlDbType.VarChar).SqlValue = ipAddress;
                        result = cmd.ExecuteNonQuery();
                    }
                    conn.Close();
                }
            }
            catch (Exception ex)
            { 
                LogHelper.ErrorFormat("{0}.{1}: message ({2})", className, methodName, ex.Message);
            }

            LogHelper.DebugFormat("{0}.{1}: --- END ---", className, methodName);
            return result;
        }

        private double getDistance(double Lat1, double Lon1, double Lat2, double Lon2)
        {
            int R = 6371;

            double rLat1 = ToRadian(Lat1);
            double rLat2 = ToRadian(Lat2);

            double dLat = rLat2 - rLat1;
            double dLon = ToRadian(Lon2 - Lon1);

            double a = Math.Pow(Math.Sin(dLat / 2), 2) +
                Math.Pow(Math.Sin(dLon / 2), 2) *
                Math.Cos(rLat1) * Math.Cos(rLat2);

            double b = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));

            return R * b;
        }

        private static double ToRadian(double Grad)
        {
            return Math.PI * Grad / 180;
        }
    }
}