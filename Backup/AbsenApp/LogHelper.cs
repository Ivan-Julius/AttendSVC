using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using log4net;
using System.Web.Configuration;

namespace AbsenApp
{
    public static class LogHelper
    {
        private static ILog log = LogManager.GetLogger(typeof(LogHelper));
        private static bool isLogDebugEnabled = (WebConfigurationManager.AppSettings["isLogDebugEnabled"] == Boolean.TrueString ? true: false);
        private static bool isLogErrorEnabled = (WebConfigurationManager.AppSettings["isLogErrorEnabled"] == Boolean.TrueString ? true : false);
        
        public static void DebugFormat(string format, string className, string methodName, string message)
        {
            if (isLogDebugEnabled)
            {
                log.DebugFormat(format, className, methodName, message);
            }

        }

        public static void DebugFormat(string format, string className, string methodName)
        {
            if (isLogDebugEnabled)
            {
                log.DebugFormat(format, className, methodName);
            }

        }

        public static void Debug(string message)
        {
            if (isLogDebugEnabled)
            {
                log.Debug(message);
            }

        }

        public static void ErrorFormat(string format, string className, string methodName, string message)
        {
            if (isLogErrorEnabled)
            {
                log.ErrorFormat(format, className, methodName, message);
            }

        }

        public static void ErrorFormat(string format, string className, string methodName)
        {
            if (isLogErrorEnabled)
            {
                log.ErrorFormat(format, className, methodName);
            }

        }

        public static void Error(string message)
        {
            if (isLogErrorEnabled)
            {
                log.Error(message);
            }

        }

        public static void Error(Exception exception)
        {
            if (isLogErrorEnabled)
            {
                log.Error(exception);
            }

        }
    }
}