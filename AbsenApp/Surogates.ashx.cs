using System;
using System.Web;
using log4net;
using System.Globalization;

namespace AbsenApp
{
    public class Surogates : IHttpHandler
    {
        private static string className = typeof(Surogates).ToString();
        private static ILog log = LogManager.GetLogger(typeof(Excuse));


        #region IHttpHandler Members

        public bool IsReusable
        {
            // Return false in case your Managed Handler cannot be reused for another request.
            // Usually this would be false in case you have some state information preserved per request.
            get { return true; }
        }

        public void ProcessRequest(HttpContext context)
        {
            //write your handler implementation here.
            string methodName = "ProcessRequest()";
            LogHelper.DebugFormat("{0}.{1}:--- start ---", className, methodName);

            log.DebugFormat("{0}.{1}:--- start ---", className, methodName);

            if (context.Request.Params.Count > 0)
            {
                LogHelper.DebugFormat("{0}.{1}: params count ({2})", className, methodName, context.Request.Params.Count.ToString());
                string method = context.Request.Params["method"];
                string result = "";
                if (!string.IsNullOrEmpty(method))
                {
                    LogHelper.DebugFormat("{0}.{1}: method ({2})", className, methodName, method);
                    result = switchMethod(context, method);
                    context.Response.ContentType = "text/html";
                    context.Response.Write(result);
                }
            }
            LogHelper.DebugFormat("{0}.{1}:--- end ---", className, methodName);
            context.Response.Flush();
            context.Response.End();
        }


        private string switchMethod(HttpContext context, string method)
        {
            string methodName = string.Format("switchMethod({0})", method);
            LogHelper.DebugFormat("{0}.{1}:--- start ---", className, methodName);

            log.DebugFormat("{0}.{1}:--- start ---", className, methodName);

            string mac = context.Request.Params["mac"];
            string ip = getUserIP(context.Request);
            string longitude = context.Request.Params["lon"];
            string latitude = context.Request.Params["lat"];
            string logs = context.Request.Params["logs"];
            string from_date = context.Request.Params["from_date"];
            string to_date = context.Request.Params["to_date"];
            string excuse_id = context.Request.Params["excuse_id"];
            string approve = context.Request.Params["approve"];
            string reason = context.Request.Params["reason"];
            string reason_type = context.Request.Params["reason_type"];
            string entry_date = context.Request.Params["entry_date"];
            string mac_list = context.Request.Params["mac_list"];
            string type_list = context.Request.Params["type_list"];
            string year = context.Request.Params["holiday_year"];
            string pass = context.Request.Params["pass"];
            string new_pass = context.Request.Params["new_pass"];
            string status_list = context.Request.Params["status_list"];
            string result = "";


            log.DebugFormat("{0}.{1}:--- {2} {3} {4} {5} {6} ---", className, methodName, mac, from_date, to_date, reason, reason_type);

            switch (method)
            {
                case "0": //MoveDeviceLog
                    if (!(string.IsNullOrEmpty(mac) && string.IsNullOrEmpty(ip) && string.IsNullOrEmpty(logs)))
                    {
                        moveDeviceLog(mac, ip, logs);
                    }
                    break;
                case "1": //RetrieveExcuse
                    if (!(string.IsNullOrEmpty(mac_list) && string.IsNullOrEmpty(from_date) && string.IsNullOrEmpty(to_date) && string.IsNullOrEmpty(approve) && string.IsNullOrEmpty(reason_type)))
                    {
                        result = retrieveExcuse(mac_list, from_date, to_date, approve, reason_type);
                    }
                    break;
                case "2": //ApproveExcuse
                    if (!(string.IsNullOrEmpty(mac) && string.IsNullOrEmpty(ip) && string.IsNullOrEmpty(excuse_id) && string.IsNullOrEmpty(approve) ))
                    {
                        result = approveExcuse(mac, excuse_id, approve, ip);
                    }
                    break;
                case "3": //Login
                    if (!(string.IsNullOrEmpty(mac) && string.IsNullOrEmpty(ip) && string.IsNullOrEmpty(longitude) && string.IsNullOrEmpty(latitude)))
                    {
                        result = login(ip, mac, longitude, latitude);
                    }
                    break;
                case "4": //insertExcuse
                    if (!(string.IsNullOrEmpty(mac) && string.IsNullOrEmpty(from_date) && string.IsNullOrEmpty(to_date) && string.IsNullOrEmpty(reason) && string.IsNullOrEmpty(reason_type)))
                    {
                        result = insertExcuse(mac, from_date, to_date, reason, reason_type, latitude, longitude);
                    }
                    break;
                case "5": //getExcuseTypes
                    result = getExcuseTypes();
                    break;
                case "6": //DailyReport
                    if (!(string.IsNullOrEmpty(mac) && string.IsNullOrEmpty(from_date) && string.IsNullOrEmpty(to_date) && string.IsNullOrEmpty(mac_list) && string.IsNullOrEmpty(type_list) && string.IsNullOrEmpty(status_list)))
                    {
                        result = getDailyReport(mac, from_date, to_date, mac_list, type_list, status_list);
                    }
                    break;
                case "7": //MonthlyReport
                    if (!(string.IsNullOrEmpty(mac) && string.IsNullOrEmpty(from_date) && string.IsNullOrEmpty(to_date) && string.IsNullOrEmpty(mac_list)))
                    {
                        result = getMonthlyReport(mac, from_date, to_date, mac_list);
                    }
                    break;
                case "8": //getDeviceLog
                    if (!(string.IsNullOrEmpty(mac_list) && string.IsNullOrEmpty(from_date) && string.IsNullOrEmpty(to_date)))
                    {
                        result = getDeviceLog(mac_list, from_date, to_date);
                    }
                    break;
                case "9": //updateHolidaysDate
                     if (!(string.IsNullOrEmpty(year)))
                    {
                        updateHolidays(year);
                    }
                    break;
                case "10": //getUsersMacList
                    if (!(string.IsNullOrEmpty(mac)))
                    {
                        result = getUsersMacs(mac);
                    }
                    break;
                case "11" : //all access
                     if (!(string.IsNullOrEmpty(mac)))
                    {
                        result = getIsAllAccess(mac).ToString();
                    }
                    break;
                case "12" : // update pass
                    if (!(string.IsNullOrEmpty(mac)) && !(string.IsNullOrEmpty(pass))) {

                        result = updatePaasword(mac, pass, new_pass);
                    }
                    break;
                case "13": // reset pass
                    if (!(string.IsNullOrEmpty(mac)))
                    {

                        result = resetPassword(mac);
                    }
                    break;
                 case "14": // getWIfiList
                    if (!(string.IsNullOrEmpty(mac)))
                    {
                        result = getWifiLists(mac);
                    }
                    break;
    
            }


            log.DebugFormat("{0}.{1}:--- end ---", className, methodName);
            LogHelper.DebugFormat("{0}.{1}:--- end ---", className, methodName);

            return result;
        }

        private void moveDeviceLog(string mac, string ip, string logs)
        {
            string methodName = string.Format("moveDeviceLog({0},{1},{2})", mac, ip, logs);
            LogHelper.DebugFormat("{0}.{1}:--- start ---", className, methodName);

            Logs.LocalLogRetrieval(logs, mac, ip);

            LogHelper.DebugFormat("{0}.{1}:--- end ---", className, methodName);
        }

        private string retrieveExcuse(string mac, string from_date, string to_date, string approve, string reason_type)
        {
            string methodName = string.Format("retrieveExcuse({0},{1},{2})", mac, from_date, to_date);
            LogHelper.DebugFormat("{0}.{1}:--- start ---", className, methodName);

            string result = "";
            DateTime f_date = DateTime.MinValue;
            DateTime t_date = DateTime.MinValue;

            if (DateTime.TryParse(from_date, out f_date) && DateTime.TryParse(to_date, out t_date))
            {
                result = Retriever.pendingApproval(mac, f_date, t_date, approve, reason_type);
            }

            LogHelper.DebugFormat("{0}.{1}:--- end ---", className, methodName);
            return result;
        }

        private string approveExcuse(string mac, string excuse_id, string approve, string ip)
        {
            string methodName = string.Format("approveExcuse({0},{1},{2},{3})", mac, ip, excuse_id, approve);
            LogHelper.DebugFormat("{0}.{1}:--- start ---", className, methodName);

            string result = Excuse.approveExcuse(mac, excuse_id, approve, ip);

            LogHelper.DebugFormat("{0}.{1}:--- end ---", className, methodName);
            return result;
        }

        private string login(string ip, string mac, string longitude, string latitude)
        {
            string methodName = string.Format("login({0},{1},{2},{3})", mac, ip, longitude, latitude);
            LogHelper.DebugFormat("{0}.{1}:--- start ---", className, methodName);

            double lon = 0.0;
            double lat = 0.0;
            double.TryParse(longitude, out lon);
            double.TryParse(latitude, out lat);
            int res = new Absen().Login(mac, ip, lon, lat);
            string result = res.ToString();
            result = Retriever.RetrieveLoginData(mac, ip);

            LogHelper.DebugFormat("{0}.{1}:--- end ---", className, methodName);
            return result;
        }

        private string insertExcuse(string mac, string from_date, string to_date, string reason, string excuse_type, string latitude, string longitude)
        {
            string methodName = string.Format("insertExcuse({0},{1},{2},{3},{4},{5})", mac, from_date, to_date, reason, latitude, longitude);
            LogHelper.DebugFormat("{0}.{1}:--- start ---", className, methodName);

            log.DebugFormat("{0}.{1}:--- {2},{3}, {4}, {5}, {6} ---", className, methodName, mac, from_date, to_date, reason, excuse_type);

            string result = "";


            DateTime f_date = DateTime.MinValue;
            DateTime t_date = DateTime.MinValue;
            string pattern = "yyyy-MM-dd HH:mm:ss";

            bool ok_fdate = DateTime.TryParseExact(from_date, pattern, null, DateTimeStyles.None, out f_date);
            bool ok_tdate = DateTime.TryParseExact(to_date, pattern, null, DateTimeStyles.None, out t_date);

            if (!ok_fdate) {
                pattern = "yyyy-MM-dd";
                ok_fdate = DateTime.TryParseExact(from_date, pattern, null, DateTimeStyles.None, out f_date);
                ok_tdate = DateTime.TryParseExact(to_date, pattern, null, DateTimeStyles.None, out t_date);
            }

            if ( ok_fdate && ok_tdate)
            {
                log.DebugFormat("{0}.{1}:--- end ---, pass parsing: f_date{2} , t_date{3}", className, methodName, f_date.ToString(), t_date.ToString());
                result = Excuse.insertExcuse(mac, f_date, t_date, reason, int.Parse(excuse_type), latitude, longitude);
            }

            LogHelper.DebugFormat("{0}.{1}:--- end ---", className, methodName);
            return result;
        }

        private string getExcuseTypes()
        {
            string methodName = "getExcuseTypes()";
            LogHelper.DebugFormat("{0}.{1}:--- start ---", className, methodName);

            string result = result = Retriever.getAllExcuseType();

            LogHelper.DebugFormat("{0}.{1}:--- end ---", className, methodName);
            return result;
        }

        private string getDailyReport(string mac, string from_date, string to_date, string mac_list, string type_list, string status_list)
        {
            string methodName = string.Format("getDailyReport({0},{1},{2},{3})", mac, from_date, to_date, mac_list);
            LogHelper.DebugFormat("{0}.{1}:--- start ---", className, methodName);

            string result = "";

            DateTime f_date = DateTime.MinValue;
            DateTime t_date = DateTime.MinValue;

            if (DateTime.TryParse(from_date, out f_date) && DateTime.TryParse(to_date, out t_date))
            {
                result = Retriever.getDailyReport(mac, f_date, t_date, mac_list, type_list, status_list);
            }

            LogHelper.DebugFormat("{0}.{1}:--- end ---", className, methodName);
            return result;

        }

        private string getMonthlyReport(string mac, string from_date, string to_date, string mac_list)
        {
            string methodName = string.Format("getMonthlyReport({0},{1},{2},{3})", mac, from_date, to_date, mac_list);
            LogHelper.DebugFormat("{0}.{1}:--- start ---", className, methodName);

            string result = "";
            DateTime f_date = DateTime.MinValue;
            DateTime t_date = DateTime.MinValue;

            if (DateTime.TryParse(from_date, out f_date) && DateTime.TryParse(to_date, out t_date))
            {
                result = Retriever.getMonthlyReport(mac, f_date, t_date, mac_list);
            }

            LogHelper.DebugFormat("{0}.{1}:--- end ---", className, methodName);
            return result;
        }

        private string getDeviceLog(string mac_list, string from_date, string to_date)
        {
            string methodName = string.Format("getMonthlyReport({0},{1},{2})", mac_list, from_date, to_date);
            LogHelper.DebugFormat("{0}.{1}:--- start ---", className, methodName);

            string result = "";
            DateTime f_date = DateTime.MinValue;
            DateTime t_date = DateTime.MinValue;

            if (DateTime.TryParse(from_date, out f_date) && DateTime.TryParse(from_date, out t_date))
            {
                result = Retriever.getDeviceLog(mac_list, f_date, t_date);
            }

            LogHelper.DebugFormat("{0}.{1}:--- end ---", className, methodName);
            return result;
        }

        private void updateHolidays(string year)
        {
            string methodName = string.Format("updateHolidays({0})", year);
            LogHelper.DebugFormat("{0}.{1}:--- start ---", className, methodName);

            try
            {
                HolidayFeed.getFeed(year);
            }
            catch (Exception ex)
            {
                LogHelper.Error(ex);
            }

            LogHelper.DebugFormat("{0}.{1}:--- end ---", className, methodName);
        }

        private string getUserIP(HttpRequest request)
        {
            string methodName = string.Format("getUserIP({0})", request.ToString());
            LogHelper.DebugFormat("{0}.{1}:--- start ---", className, methodName);

            // Look for a proxy address first
            string _ip = request.ServerVariables["HTTP_X_FORWARDED_FOR"];

            // If there is no proxy, get the standard remote address
            if ( string.IsNullOrEmpty(_ip) )
            {
	            _ip = request.ServerVariables["REMOTE_ADDR"];
            }

            LogHelper.DebugFormat("{0}.{1}:--- end ---", className, methodName);
            return _ip;
        }

        public string getUsersMacs(string mac)
        {
            string methodName = string.Format("getUsersMacs({0})", mac);
            LogHelper.DebugFormat("{0}.{1}:--- start ---", className, methodName);

            string result = "";
            result = Retriever.getUsersMacs(mac);
           

            LogHelper.DebugFormat("{0}.{1}:--- end ---", className, methodName);
            return result;
        }

        private bool getIsAllAccess(string mac)
        {
            string methodName = string.Format("getIsAllAccess({0})", mac);
            LogHelper.DebugFormat("{0}.{1}:--- start ---", className, methodName);

            bool result = Retriever.allAccess(mac);
            
            LogHelper.DebugFormat("{0}.{1}:--- {2} ---", className, methodName, result.ToString());
            LogHelper.DebugFormat("{0}.{1}:--- end ---", className, methodName);
            return result;
        }



        private string updatePaasword(string mac,string old_pass, string new_pass)
        {
            string methodName = string.Format("updatePaasword({0})", mac);
            LogHelper.DebugFormat("{0}.{1}:--- start ---", className, methodName);

            string result = "";
            result = Retriever.updatePassword(mac, old_pass, new_pass);
           
            LogHelper.DebugFormat("{0}.{1}:--- end ---", className, methodName);
            return result;
        }

        private string resetPassword(string mac)
        {
            string methodName = string.Format("resetPassword({0})", mac);
            LogHelper.DebugFormat("{0}.{1}:--- start ---", className, methodName);

            string result = "";
            result = Retriever.resetPassword(mac);

            LogHelper.DebugFormat("{0}.{1}:--- end ---", className, methodName);
            return result;
        }

        private string getWifiLists(string mac)
        {
            string methodName = string.Format("getWifiLists({0})", mac);
            LogHelper.DebugFormat("{0}.{1}:--- start ---", className, methodName);

            string result = "";
            result = Retriever.getWifiList(mac);

            LogHelper.DebugFormat("{0}.{1}:--- end ---", className, methodName);
            return result;
        }

        #endregion
    }

}