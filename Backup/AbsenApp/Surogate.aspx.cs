using System;
using System.Web.UI;
using log4net;

namespace AbsenApp
{
    public partial class Surogate : System.Web.UI.Page
    {
        private string ConnectionString = System.Configuration.ConfigurationManager.ConnectionStrings["TKPAbsen"].ConnectionString;
        private static ILog log = LogManager.GetLogger(typeof(Surogate));
        private static string className = "Surogate";
       
        protected void Page_Load(object sender, EventArgs e){

            string methodName = "Page_Load()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");
           
            if (!Page.IsPostBack)
                switchMethod(Request.Params["method"]);

            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, Request.Params["method"]);
        }

        private string switchMethod(string Method) {

            string methodName = "switchMethod()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, Method);

            string returns = "";

            switch (Method) {
                case "MoveDeviceLog": MoveDeviceLog(Request.Params["mac"], Request.Params["ip"], Request.Params["logs"]);
                    break;
                case "RetrieveExcuse": returns = RetrieveExcuse(Request.Params["macAdds"], Request.Params["from_date"], Request.Params["to_date"], Request.Params["approve"], Request.Params["excuse_type"]);
                    break;
                case "ApproveExcuse": ApproveExcuse(Request.Params["mac"], Request.Params["ip"], Request.Params["Excuse_id"], Request.Params["approve"], Request.Params["pass"]);
                    break;
                case "Login": returns = Login(Request.Params["ip"], Request.Params["mac"]);
                    break;
                case "insertExcuse": insertExcuse(Request.Params["mac"], Request.Params["from_date"], Request.Params["to_date"], Request.Params["reason"], Request.Params["type_id"], Request.Params["lat"], Request.Params["lon"]);
                    break;
                case "getExcuseTypes": returns = getExcuseTypes();
                    break;
                case "DailyReport": returns = getDailyReport(Request.Params["mac"], Request.Params["from_date"], Request.Params["to_date"], Request.Params["mac_list"], Request.Params["type_list"], Request.Params["status_list"]);
                    break;
                case "MonthlyReport": returns = getMonthlyReport(Request.Params["mac"], Request.Params["from_date"], Request.Params["to_date"], Request.Params["mac_list"]);
                    break;
                case "getDeviceLog": returns = getDeviceLog(Request.Params["mac_list"], Request.Params["from_date"], Request.Params["to_date"]);
                    break;
                case "updateHolidays": updateHolidays(Request.Params["year"]);
                    break;
                case "10": //getUsersMacList
                    if (!(String.IsNullOrEmpty(Request.Params["mac"])))
                    {
                        returns = getUsersMacs(Request.Params["mac"]);
                    }
                    break;
            }

            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, "");
            return returns;
        }

        private void MoveDeviceLog(string mac, string ip, string logs) {

            string methodName = "switchMethod()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, mac+"|"+ip+"|"+logs);

            Logs.LocalLogRetrieval(logs, mac, ip);

            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, "");            
        }
            
        private string RetrieveExcuse(string macAdds, string from_date, string to_date, string approve, string excuse_type) {

            string methodName = "Login()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");

            string result = "";

            var fdate = DateTime.Parse(from_date);
            var tdate = DateTime.Parse(to_date);
                        
            result = Retriever.pendingApproval(macAdds, fdate, tdate, approve, excuse_type);
            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, result);

            return result;
        }

        private string ApproveExcuse(string mac, string ip, string Excuse_id, string approve, string pass) {
            return Excuse.approveExcuse(mac, pass, Excuse_id, approve, ip);        
        }

        private string Login(string ip, string mac) {

            string methodName = "Login()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");

            int res = 0;// Absen.Login(mac, ip);
            string result = res.ToString();
            result = Retriever.RetrieveLoginData(mac, ip);           

            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, result);
            return result;
        }

        private string insertExcuse(string mac, string from_date, string to_date, string reason, string type_id, string latitude, string longitude){

            string methodName = "insertExcuse()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");

            log.DebugFormat("----------{0}-{1}-({2})-----------", className, methodName, "" );

            string result = "";

            try
            {
                DateTime fdate = DateTime.Parse(from_date);
                DateTime tdate = DateTime.Parse(to_date);
              
                log.DebugFormat("------------DATA---{0}-{1}-({2})-----------", className, methodName, from_date + "|" + to_date + "|" + latitude + longitude);

                result = Excuse.insertExcuse(mac, fdate, tdate, reason, int.Parse(type_id), latitude, longitude);
            }
            catch (Exception ex) {
                log.Error(ex);
            }

            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName,result);
            return result;
        }


        private string getExcuseTypes() {

            string methodName = "getExcuseTypes()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");

            string result = "";

            try {
            
                result = Retriever.getAllExcuseType();             
            
            }catch(Exception ex){
                log.Error(ex);         
            }

            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, result);
            return result;                
        }

        private string getDailyReport(string mac, string from, string to, string mac_list, string type_list, string status_list) {

            string methodName = "getExcuseTypes()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");

            string result = "";

            try
            {
                DateTime fdate = DateTime.Parse(from);
                DateTime tdate = DateTime.Parse(to);

                result = Retriever.getDailyReport(mac, fdate, tdate, mac_list, type_list, status_list);

            }
            catch (Exception ex)
            {
                log.Error(ex);
            }

            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, result);
            return result;       

        }


        private string getMonthlyReport(string mac, string from, string to, string mac_list)
        {

            string methodName = "getExcuseTypes()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");

            string result = "";

            try
            {

                DateTime fdate = DateTime.Parse(from);
                DateTime tdate = DateTime.Parse(to);
                
                result = Retriever.getMonthlyReport(mac, fdate, tdate, mac_list);

            }
            catch (Exception ex)
            {
                log.Error(ex);
            }

            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, result);
            return result;

        }

        

         private string getDeviceLog(string mac_list, string from, string to)
        {

            string methodName = "getDeviceLog()";
            log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");

            string result = "";

            try
            {

                DateTime fdate = DateTime.Parse(from);
                DateTime tdate = DateTime.Parse(to);

                result = Retriever.getDeviceLog(mac_list, fdate, tdate);

            }
            catch (Exception ex)
            {
                log.Error(ex);
            }

            log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName, result);
            return result;

        }

         private void updateHolidays(string year)
         {
             string methodName = "updateHolidays()";
             log.DebugFormat("------------START---{0}-{1}-({2})-----------", className, methodName, "");

             try
             {
                 HolidayFeed.getFeed(year);
             }
             catch (Exception ex)
             {
                 log.Error(ex);
             }

             log.DebugFormat("------------END---{0}-{1}-({2})-----------", className, methodName);
         }

         public string getUsersMacs(string mac)
         {
             string methodName = String.Format("getUsersMacs({0})", mac);
             LogHelper.DebugFormat("{0}.{1}:--- start ---", className, methodName);

             string result = "";
             result = Retriever.getUsersMacs(mac);

             LogHelper.DebugFormat("{0}.{1}:--- end ---", className, methodName);
             return result;

         }

    }
}
