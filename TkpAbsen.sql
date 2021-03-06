USE [master]
GO
/****** Object:  Database [TKPAbsen]    Script Date: 6/26/2015 5:42:35 PM ******/
CREATE DATABASE [TKPAbsen]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Absensi', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\Absensi.mdf' , SIZE = 4160KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'Absensi_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\Absensi_log.ldf' , SIZE = 1280KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [TKPAbsen] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [TKPAbsen].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [TKPAbsen] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [TKPAbsen] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [TKPAbsen] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [TKPAbsen] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [TKPAbsen] SET ARITHABORT OFF 
GO
ALTER DATABASE [TKPAbsen] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [TKPAbsen] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [TKPAbsen] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [TKPAbsen] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [TKPAbsen] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [TKPAbsen] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [TKPAbsen] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [TKPAbsen] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [TKPAbsen] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [TKPAbsen] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [TKPAbsen] SET  ENABLE_BROKER 
GO
ALTER DATABASE [TKPAbsen] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [TKPAbsen] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [TKPAbsen] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [TKPAbsen] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [TKPAbsen] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [TKPAbsen] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [TKPAbsen] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [TKPAbsen] SET RECOVERY FULL 
GO
ALTER DATABASE [TKPAbsen] SET  MULTI_USER 
GO
ALTER DATABASE [TKPAbsen] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [TKPAbsen] SET DB_CHAINING OFF 
GO
ALTER DATABASE [TKPAbsen] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [TKPAbsen] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
EXEC sys.sp_db_vardecimal_storage_format N'TKPAbsen', N'ON'
GO
USE [TKPAbsen]
GO
/****** Object:  StoredProcedure [dbo].[ammendforLate]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ivan
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ammendforLate]
@user_id int,
@excuse_id int, 
@login_type int,
@from_date datetime,
@to_date datetime,
@result varchar(50) OUTPUT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	print @user_id

	declare @company_id int 
	 select @company_id = company_id 
	  FROM  users u    
    INNER JOIN company_setting cs ON u.company_id = cs.id
	where u.id = @user_id
    
	DECLARE @nowutc DATETIME 
		, @login_date DATETIME
		, @today_time_begin SMALLINT
        , @time_begin SMALLINT
        , @time_end SMALLINT
        , @time_overtime SMALLINT
        , @timezone SMALLINT
		, @limit_late DATETIME
        , @logout_date DATETIME
		, @login_start_overtime DATETIME
		, @is_late BIT
		, @login_id int
       
	 SELECT @today_time_begin = today_time_begin
        , @time_begin = time_begin
        , @time_end = time_end
        , @time_overtime = time_overtime
        , @timezone = timezone        
        FROM dbo.getCompanySetting(@company_id)

		SET @limit_late = DATEADD(HOUR, @time_begin, CONVERT(DATETIME, CONVERT(VARCHAR,(CONVERT(DATE, @from_date)))+' 00:00:00'))
		SET @login_date = @limit_late
		 SELECT @logout_date = DATEADD(HOUR,@time_end,@limit_late)
				, @login_start_overtime = DATEADD(HOUR,@time_overtime,@logout_date)
		SET @is_late = 0
		SET @login_id = 0

		declare @loginType varchar(20)

		select @login_id = z.id, @loginType = x.login_type 
		from login z join login_type x on z.login_type = x.id
		where CONVERT(DATE, z.first_login) = CONVERT(DATE, @from_date) and z.user_id = user_id
		
		set @result = 'ok'

		if(@login_id > 0 and @loginType != 'Absent')
		BEGIN
			print 'not absent late approval'
			update login set first_login = @login_date, logout_time = @logout_date, is_late = @is_late, 
				start_overtime = @login_start_overtime, login_type = @login_type
			where id = @login_id
			
		END
		else if(@login_id = 0 and (CONVERT(DATE, GETDATE()) <= CONVERT(DATE, @from_date)))
		begin
			print 'early approval' 
			INSERT INTO login (user_id, first_login, last_login, logout_time, start_overtime, is_late, login_type)  
			VALUES (@user_id, @login_date, @login_date, @logout_date, @login_start_overtime, @is_late, @login_type)
		end
		else 
			begin
			print 'absent user'
			set @result = 'User was Absent'
		end

END

GO
/****** Object:  StoredProcedure [dbo].[doLogin]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[doLogin]
    -- Add the parameters for the stored procedure here
    @mac VARCHAR(17)
  , @ip_address VARCHAR(15)
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    DECLARE @user_id INT
		  , @company_id INT 
		  , @mac_id INT
		  , @result INT

    EXEC @result = dbo.getMacUserCompanyStatus @mac, @company_id OUTPUT, @user_id OUTPUT, @mac_id OUTPUT

    IF (@result = 0)
    BEGIN
        DECLARE @login_date DATETIME                
			  , @nowutc DATETIME
			  , @logout_time DATETIME
			  , @first_login DATETIME
			  , @last_login DATETIME
			  , @today_time_begin SMALLINT
			  , @time_begin SMALLINT
		      , @time_end SMALLINT
			  , @time_overtime SMALLINT
			  , @timezone SMALLINT
			  , @login_id INT
			  , @LateExcuseID INT = 0
			  , @EarlyLeaveID INT = 0

        SELECT @today_time_begin = today_time_begin
			 , @time_begin = time_begin
			 , @time_end = time_end
			 , @time_overtime = time_overtime
			 , @timezone = timezone        
        FROM dbo.getCompanySetting(@company_id)

        SELECT @nowutc = GETUTCDATE(), @login_date = DATEADD(HOUR, @timezone, @nowutc)
        
        EXEC dbo.hasLoggedInToday @user_id, 
								  @login_date, 
								  @today_time_begin, 
								  @login_id OUTPUT, 
								  @first_login OUTPUT, 
								  @last_login OUTPUT, 
								  @logout_time OUTPUT
        
		DECLARE @excuse INT = 0; 
		DECLARE @excuse_name VARCHAR(50)
		
		SELECT @excuse = excuse.id , @excuse_name = Excuse_Type.typeName 
		FROM Excuse JOIN Excuse_Type 
		ON Excuse.type = Excuse_Type.id
		WHERE user_id = @user_id and mac_id = @mac_id 
			  AND CONVERT(DATE,from_date) = CONVERT(DATE, getdate()) 
		   	  AND excuse.approved = 1 and Excuse_Type.typeName IN ('Allowed Late', 'Early Leave')
		
		PRINT @user_id
		PRINT @mac_id

        IF (@login_id IS NULL)
        BEGIN
            DECLARE @limit_late DATETIME
            , @logout_date DATETIME
            , @login_start_overtime DATETIME
            , @is_late BIT
			
            SET @limit_late = DATEADD(HOUR, @time_begin, dbo.getDateOnly(@nowutc))
            
			IF(DATEDIFF(SECOND, @limit_late, @login_date) > 0 and ((@excuse < 1) OR (@excuse > 0 and LOWER(@excuse_name) != LOWER('Allowed Late')))) 
				BEGIN	
					PRINT 'late'
					SET @is_late = 1
				END
            ELSE
				BEGIN
					PRINT 'not late'	
					SET @is_late = 0
				END

			IF(@excuse > 0 and LOWER(@excuse_name) = LOWER('Allowed Late'))
			BEGIN
				SET @login_date = @limit_late
				IF(@is_late = 1) 
				BEGIN	
					SET @is_late = 0
				END 

			END
          
            SELECT @logout_date = DATEADD(HOUR,@time_end,@login_date)
            , @login_start_overtime = DATEADD(HOUR,@time_overtime,@logout_date)

            INSERT INTO login (user_id, first_login, last_login, logout_time, start_overtime, is_late, login_type) 
            VALUES (@user_id, @login_date, @login_date, @logout_date, @login_start_overtime, @is_late, 1)
            SET @login_id = @@IDENTITY
        END
        ELSE
        BEGIN
			
			PRINT 'Hello'

            DECLARE @is_full BIT
            , @is_full_count INT
         
            SET @is_full_count = DATEDIFF(SECOND, @logout_time, @login_date) 

            IF (@is_full_count > 0)
                SET @is_full = 1
            ELSE
                SET @is_full = 0
        
			if(@excuse < 1 or (@excuse > 0 and LOWER(@excuse_name) != LOWER('Early Leave')))
            BEGIN
				
				PRINT 'Hello1'
				PRINT @excuse
				PRINT @excuse_name

				UPDATE login
				SET last_login = @login_date
				, is_full = @is_full
				, login_elapse_time = DATEDIFF(SECOND, first_login, @login_date)
				, overtime_elapse_time = DATEDIFF(SECOND, logout_time, start_overtime) +  DATEDIFF(SECOND, start_overtime, @login_date)
				WHERE id = @login_id
			END
        END
   
		if(@excuse < 1 or (@excuse > 0 and LOWER(@excuse_name) != LOWER('Early Leave')))
        BEGIN
			INSERT INTO login_history (login_id, login_date, mac_id, ip_address)
			VALUES (@login_id, @login_date, @mac_id, @ip_address)
		END

        SET @result = 0
    END
    RETURN @result
END



GO
/****** Object:  StoredProcedure [dbo].[earlyLeave]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ivan
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[earlyLeave]
@user_id int,
@login_type int,
@from_date datetime,
@to_date datetime,
@result varchar(50) OUTPUT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	declare @company_id int 
	 select @company_id = company_id 
	  FROM  users u    
    INNER JOIN company_setting cs ON u.company_id = cs.id
	where u.id = @user_id
    
	DECLARE @nowutc DATETIME 
		, @login_date DATETIME
		, @today_time_begin SMALLINT
        , @time_begin SMALLINT
        , @time_end SMALLINT
        , @time_overtime SMALLINT
        , @timezone SMALLINT
		, @limit_late DATETIME
        , @logout_date DATETIME
		, @login_start_overtime DATETIME
		, @is_late BIT
		, @login_id INT

	DECLARE @OCCURANCE INT;
	SET @OCCURANCE = DATEDIFF(day, @from_date, @to_date)

	IF(@OCCURANCE = 0)
	BEGIN		
	 SELECT @today_time_begin = today_time_begin
        , @time_begin = time_begin
        , @time_end = time_end
        , @time_overtime = time_overtime
        , @timezone = timezone        
        FROM dbo.getCompanySetting(@company_id)

		declare @loginType varchar(20)

		select @login_id = z.id, @loginType = x.login_type 
		from login z join login_type x on z.login_type = x.id
		where CONVERT(DATE, z.first_login) = CONVERT(DATE, @from_date) and z.user_id = user_id		

		PRINT 'Hello'

		if(CONVERT(DATE,@from_date) = CONVERT(DATE, GETDATE()))
		BEGIN	      	
			PRINT 'Hello1'
			if(@login_id > 0)
			BEGIN
				update login set logout_time = @to_date, last_login = @to_date, login_type = @login_type where id = @login_id	
				set @result = 'ok'
			END	
			else
			BEGIN
				SET @result = 'User has not login'
			END	
		END
		ELSE IF(CONVERT(DATE,@from_date) < CONVERT(DATE, GETDATE()))
		BEGIN
			PRINT 'Hello2'
			if(@loginType != 'Absent')
			BEGIN
				update login set logout_time = @to_date, last_login = @to_date, login_type = @login_type where id = @login_id	
				SET @result = 'ok'
			END
			else
			BEGIN
				SET @result = 'User has not login'
			END	
		END
	END
	ELSE
	BEGIN
		SET @result = 'early leave from date and to date must be on the same date'
	END	

	PRINT @result

END

GO
/****** Object:  StoredProcedure [dbo].[excuseApproval]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ivan
-- Create DATE: <Create DATE,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[excuseApproval]
@excuse_id INT,
@mac VARCHAR(17),
@ip VARCHAR(15),
@approval bit,
@res VARCHAR(50) OUTPUT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets FROM
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @usertype VARCHAR(50), 
		@user_id INT, 
		@approved bit, 
		@type SMALLINT, 
		@login_id INT, 
		@excuse_user INT, 
		@excuse_mac INT, 
		@type_name VARCHAR(50),
		@from_date DATETIME,
		@to_date DATETIME,
		@entry_date DATETIME,
		@to_exec NVARCHAR(500) 

	/* find the approver
	SELECT @usertype = o.name, @user_id = n.user_id FROM users_macs n
	join users_groups m ON m.user_id = n.user_id 
	join groups o ON o.id = m.group_id
	WHERE n.mac = @mac */
	 
	IF(@approval = 0)
		BEGIN
			SET @to_exec = 'update Excuse SET approved = 0 WHERE id = CONVERT(INT,'+CONVERT(VARCHAR(20),@excuse_id)+')'
		END 
	ELSE
		BEGIN	
		
		DECLARE @login_type INT
		DECLARE @result VARCHAR(50)
		DECLARE @sqlexec NVARCHAR(3000)
				
		SELECT @approved = excuse.approved, @excuse_user = user_id, @excuse_mac = mac_id, @type = excuse.type, 
			   @type_name = Excuse_type.typeName, @from_date = from_date, @to_date = to_date, @entry_date = entry_date FROM excuse 
		       join Excuse_type ON excuse.type = Excuse_type.id WHERE excuse.id = @excuse_id

		SELECT @login_id = id FROM login WHERE CONVERT(DATE, login.first_login) = CONVERT(DATE, GETDATE())	

		SELECT @login_type = id FROM login_type WHERE LOWER(login_type.login_type) = LOWER(@type_name)

		SET @res = 'error'		
		
		IF(@approved = 0)
		BEGIN			
			IF(LOWER(@type_name) in ('permit', 'leave', 'sick'))
			BEGIN
				SET @sqlexec = 'EXEC [dbo].[permitLeaveLogin] '+CONVERT(VARCHAR(10), @excuse_user)+','+CONVERT(VARCHAR(10),@login_type)+','''+CONVERT(VARCHAR(50), @from_date)+''','''+CONVERT(VARCHAR(50), @to_date)+''''
			END			
			ELSE IF (LOWER(@type_name) = 'allowed late')
			BEGIN
				SET @sqlexec = 'EXEC [dbo].[ammendforLate] '+CONVERT(VARCHAR(10), @excuse_user)+','+ CONVERT(VARCHAR(10),@excuse_id)+','+ CONVERT(VARCHAR(10), @login_type)+','''+CONVERT(VARCHAR(50), @from_date)+''','''+CONVERT(VARCHAR(50), @to_date)+''', @result OUTPUT'
			END			
			ELSE IF (LOWER(@type_name) = 'early leave')
			BEGIN
				SET @sqlexec = 'EXEC dbo.earlyLeave '+CONVERT(VARCHAR(10), @excuse_user)+','+ CONVERT(VARCHAR(10),@excuse_id)+','''+CONVERT(VARCHAR(50), @from_date)+''','''+CONVERT(VARCHAR(50), @to_date)+''', @result OUTPUT'
			END
			ELSE IF (LOWER(@type_name) = 'overtime')
			BEGIN
				SET @sqlexec = 'EXEC dbo.Overtime '+CONVERT(VARCHAR(10), @excuse_user)+','+ CONVERT(VARCHAR(10),@excuse_id)+','''+CONVERT(VARCHAR(50), @from_date)+''','''+CONVERT(VARCHAR(50), @to_date)+''', @result OUTPUT'
			END
		END

		PRINT @sqlexec

		BEGIN TRY
			EXEC sp_executesql @sqlexec, N'@result VARCHAR(50) OUTPUT', @result OUTPUT
		END TRY
		BEGIN CATCH
			SET @res = 'ERROR : '+ERROR_MESSAGE()			
		END CATCH
		
		PRINT @res

		SET @res = @result

		IF(@res is null or @res = 'ok')
		BEGIN
			SET @to_exec = 'UPDATE Excuse SET approved = 1 WHERE id = CONVERT(INT,'+CONVERT(VARCHAR(20),@excuse_id)+')' 			
		END
		
		iF(@res != 'ok' and (LOWER(@type_name) = 'overtime'))		
		BEGIN
			SET @to_exec = 'update Excuse SET approved = 0 WHERE id = CONVERT(INT,'+CONVERT(VARCHAR(20),@excuse_id)+')'
		END
	END
	BEGIN TRY
		EXEC sp_executesql @to_exec
	END TRY
	BEGIN CATCH
		SET @res = 'ERROR : '+ERROR_MESSAGE()
		PRINT @res
	END CATCH

	PRINT @res

END

GO
/****** Object:  StoredProcedure [dbo].[fillEmptyDailyRecord]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[fillEmptyDailyRecord]
as
begin

declare @limit datetime

select @limit = dateadd(hh,-7, CONVERT(DATETIME, CONVERT(VARCHAR(10),getdate(), 120)))

if (select count(*) from holiday where date = CONVERT(VARCHAR(10),getdate(), 120)) = 0

begin
 insert into absen (mac_id,first_login, last_login, ip, status)
 (
     select m.id,
     @limit as first_login,
     @limit as last_login,
     '0' as IP,
     0 as status
     from mac m where m.id not in 
     (
        select distinct mac_id from absen where 
        first_login between  @limit and dateadd(dd,1,@limit)
     )
     and m.status = 1
 ) 
end

end


GO
/****** Object:  StoredProcedure [dbo].[getDeviceLog]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[getDeviceLog]
	-- Add the parameters for the stored procedure here
@mac_list VARCHAR(MAX),
@from_date DATETIME,
@to_date DATETIME
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT dl.mac_id, dl.logdate, dl.message, dl.stacktrace, dl.timestamp, u.name  
	FROM dbo.device_Log dl 
	JOIN dbo.device_Logtype dlt ON dl.type = dlt.log_type 
	JOIN dbo.mac m ON m.id = dl.mac_id 
	JOIN dbo.users_macs um ON um.mac = m.mac 
	JOIN dbo.users u ON u.id = um.user_id 
END

GO
/****** Object:  StoredProcedure [dbo].[getExcuseTypes]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ivan
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[getExcuseTypes]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT id, typeName from Excuse_Type
END

GO
/****** Object:  StoredProcedure [dbo].[getLog]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[getLog]
	-- Add the parameters for the stored procedure here
@mac_list VARCHAR(MAX),
@from_date DATETIME,
@to_date DATETIME
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT dl.mac_id, dl.logdate, dl.message, dl.stacktrace, dl.timestamp, u.name  
	FROM dbo.device_Log dl 
	JOIN dbo.device_Logtype dlt ON dl.type = dlt.log_type 
	JOIN dbo.mac m ON m.id = dl.mac_id 
	JOIN dbo.users_macs um ON um.mac = m.mac 
	JOIN dbo.users u ON u.id = um.user_id 

END

GO
/****** Object:  StoredProcedure [dbo].[getmac]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getmac]
@mac varchar(17)

as

set nocount off;
select m.id,m.can_approve from mac m left join add_mac a on m.id = a.owner_id where (m.mac = @mac or a.mac = @mac) and m.status = 1


GO
/****** Object:  StoredProcedure [dbo].[getmaclist]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getmaclist]
 @mac varchar(17)

 as

 declare @query varchar(max)

 select @query = 'select id,owner from mac where status = 1'

 if((select can_approve from mac where mac = @mac) = 0)
 begin

 select @query = @query + ' and mac = ''' + @mac + ''''

 end

 exec(@query)

GO
/****** Object:  StoredProcedure [dbo].[getMacUserCompanyStatus]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[getMacUserCompanyStatus]
    -- Add the parameters for the stored procedure here
    @mac VARCHAR(17)
    , @company_id INT OUTPUT
    , @user_id INT OUTPUT
    , @mac_id INT OUTPUT
--    , @mac_status BIT OUTPUT
--    , @user_status BIT OUTPUT
--    , @company_status BIT OUTPUT
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    DECLARE @result INT
    , @mac_status BIT
    , @user_group_status BIT
    , @user_status BIT
    , @company_status BIT

    SET @result = 0

    -- Insert statements for procedure here
    SELECT @company_id = company_id, @user_id = user_id, @mac_id = mac_id, @mac_status = mac_status, @user_group_status = user_group_status, @user_status = user_status, @company_status = company_status
    FROM [dbo].[UserCompanyByMAC]  WHERE mac = (@mac)
    --SELECT @company_id, @user_id, @mac_id

	PRINT @mac_id

    IF (@mac_id IS NULL)
    BEGIN
        --SELECT 'MAC not registered'
        SET @result = -105
    END
    ELSE IF (@mac_id IS NOT NULL AND @mac_status = 0)
    BEGIN
        --SELECT 'MAC Address disabled'
        SET @result = -104
    END
    ELSE IF (@mac_id IS NOT NULL AND @mac_status = 1 AND @user_group_status = 0)
    BEGIN
        --SELECT 'User in group disabled'
        SET @result = -103
    END
    ELSE IF (@mac_id IS NOT NULL AND @mac_status = 1 AND @user_status = 0)
    BEGIN
        --SELECT 'User disabled'
        SET @result = -102
    END
    ELSE IF (@mac_id IS NOT NULL AND @mac_status = 1 AND @user_status = 1 AND @company_status = 0)
    BEGIN
        --SELECT 'Company disabled'
        SET @result = -101
    END
    RETURN @result
END


GO
/****** Object:  StoredProcedure [dbo].[getNotesReport]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getNotesReport]
@selectedMacString varchar(max),
@from varchar(max),
@to varchar(max)

as

declare @query varchar(max)

select @from = convert(varchar,dateadd(hh,-7,convert(datetime,@from,120)),120)
select @to = convert(varchar,dateadd(hh,-7,convert(datetime,@to,120)),120)

begin

set @query = 'select m.owner,n.date,n.type,n.notes,n.approval,n.approval_notes '+
'from notes n inner join mac m on n.mac_id = m.id ' +
             'where mac_id in (' +@selectedMacString + ') and n.date >= ''' + @from +
             ''' and n.date <=''' + @to + ''' order by n.date desc';

exec(@query)

end


GO
/****** Object:  StoredProcedure [dbo].[getPendingApproval]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getPendingApproval]
 @selectedMacString varchar(100),
 @from varchar(10),
 @to varchar(10)

as

declare
@query varchar(max)

 begin

 set @query= 'select n.date,n.type,n.notes,m.owner,n.id,n.approval, n.approval_notes, n.mac_id '+
    'from notes n join mac m on n.mac_id = m.id ' +
             'where n.mac_id in (' + @selectedMacString + ') ' +
    'and date between ''' + @from + ''' and ''' + @to +
             ''' order by n.date desc';

 exec(@query)
 end

GO
/****** Object:  StoredProcedure [dbo].[getPendingExcuse]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getPendingExcuse]
 @selectedMacString varchar(300),
 @from datetime,
 @to datetime

as
begin

declare @query nvarchar(max)
 
set @query= 'SELECT n.from_date, n.to_date, n.entry_date, k.typeName as type, n.excuse_reason, m.owner, n.id, n.mac_id '+
    'FROM excuse n JOIN mac m ON m.id = n.mac_id JOIN Excuse_Type k on n.type = k.id
	WHERE n.approved = 0 ' 

	if(@selectedMacString is not null)
	BEGIN
       set @query = @query + 'and n.mac_id in (' + @selectedMacString + ') '
	END
	
	if(@from is not null and @to is not null)
	BEGIN
		set @query = @query + 'and n.entry_date BETWEEN (CONVERT(datetime,'''+CONVERT(nvarchar(30),@from, 21)+''')) AND (CONVERT(datetime,'''+CONVERT(nvarchar(30),@to, 21)+''')) or 
		n.from_date BETWEEN (CONVERT(datetime,'''+CONVERT(nvarchar(30),@from, 21)+''')) AND (CONVERT(datetime,'''+CONVERT(nvarchar(30),@to, 21)+'''))'; 
	END
	else
	BEGIN
		set @query = @query + 'and ((DATEPART(m, n.entry_date) = DATEPART(m, getdate()) and DATEPART(yy, n.entry_date) = DATEPART(yy, getdate())) or 
		(DATEPART(m, n.from_date) = DATEPART(m, getdate()) and DATEPART(yy, n.from_date) = DATEPART(yy, getdate())))'; 
	END

set @query = @query + 'order by n.entry_date desc';



print @query
Exec sp_executesql @query
end

GO
/****** Object:  StoredProcedure [dbo].[getReport]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[getReport]
@selectedMacString varchar(max),
@from varchar(max),
@to varchar(max)

as

declare @query varchar(max)

select @from = convert(varchar,dateadd(hh,-7,convert(datetime,@from,120)),120)
select @to = convert(varchar,dateadd(hh,-7,convert(datetime,@to,120)),120)

begin

set @query = 'select m.owner,a.first_login,a.last_login, a.id, a.status '+
'from absen a inner join mac m on a.mac_id = m.id ' +
             'where mac_id in ( '+@selectedMacString + ') and first_login between ''' + @from +
             ''' and '''+ @to+''' order by a.first_login desc'

exec(@query)

end



GO
/****** Object:  StoredProcedure [dbo].[getUserLoginInformation]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Ivan>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[getUserLoginInformation]
@mac VARCHAR(17),
@ip_address VARCHAR(15)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets FROM
	-- INTerfering with SELECT statements.
	SET NOCOUNT ON;
	
	  DECLARE @user_id INT
    , @company_id INT 
    , @mac_id INT	
	
	DECLARE @resultTABLE TABLE(first_login DATETIME, last_login DATETIME, is_full SMALLINT, late_count INT);
	EXEC dbo.getMacUserCompanyStatus @mac, @company_id OUTPUT, @user_id OUTPUT, @mac_id OUTPUT
	
	SELECT Top 1 first_login, 
				last_login,
				 is_full,	
				 is_late,			   
				(select count(*) as latecount from login WHERE login.user_id = @user_id and is_late = 1) as late_count
		FROM login WHERE login.user_id = @user_id 
		ORDER BY first_login DESC	 

END

GO
/****** Object:  StoredProcedure [dbo].[hasLoggedInToday]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  PROCEDURE [dbo].[hasLoggedInToday]
(
    -- Add the parameters for the function here
    @user_id INT
    , @login_date DATETIME
    , @today_time_begin SMALLINT
    , @login_id INT OUTPUT
    , @first_login DATETIME OUTPUT
    , @last_login DATETIME OUTPUT
    , @logout_time DATETIME OUTPUT
)
AS
BEGIN
    -- Declare the return variable here
    DECLARE @limit_first DATETIME
    , @limit_last DATETIME
    

    -- Add the T-SQL statements to compute the return value here
    SELECT @limit_first = DATEADD(HOUR,@today_time_begin, dbo.getDateOnly(@login_date))
    , @limit_last = DATEADD(DAY, 1, @limit_first)

    --SELECT @limit_first, @limit_last

    SELECT @login_id = id 
    , @first_login = first_login
    , @last_login = last_login
    , @logout_time = logout_time
    FROM login 
    WHERE user_id = @user_id
    AND first_login >= @limit_first
    AND last_login < @limit_last

    -- Return the result of the function
    RETURN 0

END



GO
/****** Object:  StoredProcedure [dbo].[insertallocallogs]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ivan
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[insertallocallogs]
@logs VARCHAR(max),
@mac VARCHAR(17),
@ip_Address VARCHAR(15)

as
BEGIN
	-- SET NOCOUNT ON added to prevent extra result SETs from
	-- INTerfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @occurance INT;
	DECLARE @parts VARCHAR(max);
	DECLARE @occurance2 INT;
	DECLARE @logdate DATETIME;
	DECLARE @utclogdate DATETIME;
	DECLARE @time VARCHAR(20);
	DECLARE @type VARCHAR(10)
	DECLARE @stacktrace VARCHAR(MAX);
	DECLARE @message VARCHAR(MAX);		
	DECLARE @Seperators VARCHAR(3);
	DECLARE @Delimiters VARCHAR(3);
	DECLARE @user_id INT
	DECLARE @company_id INT 
    DECLARE @mac_id INT
	DECLARE @type_id INT
	DECLARE @timezone INT
	
	SELECT @timezone = timezone FROM dbo.company_setting cs JOIN dbo.users u ON cs.id = u.company_id JOIN dbo.users_macs um ON u.id = um.user_id WHERE um.mac = @mac     

	SET @Delimiters = '^';
	SET @Seperators = '|'; -- wierd patindex result with [ opening must add -1 to patindex

	SET @occurance = ((LEN(@logs) - LEN(REPLACE(@logs, @Seperators, '')))/LEN(@Seperators));
	PRINT @logs
	PRINT 'Occurance '+ CAST(@occurance as Varchar(10))
	IF(@occurance > 0)
	BEGIN			
		WHILE (@Occurance >= 0)
		BEGIN		
			PRINT 'inloop Occurance '+CAST(@occurance as Varchar(10))
			if(@Occurance > 0)
			BEGIN
				SET @parts = SUBSTRING(@logs, 0, PATINDEX('%'+@Seperators+'%', @logs));
				SET @logs = SUBSTRING(@logs, LEN(@parts + @Seperators)+LEN(@Seperators), LEN(@logs));		
			END
			ELSE
				SET @parts = @logs
			PRINT @parts

			SET @occurance2 = ((LEN(@parts) - LEN(REPLACE(@parts, @delimiters, '')))/LEN(@delimiters));
			IF(@occurance2 > 0)
			BEGIN
				SET @time =  SUBSTRING(@parts, 0, PATINDEX('%'+@delimiters+'%', @parts));
				SET @parts =  SUBSTRING(@parts, (LEN(@time) + LEN(@delimiters))+1, LEN(@parts));	
				SET @type = SUBSTRING(@parts, 0, PATINDEX('%'+@delimiters+'%', @parts));
				SET @parts =  SUBSTRING(@parts, (LEN(@type) + LEN(@delimiters))+1, LEN(@parts));
				SET @message = SUBSTRING(@parts, 0, PATINDEX('%'+@delimiters+'%', @parts));
				SET @stacktrace =  SUBSTRING(@parts, (LEN(@type) + LEN(@delimiters))+1, LEN(@parts));
				SET @utclogdate = CONVERT(DATETIME, DATEADD(MILLISECOND, CONVERT(BIGINT, @time) % 1000, DATEADD(SECOND, CONVERT(BIGINT, @time) / 1000, '19700101')));
				SET @logdate = DATEADD(HH, @timezone, @utclogdate)

				PRINT @time
				PRINT @type
				PRINT @stacktrace
				PRINT @logdate

				EXEC dbo.getMacUserCompanyStatus @mac, @company_id OUTPUT, @user_id OUTPUT, @mac_id OUTPUT
				select @type_id = id from dbo.device_Logtype where LOWER(log_type) = LOWER(@type)

				INSERT INTO dbo.device_log(logdate, type, message, stacktrace, mac_id, timestamp) values(@logdate, @type_id, @message, @stacktrace, @mac_id, GETDATE())
			END
			PRINT 'inloop Occurance '+CAST(@occurance as Varchar(10))
			SET @occurance = @occurance - 1;
		END
	END
	ELSE
	BEGIN		
		SET @occurance2 = ((LEN(@logs) - LEN(REPLACE(@logs, @delimiters, '')))/LEN(@delimiters));
		IF(@occurance2 > 0)
		PRINT '1'
		PRINT @occurance2
		BEGIN
			SET @time =  SUBSTRING(@logs, 0, PATINDEX('%'+@delimiters+'%', @logs));
			SET @parts =  SUBSTRING(@logs, (LEN(@time) + LEN(@delimiters))+1, LEN(@logs));	
			SET @type = SUBSTRING(@parts, 0, PATINDEX('%'+@delimiters+'%', @parts));
			SET @parts =  SUBSTRING(@parts, (LEN(@type) + LEN(@delimiters))+1, LEN(@parts));
			SET @message = SUBSTRING(@parts, 0, PATINDEX('%'+@delimiters+'%', @parts));
			SET @stacktrace =  SUBSTRING(@parts, (LEN(@type) + LEN(@delimiters))+1, LEN(@parts));
			SET @utclogdate = CONVERT(DATETIME, DATEADD(MILLISECOND, CONVERT(BIGINT, @time) % 1000, DATEADD(SECOND, CONVERT(BIGINT, @time) / 1000, '19700101')));
			SET @logdate = DATEADD(HH, @timezone, @utclogdate)
			
			PRINT @time
			PRINT @type
			PRINT @stacktrace
			PRINT @logdate

			EXEC dbo.getMacUserCompanyStatus @mac, @company_id OUTPUT, @user_id OUTPUT, @mac_id OUTPUT				
			select @type_id = id from dbo.device_Logtype where LOWER(log_type) = LOWER(@type)			
					
			INSERT INTO dbo.device_log(logdate, type, message, stacktrace, mac_id, timestamp) values(@logdate, @type_id, @message, @stacktrace, @mac_id, GETDATE())
		END
	END	
END

GO
/****** Object:  StoredProcedure [dbo].[insertExcuse]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:	 Ivan
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[insertExcuse]
@from_date datetime,
@to_date datetime,
@mac varchar(17),
@reason varchar(250),
@type_id int,
@entry_date datetime,
@Pass varchar(250) OUTPUT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @user_id INT
    , @company_id INT 
    , @mac_id INT
	, @macuser_id INT
    , @result INT
	
	EXEC @result = dbo.getMacUserCompanyStatus @mac, @company_id OUTPUT, @user_id OUTPUT, @macuser_id OUTPUT
	set @mac_id = @macuser_id


	Declare @type varchar(50)
	Declare @dispensation int
	select @type = typeName from Excuse_Type where id = @type_id 
	select @dispensation = sick_permitentry_dispensation from company_setting where id = @company_id
		
	SET @Pass = 'ok'
	print CONVERT(DATE,@from_date)
	print CONVERT(DATE, @entry_date)

	if((LOWER(@type) in ('sick', 'permit', 'leave')) and (CONVERT(DATE, @from_date) < CONVERT(DATE, @entry_date)))
	BEGIN		
		SET @Pass = 'this type of request must be entered before the request date'		
	END
	ELSE if((LOWER(@type) in ('allowed late','early leave')) and (((CONVERT(DATE, @from_date) = CONVERT(DATE, @entry_date)) and (CONVERT(TIME, @from_date) <= CONVERT(TIME, @entry_date))) or (CONVERT(DATE, @from_date) < CONVERT(DATE, @entry_date))))
	BEGIN
		SET @Pass = 'this type of request must be entered before the request time'		
	END
	ELSE if((LOWER(@type) in ('allowed late','early leave')) and (CONVERT(DATE, @from_date) != CONVERT(DATE, @to_date)))
	BEGIN
		SET @Pass = 'this type of request from and to date must be on the same day'		
	END
	Else if ((LOWER(@type) = 'overtime') and ((CONVERT(DATE, @from_date) > CONVERT(DATE, @entry_date)) or ((CONVERT(DATE, @from_date) = CONVERT(DATE, @entry_date) and CONVERT(TIME, @from_date) > CONVERT(TIME, @entry_date)))))
	BEGIN
		SET @Pass = 'overtime request must be entered after overtime' 
	END

	print @Pass

	if(@pass = 'ok')
	BEGIN
		insert into 
		excuse(from_date, to_date, user_id, mac_id, excuse_reason, type, approved, entry_date)
		values(@from_date, @to_date, @user_id, @mac_id, @reason,@type_id, 0, @entry_date)
	END


END

GO
/****** Object:  StoredProcedure [dbo].[insertTraceAbsen]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[insertTraceAbsen]
@absenDate datetime,
@macId int

as

set nocount off;
insert loginhistory(login,mac_id) values (@absenDate,@macId);


GO
/****** Object:  StoredProcedure [dbo].[monthlyReport]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[monthlyReport]  
 @gmt int,
 @from DATETIME,  
 @to DATETIME
AS

--exec monthlyReport 7, '2014-09-01', '2014-10-01'
PRINT 'a'

DECLARE 
 @late_barrier DATETIME

SELECT
 @late_barrier = CAST('1900-01-01 11:00:00' AS DATETIME)
 , @from = DATEADD(HOUR, -1 * @gmt, DATEADD(MONTH, DATEDIFF(MONTH, 0, @from), 0)) -- set to the first day of the month of fromdate
 , @to = DATEADD(HOUR, -1 * @gmt, DATEADD(SECOND, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @to) + 1, 0))) -- set to the first day of the month of fromdate

SELECT 
 mac_id
 , name
 , [Month]
 , [Year]
 , IsLateCount = sum(IsLate)
 , IsNotFullCount = sum(IsNotFull)
 , IsFullCount = sum(IsFull)
 , IsOT12BelowCount = sum(IsOT12Below)
 , IsOT12UpCount = sum(IsOT12Up)
 , FullTimeComparison = (CASE WHEN sum(FullTimeComparisonSeconds) >= 0 THEN CONVERT(VARCHAR,DATEADD(s, sum(FullTimeComparisonSeconds), 0), 108) ELSE '-' + CONVERT(VARCHAR,DATEADD(s, sum(FullTimeComparisonSeconds) * -1, 0), 108) END)
 , InDayCount = sum(IsInDay)
 , OutDayCount = sum(IsOutDay)
 , WorkDayCount = sum(IsWorkDay)
FROM (
SELECT 
 mac_id
 , m.owner as name
 , [Month] = month(DATEADD(hh, @gmt, first_login))
 , [Year] = year(DATEADD(hh, @gmt, first_login))
 , IsLate = (CASE WHEN CONVERT(DATETIME, CONVERT(VARCHAR,DATEADD(hh, @gmt, first_login), 108)) >= CONVERT(DATETIME, @late_barrier) AND a.STATUS < 2 THEN 1 ELSE 0 END)
 , IsNotFull = (CASE WHEN NOT DATEDIFF(s,DATEADD(hh, @gmt, first_login),DATEADD(hh, @gmt, last_login)) >= 32400 AND a.[status] < 2 THEN 1 ELSE 0 END)
 , IsFull = (CASE WHEN DATEDIFF(s,DATEADD(hh, @gmt, first_login),DATEADD(hh, @gmt, last_login)) >= 32400 OR A.[STATUS] = 2 THEN 1 ELSE 0 END)
 , IsOT12Below = (CASE WHEN DATEDIFF(s,DATEADD(hh, @gmt, first_login),DATEADD(hh, @gmt, last_login)) >= 39600 AND NOT DATEDIFF(d,DATEADD(hh, @gmt, first_login),DATEADD(hh, @gmt, last_login)) > 0  THEN 1 ELSE 0 END)
 , IsOT12Up = (CASE WHEN DATEDIFF(s,DATEADD(hh, @gmt, first_login),DATEADD(hh, @gmt, last_login)) >= 39600 AND DATEDIFF(d,DATEADD(hh, @gmt, first_login),DATEADD(hh, @gmt, last_login)) > 0  THEN 1 ELSE 0 END)
 , FullTimeComparisonSeconds = CASE WHEN a.STATUS < 2 THEN DATEDIFF(s,DATEADD(hh, @gmt, first_login),DATEADD(hh, @gmt, last_login)) - 32400 ELSE 0 END
 , IsInDay = (CASE WHEN CONVERT(DATETIME, CONVERT(VARCHAR,DATEADD(hh, @gmt, first_login), 108)) <> CONVERT(DATETIME, '1900-01-01 00:00:00') OR a.[status] > 0 THEN 1 ELSE 0 END)
 , IsOutDay = (CASE WHEN CONVERT(DATETIME, CONVERT(VARCHAR,DATEADD(hh, @gmt, first_login), 108)) = CONVERT(DATETIME, '1900-01-01 00:00:00') AND a.[status] = 0  THEN 1 ELSE 0 END)
 , IsWorkDay = 1
FROM absen a (NOLOCK) inner join mac m (NOLOCK) on a.mac_id = m.id
WHERE first_login BETWEEN @from AND @to and m.status = 1) A 
GROUP BY A.mac_id, A.name, A.[Month], A.[Year]
ORDER BY a.mac_id asc, A.[Year] desc, A.[Month] desc

GO
/****** Object:  StoredProcedure [dbo].[moveDaily2Archive]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[moveDaily2Archive]
(
    @limit DATETIME = NULL
)
AS
BEGIN -- PROCEDURE
    SET NOCOUNT ON

    IF (@limit IS NULL)  SET @limit = DATEADD(DAY, -1, [dbo].[getDateOnly](GETDATE()))

    DECLARE @temp_table TABLE
    (
        login_id INT NOT NULL PRIMARY KEY
    )

    BEGIN TRY
        INSERT INTO @temp_table (login_id)
            SELECT id FROM [login] WITH (NOLOCK) WHERE first_login < @limit    

        BEGIN TRANSACTION
        --copy from [login] to [archive_login]
        --select * from login
        INSERT INTO archive_login (id, [user_id], first_login, last_login, logout_time, start_overtime, login_elapse_time, overtime_elapse_time, is_late, is_full, [login_type], [timestamp])
            SELECT id, [user_id], first_login, last_login, logout_time, start_overtime, login_elapse_time, overtime_elapse_time, is_late, is_full, [login_type], [timestamp]
                FROM [login] l WITH (NOLOCK) INNER JOIN @temp_table t ON l.id = t.login_id
        --select * from archive_login


        --copy from [login_history] to [archive_login_history]
        --select * from login_history
        INSERT INTO archive_login_history (login_id, mac_id, login_date, ip_address, createdate)
            SELECT lh.login_id, lh.mac_id, lh.login_date, lh.ip_address, lh.createdate
                FROM login_history lh WITH (NOLOCK) INNER JOIN @temp_table t ON lh.login_id = t.login_id
        --select * from archive_login_history

        --delete login_history
        DELETE FROM login_history 
            WHERE login_id IN (SELECt login_id FROM @temp_table)
        --select * from login_history

        --delete login
        DELETE FROM [login]
            WHERE id IN (SELECT login_id FROM @temp_table)
        --select * from login

        COMMIT TRANSACTION
        --ROLLBACK TRANSACTION
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION

        DECLARE @ErrMsg NVARCHAR(MAX), @ErrSeverity INT
        SELECT @ErrMsg = ERROR_MESSAGE(),
             @ErrSeverity = ERROR_SEVERITY()

        RAISERROR(@ErrMsg, @ErrSeverity, 1)
    END CATCH

END -- PROCEDURE



GO
/****** Object:  StoredProcedure [dbo].[moveMonthly2Archive]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[moveMonthly2Archive]
(
    @limit DATETIME = NULL
)
AS
BEGIN -- PROCEDURE
    SET NOCOUNT ON

    IF (@limit IS NULL)  SET @limit = DATEADD(MONTH, -2, GETDATE())

    DECLARE @limitFirstDay DATETIME
    , @limitLastDay DATETIME

    SELECT @limitFirstDay = [dbo].[firstDayOfMonth](@limit)
    , @limitLastDay = [dbo].[lastDayOfMonth](@limit)

    DECLARE @count INT
    SELECT @count= COUNT(*) 
        FROM archive_monthly
        WHERE report_year = DATEPART(YEAR, @limit)
            AND report_month = DATEPART(MONTH, @limit)

    IF (@count < 1)
    BEGIN
        INSERT INTO login_monthly(report_year, report_month, user_id, count_late, count_not_full, count_full, sum_overtime_elapse_time, overtime_elapse_time, sum_login_elapse_time, login_elapse_time, count_not_login, count_login, total_login)
        SELECT report_year
            , report_month
            , [user_id]
            , count_late = SUM(is_late) 
            , count_not_full = SUM(
                CASE
                    WHEN is_full = 0 THEN 1
                    ELSE 0
                END
            )
            , count_full = SUM(
                CASE
                    WHEN is_full = 1 THEN 1
                    ELSE 0
                END
            ) 
            , sum_overtime_elapsed_time = SUM(overtime_elapse_time)
            , overtime_elapsed_time = CASE 
                WHEN SUM(overtime_elapse_time) >= 0 
                    THEN CONVERT(VARCHAR,DATEADD(s, SUM(overtime_elapse_time), 0), 108) 
                ELSE 
                    '00:00:00'
            END
            , sum_login_elapsed_time = SUM(login_quota)
            , login_elapsed_time = CASE 
                WHEN SUM(login_quota) >= 0 
                    THEN CONVERT(VARCHAR,DATEADD(s, SUM(login_quota), 0), 108) 
                ELSE 
                    '-' + CONVERT(VARCHAR,DATEADD(s, SUM(login_quota) * -1, 0), 108) 
            END
            , count_not_login = SUM(
                CASE
                    WHEN [login_type] = 0 THEN 1
                    ELSE 0
                END
            ) 
            , count_login = SUM(
                CASE
                    WHEN [login_type] > 0 THEN 1
                    ELSE 0
                END
            ) 
            , total_login = COUNT([user_id])
        FROM
        (
            SELECT report_year = DATEPART(YEAR, l.first_login) 
                , report_month = DATEPART(MONTH, l.first_login) 
                , l.[user_id]
                , login_quota = CASE
                    WHEN [login_type] < 2 THEN login_elapse_time - dbo.calculateQuota(9,1)
                    ELSE 0
                END
                , l.overtime_elapse_time
                , l.is_late
                , l.is_full
                , l.[login_type]
                FROM [archive_login] l WITH (NOLOCK) 
                    INNER JOIN users u WITH (NOLOCK) ON l.[user_id] = u.id
                    WHERE l.first_login BETWEEN @limitFirstDay AND @limitLastDay
        ) report_monthly
        GROUP BY report_year, report_month, [user_id]
    END
END -- PROCEDURE



GO
/****** Object:  StoredProcedure [dbo].[Overtime]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ivan
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Overtime]
@user_id int,
@login_type int,
@from_date datetime,
@to_date datetime,
@result int OUTPUT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		    
	DECLARE @nowutc DATETIME 
		, @login_date DATETIME
		, @today_time_begin SMALLINT
        , @time_begin SMALLINT
        , @time_end SMALLINT
        , @time_overtime SMALLINT
        , @timezone SMALLINT
		, @limit_late DATETIME
        , @logout_date DATETIME
		, @login_start_overtime DATETIME
		, @is_late BIT
		, @login_id INT

	 
		if((CONVERT(DATE,@from_date) < CONVERT(DATE, GETDATE())) and (CONVERT(TIME,@from_date) < CONVERT(TIME, GETDATE())))
		BEGIN   
			declare @loginType varchar(20)
			select @login_id = z.id, @loginType = x.login_type 
			from login z join login_type x on z.login_type = x.id
			where CONVERT(DATE, z.first_login) = CONVERT(DATE, @from_date) and z.user_id = user_id

			if(@login_id > 0 and @loginType != 'Absent')
			BEGIN
				Declare @overtime int = 0
				select @overtime = overtime_elapse_time from login where id = @login_id
				if(@Overtime > 0)
					BEGIN
						set @result = 'ok';
					END					
				ELSE
					BEGIN
						set @result = 'no overtime found';
					END
				END		
			ELSE 
			BEGIN
				set @result = 'user Absent';
			END
		END
		ELSE 
		BEGIN
			SET @result = 'cant approve before overtime done';
		END
	
END

GO
/****** Object:  StoredProcedure [dbo].[permitLeaveLogin]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ivan
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[permitLeaveLogin]
@user_id int,
@login_type int,
@from_date datetime,
@to_date datetime

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	declare @company_id int 
	 select @company_id = company_id 
	  FROM  users u    
    INNER JOIN company_setting cs ON u.company_id = cs.id
	where u.id = @user_id
    
	DECLARE @nowutc DATETIME 
		, @login_date DATETIME
		, @today_time_begin SMALLINT
        , @time_begin SMALLINT
        , @time_end SMALLINT
        , @time_overtime SMALLINT
        , @timezone SMALLINT
		, @limit_late DATETIME
        , @logout_date DATETIME
		, @login_start_overtime DATETIME
		, @is_late BIT
		
		       
	 SELECT @today_time_begin = today_time_begin
        , @time_begin = time_begin
        , @time_end = time_end
        , @time_overtime = time_overtime
        , @timezone = timezone        
        FROM dbo.getCompanySetting(@company_id)
			
	DECLARE @OCCURANCE INT = 0;
	SET @OCCURANCE = DATEDIFF(day, @from_date, @to_date);
	DECLARE @date DATETIME = @from_date;
	WHILE(@OCCURANCE >= 0)	
	begin
		
		print @date
		SET @limit_late = DATEADD(HOUR, @time_begin, dbo.getDateOnly(@date))
		SET @login_date = @limit_late
		SELECT @logout_date = DATEADD(HOUR,@time_end,@limit_late), @login_start_overtime = DATEADD(HOUR,@time_overtime,@logout_date)
		SET @is_late = 0	

		declare @loginType varchar(20) 
		declare @login_id int = 0

		select @login_id = z.id, @loginType = x.login_type 
		from login z join login_type x on z.login_type = x.id
		where (CONVERT(DATE, z.first_login) = CONVERT(DATE, @date)) and z.user_id = user_id

		if(@login_id < 1 or ((@login_id > 0) and @loginType = 'Absent'))
		BEGIN		
		begin try		
			INSERT INTO login (user_id, first_login, last_login, logout_time, start_overtime, is_late, login_type) 
            VALUES (@user_id, @login_date, @login_date, @login_date, @login_date, @is_late, @login_type)		
		end TRY
		BEGIN catch			
			 SELECT 
				ERROR_NUMBER() AS ErrorNumber
			   , ERROR_MESSAGE() AS ErrorMessage;
		END CATCH
		END
		SET @date = DATEADD(DAY, 1, @date)
		SET @OCCURANCE = @OCCURANCE - 1;
	end 	
END

GO
/****** Object:  StoredProcedure [dbo].[reportDaily]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[reportDaily]
    @mac VARCHAR(17)
    , @mac_list VARCHAR(MAX)
    , @from_date DATETIME
    , @to_date DATETIME
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @user_id INT
    , @company_id INT 
    , @mac_id INT
    , @result INT

	DECLARE @inv VARCHAR(20)
	DECLARE @tmp_macList VARCHAR(MAX)
	DECLARE @cond2 VARCHAR(MAX)

	/*WHILE LEN(@tmp_macList) > 0
	BEGIN
		
		IF (PATINDEX('%|%',@tmp_macList) > 0)
		BEGIN
			SET @inv = SUBSTRING(@tmp_macList, 0, PATINDEX('%|%',@tmp_macList))
			PRINT @tmp_macList
			PRINT @inv
			
			IF(LEN(@cond2) > 0)
			BEGIN
				SET @cond2 = @cond2+' , '''+@inv+''''
			END
			ELSE
			BEGIN
				SET @cond2 = 'WHERE mac IN ('''+@inv+''''
			END

			SET @tmp_macList = SUBSTRING(@tmp_macList, LEN(@inv + '|') + 1, LEN(@tmp_macList))
		END
		ELSE
		BEGIN
			SET @inv = @tmp_macList
				IF(LEN(@cond2) > 0)
			BEGIN
				SET @cond2 = @cond2+', '''+@inv+''''
			END
			ELSE
			BEGIN
				SET @cond2 = 'WHERE mac IN ('''+@inv+''''
			END
			SET @tmp_macList = NULL
			
		END

		PRINT @cond2
	END*/

	SET @cond2 =  ' WHERE mac IN ('+@mac_list+'))'

    EXEC @result = dbo.getMacUserCompanyStatus @mac, @company_id OUTPUT, @user_id OUTPUT, @mac_id OUTPUT

	DECLARE @totalq NVARCHAR(MAX)

	DECLARE @q VARCHAR(MAX) = 'SELECT u.name [user_name]
            , l.first_login
            , l.last_login
            , l.logout_time
            , l.start_overtime
            , l.login_elapse_time
            , l.overtime_elapse_time
            , overtime = CASE
                WHEN l.overtime_elapse_time > 0 THEN CONVERT(VARCHAR, DATEADD(s, l.overtime_elapse_time, 0), 108) 
                ELSE CONVERT(VARCHAR,DATEADD(s, 0, 0), 108) 
            END	
            , l.is_late
            , l.is_full
            , lt.login_type
        FROM [login] l WITH (NOLOCK) 
			JOIN login_tpype lt on l.login_type = lt.id
            INNER JOIN users u WITH (NOLOCK) ON l.[user_id] = u.id
            AND l.[user_id] IN (
                SELECT [user_id] FROM users_macs WITH (NOLOCK) '
	
	DECLARE @uq VARCHAR(MAX) = ' UNION SELECT u.name [user_name]
            , l.first_login
            , l.last_login
            , l.logout_time
            , l.start_overtime
            , l.login_elapse_time
            , l.overtime_elapse_time
            , overtime = CASE
                WHEN l.overtime_elapse_time > 0 THEN CONVERT(VARCHAR, DATEADD(s, l.overtime_elapse_time, 0), 108) 
                ELSE CONVERT(VARCHAR,DATEADD(s, 0, 0), 108) 
            END
            , l.is_late
            , l.is_full
            , lt.login_type
        FROM [archive_login] l WITH (NOLOCK) 
			JOIN login_tpype lt on l.login_type = lt.id
            INNER JOIN users u WITH (NOLOCK) ON l.[user_id] = u.id
            AND l.[user_id] IN (
                SELECT [user_id] FROM users_macs WITH (NOLOCK) '
				
	DECLARE @cond VARCHAR(MAX)= ' AND l.first_login BETWEEN CONVERT(DATETIME, '''+ CONVERT(VARCHAR(30), @from_date) +''') AND CONVERT(DATETIME, '''+ CONVERT(VARCHAR(30),@to_date) + ''')'

	SELECT @from_date = dbo.getDateOnly(@from_date)
        , @to_date = dbo.getDateOnly(DATEADD(DAY, 1, @to_date))

	SET @totalq = @q+@cond2+@cond+@uq+@cond2+@cond

	PRINT @totalq

    IF (@result = 0)
    BEGIN
		EXEC sp_executesql @totalq
	END
   
END


GO
/****** Object:  StoredProcedure [dbo].[reportMonthly]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[reportMonthly]
    @mac VARCHAR(17)
    , @mac_list VARCHAR(MAX)
    , @from_date DATETIME
    , @to_date DATETIME
AS
BEGIN
    SET NOCOUNT ON
    DECLARE @user_id INT
    , @company_id INT 
    , @mac_id INT
    , @result INT


    EXEC @result = dbo.getMacUserCompanyStatus @mac, @company_id OUTPUT, @user_id OUTPUT, @mac_id OUTPUT

	DECLARE @q NVARCHAR(MAX)

    IF (@result = 0)
    BEGIN
       
        SET @q = 'SELECT report_year, report_month, [user_id], [name], count_late, count_not_full, count_full, count_sick, count_leave, count_permit, count_AllowedLate, count_earlyLeave, overtime_elapse_time, login_elapse_time, count_not_login, count_login, total_login
        FROM
        (
            SELECT report_year
                , report_month
				, [name]
                , [user_id]
                , count_late = SUM(is_late) 
                , count_not_full = SUM(
                    CASE
                        WHEN is_full = 0 THEN 1
                        ELSE 0
                    END
                )
                , count_full = SUM(
                    CASE
                        WHEN is_full = 1 THEN 1
                        ELSE 0
                    END
                ) 
                , overtime_elapse_time = CASE 
                    WHEN SUM(overtime_elapse_time) >= 0 
                        THEN CONVERT(VARCHAR,DATEADD(s, SUM(overtime_elapse_time), 0), 108) 
                    ELSE 
                        ''00:00:00''
                END
                , login_elapse_time = CASE 
                    WHEN SUM(login_quota) >= 0 
                        THEN CONVERT(VARCHAR,DATEADD(s, SUM(login_quota), 0), 108) 
                    ELSE 
                        ''-'' + CONVERT(VARCHAR,DATEADD(s, SUM(login_quota) * -1, 0), 108) 
                END
                , count_not_login = SUM(
                    CASE
                        WHEN [login_type] = ''Absent'' THEN 1
                        ELSE 0
                    END
                ) 
                , count_login = SUM(
                    CASE
                        WHEN [login_type] = ''Normal'' THEN 1
                        ELSE 0
                    END
                ) 
				  , count_sick = SUM(
                    CASE
                        WHEN [login_type] = ''Sick'' THEN 1
                        ELSE 0
                    END
                ) 
				  , count_permit = SUM(
                    CASE
                        WHEN [login_type] = ''Permit'' THEN 1
                        ELSE 0
                    END
                )  , count_leave = SUM(
                    CASE
                        WHEN [login_type] = ''Leave'' THEN 1
                        ELSE 0
                    END
                )    , count_earlyLeave = SUM(
                    CASE
                        WHEN [login_type] = ''Early Leave'' THEN 1
                        ELSE 0
                    END
                )   , count_AllowedLate = SUM(
                    CASE
                        WHEN [login_type] = ''Allowed Late'' THEN 1
                        ELSE 0
                    END
                )  , total_login = COUNT([user_id])
            FROM
            (
                SELECT l.[user_id], l.[name], report_year = DATEPART(YEAR, l.first_login) 
                    , report_month = DATEPART(MONTH, l.first_login) 
                    , login_quota = CASE
                        WHEN lt.[login_type] = ''Normal'' THEN login_elapse_time - dbo.calculateQuota(9,1)
                        ELSE 0
                    END
                    , l.overtime_elapse_time
                    , l.is_late
                    , l.is_full
                    , lt.[login_type]
                    FROM [login] l WITH (NOLOCK) 
                        INNER JOIN users u WITH (NOLOCK) ON l.[user_id] = u.id
                        AND l.first_login BETWEEN CONVERT(DATETIME, '''+ CONVERT(VARCHAR(30), @from_date) +''') AND CONVERT(DATETIME, '''+ CONVERT(VARCHAR(30),@to_date) + ''')
                        INNER JOIN dbo.users_macs t ON l.[user_id] = t.[user_id]
						JOIN dbo.login_type lt ON l.login_type = lt.id
						WHERE t.mac IN ('+ @mac_list +')
						
                UNION
                SELECT l.[user_id], l.[name], report_year = DATEPART(YEAR, l.first_login) 
                    , report_month = DATEPART(MONTH, l.first_login) 
                    , login_quota = CASE
                        WHEN lt.[login_type] = ''Normal'' THEN login_elapse_time - dbo.calculateQuota(9,1)
                        ELSE 0
                    END
                    , l.overtime_elapse_time
                    , l.is_late
                    , l.is_full
                    , lt.[login_type]
                    FROM [archive_login] l WITH (NOLOCK) 
                        INNER JOIN users u WITH (NOLOCK) ON l.[user_id] = u.id
                        AND l.first_login BETWEEN CONVERT(DATETIME, '''+ CONVERT(VARCHAR(30), @from_date) +''') AND CONVERT(DATETIME, '''+ CONVERT(VARCHAR(30),@to_date) + ''')
                         INNER JOIN dbo.users_macs t ON l.[user_id] = t.[user_id]
						JOIN dbo.login_type lt ON l.login_type = lt.id
						WHERE t.mac IN ('+ @mac_list +')
            ) report
            GROUP BY report_year, report_month, [user_id]
            
        ) report_monthly
        ORDER BY report_year DESC, report_month DESC, [user_id]'

		PRINT @q

		/*UNION
            SELECT report_year, report_month, [user_id], count_late, count_not_full, count_full, count_sick, count_leave, count_permit, count_AllowedLate, count_earlyLeave, overtime_elapse_time, login_elapse_time, count_not_login, count_login, total_login
                FROM login_monthly WITH (NOLOCK) 
                WHERE report_year BETWEEN DATEPART(YEAR, @from_date) AND DATEPART(YEAR, @to_date) 
                AND report_month BETWEEN DATEPART(MONTH, @from_date) AND DATEPART(MONTH, @to_date) 
                AND [user_id] IN (SELECT [user_id] FROM @temp_table)*/

		EXEC sp_executesql @q
    END

    RETURN @result
END


GO
/****** Object:  UserDefinedFunction [dbo].[calculateQuota]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[calculateQuota]
(
    -- Add the parameters for the function here
    @quota INT
    , @type INT -- 0: to minute, 1: to second
)
RETURNS INT
AS
BEGIN
    -- Declare the return variable here
    DECLARE @hour_to_minute INT
    , @minute_to_second INT
    , @result INT
    
    SELECT @hour_to_minute = 60
    , @minute_to_second = 60

    -- Add the T-SQL statements to compute the return value here
    SELECT @result = (
        CASE 
            WHEN @type = 0 THEN @quota * @hour_to_minute
            WHEN @type = 1 THEN @quota * @hour_to_minute * @minute_to_second
            ELSE @quota
        END
    )

    -- Return the result of the function
    RETURN @result

END


GO
/****** Object:  UserDefinedFunction [dbo].[firstDayOfMonth]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[firstDayOfMonth]
(
    -- Add the parameters for the function here
    @ref_datetime DATETIME
)
RETURNS DATETIME
AS
BEGIN
    -- Declare the return variable here
    -- Add the T-SQL statements to compute the return value here
    SELECT @ref_datetime = DATEADD(MONTH, DATEDIFF(MONTH,0,@ref_datetime),0)

    -- Return the result of the function
    RETURN @ref_datetime

END


GO
/****** Object:  UserDefinedFunction [dbo].[getDateOnly]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[getDateOnly]
(
    -- Add the parameters for the function here
    @ref_datetime DATETIME
)
RETURNS DATETIME
AS
BEGIN
    -- Declare the return variable here
    -- Add the T-SQL statements to compute the return value here
    SELECT @ref_datetime = DATEADD(DAY, DATEDIFF(DAY, 0, @ref_datetime), 0)

    -- Return the result of the function
    RETURN @ref_datetime

END


GO
/****** Object:  UserDefinedFunction [dbo].[hasLoggedInToday_]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[hasLoggedInToday_]
(
    -- Add the parameters for the function here
    @user_id INT
    , @login_date DATETIME
    , @today_time_begin SMALLINT
)
RETURNS INT
AS
BEGIN
    -- Declare the return variable here
    DECLARE @limit_first DATETIME
    , @limit_last DATETIME
    , @login_id INT

    -- Add the T-SQL statements to compute the return value here
    SELECT @limit_first = DATEADD(HOUR,@today_time_begin, dbo.getDateOnly(@login_date))
    , @limit_last = DATEADD(DAY, 1, @limit_first)

    --SELECT @limit_first, @limit_last

    SELECT @login_id = id 
    FROM login 
    WHERE user_id = @user_id
    AND first_login >= @limit_first
    AND last_login < @limit_last

    -- Return the result of the function
    RETURN @login_id

END



GO
/****** Object:  UserDefinedFunction [dbo].[lastDayOfMonth]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [dbo].[lastDayOfMonth]
(
    -- Add the parameters for the function here
    @ref_datetime DATETIME
)
RETURNS DATETIME
AS
BEGIN
    -- Declare the return variable here
    -- Add the T-SQL statements to compute the return value here
    SELECT @ref_datetime = DATEADD(SECOND,-1,DATEADD(MONTH, DATEDIFF(MONTH,0,@ref_datetime)+1,0))

    -- Return the result of the function
    RETURN @ref_datetime

END


GO
/****** Object:  Table [dbo].[archive_login]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[archive_login](
	[id] [int] NOT NULL,
	[user_id] [int] NOT NULL,
	[first_login] [datetime] NOT NULL,
	[last_login] [datetime] NOT NULL,
	[logout_time] [datetime] NOT NULL,
	[start_overtime] [datetime] NOT NULL,
	[login_elapse_time] [int] NOT NULL,
	[overtime_elapse_time] [int] NOT NULL,
	[is_late] [smallint] NOT NULL,
	[is_full] [smallint] NOT NULL,
	[login_type] [smallint] NOT NULL,
	[timestamp] [datetime] NOT NULL,
	[is_overtime] [bit] NULL,
 CONSTRAINT [PK_archive_login] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[archive_login_history]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[archive_login_history](
	[login_id] [int] NOT NULL,
	[mac_id] [int] NOT NULL,
	[login_date] [datetime] NOT NULL,
	[ip_address] [varchar](15) NOT NULL,
	[createdate] [datetime] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[company_setting]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[company_setting](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](50) NOT NULL,
	[timezone] [smallint] NOT NULL,
	[time_begin] [smallint] NOT NULL,
	[time_end] [smallint] NOT NULL,
	[time_overtime] [smallint] NOT NULL,
	[today_time_begin] [smallint] NOT NULL,
	[status] [bit] NULL,
	[createdate] [datetime] NOT NULL,
	[timestamp] [datetime] NOT NULL,
	[sick_permitentry_dispensation] [int] NULL,
 CONSTRAINT [PK_company_setting] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[device_Log]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[device_Log](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[mac_id] [int] NOT NULL,
	[logdate] [datetime] NOT NULL,
	[type] [int] NOT NULL,
	[message] [varchar](max) NOT NULL,
	[stacktrace] [varchar](max) NOT NULL,
	[timestamp] [datetime] NOT NULL,
 CONSTRAINT [PK_device_Log] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[device_Logtype]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[device_Logtype](
	[id] [int] NOT NULL,
	[log_type] [varchar](10) NOT NULL,
 CONSTRAINT [PK_device_Logtype] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Excuse]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Excuse](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[from_date] [datetime] NOT NULL,
	[to_date] [datetime] NOT NULL,
	[user_id] [int] NOT NULL,
	[mac_id] [int] NOT NULL,
	[excuse_reason] [text] NOT NULL,
	[approved] [bit] NOT NULL,
	[type] [int] NULL,
	[entry_date] [datetime] NOT NULL,
	[created_date] [datetime] NOT NULL,
 CONSTRAINT [PK_Excuse_1] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Excuse_Type]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Excuse_Type](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[typeName] [varchar](20) NOT NULL,
 CONSTRAINT [PK_Excuse_Type] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[groups]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[groups](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](50) NOT NULL,
	[createdate] [datetime] NOT NULL,
	[timestamp] [datetime] NOT NULL,
 CONSTRAINT [PK_groups] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[groups_rights]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[groups_rights](
	[group_id] [int] NOT NULL,
	[right_id] [int] NOT NULL,
	[createdate] [datetime] NOT NULL,
 CONSTRAINT [PK_groups_rights_1] PRIMARY KEY CLUSTERED 
(
	[group_id] ASC,
	[right_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[holiday]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[holiday](
	[date] [datetime] NOT NULL,
	[detail] [varchar](300) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[login]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[login](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[user_id] [int] NOT NULL,
	[first_login] [datetime] NOT NULL,
	[last_login] [datetime] NOT NULL,
	[logout_time] [datetime] NOT NULL,
	[start_overtime] [datetime] NOT NULL,
	[login_elapse_time] [int] NOT NULL,
	[overtime_elapse_time] [int] NOT NULL,
	[is_late] [smallint] NOT NULL,
	[is_full] [smallint] NOT NULL,
	[login_type] [int] NOT NULL,
	[timestamp] [datetime] NOT NULL,
	[is_overtime] [bit] NULL,
 CONSTRAINT [PK_login] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[login_history]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[login_history](
	[login_id] [int] NOT NULL,
	[mac_id] [int] NOT NULL,
	[login_date] [datetime] NOT NULL,
	[ip_address] [varchar](15) NOT NULL,
	[createdate] [datetime] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[login_monthly]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[login_monthly](
	[report_year] [int] NOT NULL,
	[report_month] [int] NOT NULL,
	[user_id] [int] NOT NULL,
	[count_late] [smallint] NOT NULL,
	[count_not_full] [smallint] NOT NULL,
	[count_full] [smallint] NOT NULL,
	[sum_overtime_elapse_time] [int] NOT NULL,
	[overtime_elapse_time] [varchar](9) NOT NULL,
	[sum_login_elapse_time] [int] NOT NULL,
	[login_elapse_time] [varchar](9) NOT NULL,
	[count_not_login] [smallint] NOT NULL,
	[count_login] [smallint] NOT NULL,
	[total_login] [smallint] NOT NULL,
	[createdate] [datetime] NOT NULL,
	[count_sick] [int] NOT NULL,
	[count_permit] [int] NOT NULL,
	[count_leave] [int] NOT NULL,
	[count_earlyLeave] [int] NOT NULL,
	[count_AllowedLate] [int] NOT NULL,
 CONSTRAINT [PK_archive_monthly] PRIMARY KEY CLUSTERED 
(
	[report_year] DESC,
	[report_month] DESC,
	[user_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[login_type]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[login_type](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[login_type] [varchar](20) NOT NULL,
 CONSTRAINT [PK_login_type] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[loginhistory]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[loginhistory](
	[login] [datetime] NOT NULL,
	[mac_id] [int] NOT NULL,
	[IP] [varchar](15) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[mac]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[mac](
	[id] [int] NOT NULL,
	[mac] [varchar](17) NOT NULL,
	[owner] [varchar](100) NOT NULL,
	[can_approve] [bit] NOT NULL,
	[status] [tinyint] NULL,
 CONSTRAINT [PK_mac] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[rights]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[rights](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](50) NOT NULL,
	[createdate] [datetime] NOT NULL,
	[timestamp] [datetime] NOT NULL,
 CONSTRAINT [PK_rights] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[users]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[users](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[company_id] [int] NOT NULL,
	[name] [varchar](50) NOT NULL,
	[status] [bit] NOT NULL,
	[createddate] [datetime] NOT NULL,
	[timestamp] [datetime] NOT NULL,
 CONSTRAINT [PK_users] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[users_groups]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[users_groups](
	[user_id] [int] NOT NULL,
	[group_id] [int] NOT NULL,
	[status] [bit] NOT NULL,
	[createdate] [datetime] NOT NULL,
 CONSTRAINT [PK_users_groups] PRIMARY KEY CLUSTERED 
(
	[user_id] ASC,
	[group_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[users_macs]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[users_macs](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[user_id] [int] NOT NULL,
	[name] [varchar](50) NOT NULL,
	[mac] [varchar](17) NOT NULL,
	[status] [bit] NOT NULL,
	[createdate] [datetime] NOT NULL,
	[timestamp] [datetime] NOT NULL,
 CONSTRAINT [PK_users_macs] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  UserDefinedFunction [dbo].[getCompanySetting]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:        <Author,,Name>
-- Create date: <Create Date,,>
-- Description:    <Description,,>
-- =============================================
CREATE FUNCTION [dbo].[getCompanySetting]
(    
    -- Add the parameters for the function here
    @company_id INT
)
RETURNS TABLE 
AS
RETURN 
(
    -- Add the SELECT statement with parameter references here
    SELECT timezone
    , time_begin
    , time_end
    , time_overtime
    , today_time_begin
    --, DATEADD(HOUR, time_begin, dbo.getDateOnly(@ref_datetime)) limit_late
    --, DATEADD(MINUTE, 1439, dbo.getDateOnly(@ref_datetime)) limit_overtime_before_24
    --, DATEADD(HOUR, 1440, dbo.getDateOnly(@ref_datetime)) limit_overtime_after_24
    FROM company_setting
    where id = @company_id
)


GO
/****** Object:  UserDefinedFunction [dbo].[getMacUserCompanyByMAC]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[getMacUserCompanyByMAC]
(    
    -- Add the parameters for the function here
    @mac VARCHAR(17)
)
RETURNS TABLE 
AS
RETURN 
(
    -- Add the SELECT statement with parameter references here
    SELECT u.company_id, m.id mac_id, um.user_id, um.name device_name, um.mac, um.status mac_status, ug.status user_group_status, u.status user_status, cs.status company_status
    FROM users_macs um JOIN users u ON um.user_id = u.id
	INNER JOIN mac m ON um.mac = m.mac
    INNER JOIN users_groups ug ON ug.user_id = u.id
    INNER JOIN company_setting cs ON u.company_id = cs.id
    WHERE um.mac = @mac
)


GO
/****** Object:  UserDefinedFunction [dbo].[isMacRegistered]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================
-- Template generated from Template Explorer using:
CREATE FUNCTION [dbo].[isMacRegistered]
(    
    -- Add the parameters for the function here
    @mac VARCHAR(17)
    , @status BIT
)
RETURNS TABLE 
AS
RETURN 
(
    -- Add the SELECT statement with parameter references here
    SELECT id mac_id, user_id, name, mac, status mac_status
    FROM users_macs
    WHERE mac = @mac
    AND status = @status
)


GO
/****** Object:  View [dbo].[UserCompanyByMAC]    Script Date: 6/26/2015 5:42:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[UserCompanyByMAC]
AS
SELECT        u.company_id, m.id AS mac_id, um.user_id, um.name AS device_name, u.name, um.mac, um.status AS mac_status, ug.status AS user_group_status, 
                         u.status AS user_status, cs.status AS company_status
FROM            dbo.users_macs AS um INNER JOIN
                         dbo.users AS u ON um.user_id = u.id INNER JOIN
                         dbo.mac AS m ON um.mac = m.mac INNER JOIN
                         dbo.users_groups AS ug ON ug.user_id = u.id INNER JOIN
                         dbo.company_setting AS cs ON u.company_id = cs.id

GO
INSERT [dbo].[archive_login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (18, 3, CAST(0x0000A4A600B90559 AS DateTime), CAST(0x0000A4A600B90559 AS DateTime), CAST(0x0000A4A6014D5619 AS DateTime), CAST(0x0000A4A6016E4B99 AS DateTime), 0, 0, 0, 0, 1, CAST(0x0000A4A600B90588 AS DateTime), NULL)
INSERT [dbo].[archive_login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (19, 2, CAST(0x0000A4B301294609 AS DateTime), CAST(0x0000A4B301294609 AS DateTime), CAST(0x0000A4B4003214C9 AS DateTime), CAST(0x0000A4B400530A49 AS DateTime), 0, 0, 0, 0, 1, CAST(0x0000A4B30129460E AS DateTime), NULL)
INSERT [dbo].[archive_login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (27, 2, CAST(0x0000A4B400F2AF7E AS DateTime), CAST(0x0000A4B400F2AF7E AS DateTime), CAST(0x0000A4B40187003E AS DateTime), CAST(0x0000A4B5001C73BE AS DateTime), 0, 0, 1, 0, 1, CAST(0x0000A4B400F2AF87 AS DateTime), NULL)
INSERT [dbo].[archive_login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (28, 4, CAST(0x0000A4B400F42A9B AS DateTime), CAST(0x0000A4B400FE7C2A AS DateTime), CAST(0x0000A4B401887B5B AS DateTime), CAST(0x0000A4B5001DEEDB AS DateTime), 2255, -30145, 1, 0, 1, CAST(0x0000A4B400F42A9B AS DateTime), NULL)
INSERT [dbo].[archive_login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (29, 5, CAST(0x0000A4B4009B9FE8 AS DateTime), CAST(0x0000A4B400FE8068 AS DateTime), CAST(0x0000A4B500074F28 AS DateTime), CAST(0x0000A4B5002844A8 AS DateTime), 0, 0, 0, 0, 1, CAST(0x0000A4B400FE8068 AS DateTime), NULL)
INSERT [dbo].[archive_login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (30, 6, CAST(0x0000A4B4009BA7FB AS DateTime), CAST(0x0000A4B400FE887B AS DateTime), CAST(0x0000A4B50007573B AS DateTime), CAST(0x0000A4B500284CBB AS DateTime), 0, 0, 0, 0, 1, CAST(0x0000A4B400FE887B AS DateTime), NULL)
INSERT [dbo].[archive_login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (31, 7, CAST(0x0000A4B400FE8E6C AS DateTime), CAST(0x0000A4B400FE8E6C AS DateTime), CAST(0x0000A4B500075D2C AS DateTime), CAST(0x0000A4B5002852AC AS DateTime), 0, 0, 0, 0, 5, CAST(0x0000A4B400FE8E6C AS DateTime), NULL)
INSERT [dbo].[archive_login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (32, 9, CAST(0x0000A4B400FE9612 AS DateTime), CAST(0x0000A4B400FE9612 AS DateTime), CAST(0x0000A4B5000764D2 AS DateTime), CAST(0x0000A4B500285A52 AS DateTime), 0, 0, 0, 0, 5, CAST(0x0000A4B400FE9612 AS DateTime), NULL)
INSERT [dbo].[archive_login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (33, 10, CAST(0x0000A4B400FE9C4C AS DateTime), CAST(0x0000A4B400FE9C4C AS DateTime), CAST(0x0000A4B500076B0C AS DateTime), CAST(0x0000A4B50028608C AS DateTime), 0, 0, 0, 0, 6, CAST(0x0000A4B400FE9C4C AS DateTime), NULL)
INSERT [dbo].[archive_login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (34, 11, CAST(0x0000A4B400FEA450 AS DateTime), CAST(0x0000A4B400FEA450 AS DateTime), CAST(0x0000A4B500077310 AS DateTime), CAST(0x0000A4B500286890 AS DateTime), 0, 0, 0, 0, 6, CAST(0x0000A4B400FEA450 AS DateTime), NULL)
INSERT [dbo].[archive_login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (35, 12, CAST(0x0000A4B400B54640 AS DateTime), CAST(0x0000A4B400B54640 AS DateTime), CAST(0x0000A4B400B54640 AS DateTime), CAST(0x0000A4B400B54640 AS DateTime), 0, 0, 0, 0, 4, CAST(0x0000A4B400FEA938 AS DateTime), NULL)
INSERT [dbo].[archive_login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (36, 13, CAST(0x0000A4B400B54640 AS DateTime), CAST(0x0000A4B400B54640 AS DateTime), CAST(0x0000A4B400B54640 AS DateTime), CAST(0x0000A4B400B54640 AS DateTime), 0, 0, 0, 0, 4, CAST(0x0000A4B400FEAE36 AS DateTime), NULL)
INSERT [dbo].[archive_login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (37, 14, CAST(0x0000A4B400B54640 AS DateTime), CAST(0x0000A4B400B54640 AS DateTime), CAST(0x0000A4B400B54640 AS DateTime), CAST(0x0000A4B400B54640 AS DateTime), 0, 0, 0, 0, 2, CAST(0x0000A4B400FEB2C2 AS DateTime), NULL)
INSERT [dbo].[archive_login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (38, 15, CAST(0x0000A4B400B54640 AS DateTime), CAST(0x0000A4B400B54640 AS DateTime), CAST(0x0000A4B400B54640 AS DateTime), CAST(0x0000A4B400B54640 AS DateTime), 0, 0, 0, 0, 2, CAST(0x0000A4B400FEB858 AS DateTime), NULL)
INSERT [dbo].[archive_login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (39, 16, CAST(0x0000A4B400B54640 AS DateTime), CAST(0x0000A4B400B54640 AS DateTime), CAST(0x0000A4B400B54640 AS DateTime), CAST(0x0000A4B400B54640 AS DateTime), 0, 0, 0, 0, 3, CAST(0x0000A4B400FEBE27 AS DateTime), NULL)
INSERT [dbo].[archive_login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (40, 17, CAST(0x0000A4B400B54640 AS DateTime), CAST(0x0000A4B400B54640 AS DateTime), CAST(0x0000A4B400B54640 AS DateTime), CAST(0x0000A4B400B54640 AS DateTime), 0, 0, 0, 0, 3, CAST(0x0000A4B400FEC24C AS DateTime), NULL)
SET IDENTITY_INSERT [dbo].[company_setting] ON 

INSERT [dbo].[company_setting] ([id], [name], [timezone], [time_begin], [time_end], [time_overtime], [today_time_begin], [status], [createdate], [timestamp], [sick_permitentry_dispensation]) VALUES (1, N'testing', 7, 11, 9, 2, 6, 1, CAST(0x0000A49E013B2A0B AS DateTime), CAST(0x0000A49E013B2A0B AS DateTime), NULL)
SET IDENTITY_INSERT [dbo].[company_setting] OFF
INSERT [dbo].[device_Logtype] ([id], [log_type]) VALUES (1, N'ERROR')
INSERT [dbo].[device_Logtype] ([id], [log_type]) VALUES (2, N'DEBUG')
SET IDENTITY_INSERT [dbo].[Excuse] ON 

INSERT [dbo].[Excuse] ([id], [from_date], [to_date], [user_id], [mac_id], [excuse_reason], [approved], [type], [entry_date], [created_date]) VALUES (2, CAST(0x0000A4BB00B54640 AS DateTime), CAST(0x0000A4BB00000000 AS DateTime), 2, 1, N'macetbos', 1, 4, CAST(0x0000A4BB009450C0 AS DateTime), CAST(0x0000A4BB00F8745E AS DateTime))
INSERT [dbo].[Excuse] ([id], [from_date], [to_date], [user_id], [mac_id], [excuse_reason], [approved], [type], [entry_date], [created_date]) VALUES (3, CAST(0x0000A4BB009450C0 AS DateTime), CAST(0x0000A4BB009450C0 AS DateTime), 5, 4, N'helootest', 1, 4, CAST(0x0000A4BB0092F130 AS DateTime), CAST(0x0000A4BB0136AFD5 AS DateTime))
INSERT [dbo].[Excuse] ([id], [from_date], [to_date], [user_id], [mac_id], [excuse_reason], [approved], [type], [entry_date], [created_date]) VALUES (20, CAST(0x0000A4BC00000000 AS DateTime), CAST(0x0000A4BF00000000 AS DateTime), 5, 4, N'melayat', 1, 1, CAST(0x0000A4BB00000000 AS DateTime), CAST(0x0000A4BF0105F994 AS DateTime))
INSERT [dbo].[Excuse] ([id], [from_date], [to_date], [user_id], [mac_id], [excuse_reason], [approved], [type], [entry_date], [created_date]) VALUES (21, CAST(0x0000A4BF00000000 AS DateTime), CAST(0x0000A4C400000000 AS DateTime), 5, 4, N'melayat', 1, 1, CAST(0x0000A4BD00000000 AS DateTime), CAST(0x0000A4BF0106AB5C AS DateTime))
SET IDENTITY_INSERT [dbo].[Excuse] OFF
SET IDENTITY_INSERT [dbo].[Excuse_Type] ON 

INSERT [dbo].[Excuse_Type] ([id], [typeName]) VALUES (1, N'Sick')
INSERT [dbo].[Excuse_Type] ([id], [typeName]) VALUES (2, N'Permit')
INSERT [dbo].[Excuse_Type] ([id], [typeName]) VALUES (4, N'Allowed Late')
INSERT [dbo].[Excuse_Type] ([id], [typeName]) VALUES (5, N'Leave')
INSERT [dbo].[Excuse_Type] ([id], [typeName]) VALUES (6, N'Early Leave')
SET IDENTITY_INSERT [dbo].[Excuse_Type] OFF
SET IDENTITY_INSERT [dbo].[groups] ON 

INSERT [dbo].[groups] ([id], [name], [createdate], [timestamp]) VALUES (1, N'yyyyyy', CAST(0x0000A49E013B8A01 AS DateTime), CAST(0x0000A49E013B8A01 AS DateTime))
SET IDENTITY_INSERT [dbo].[groups] OFF
INSERT [dbo].[groups_rights] ([group_id], [right_id], [createdate]) VALUES (1, 1, CAST(0x0000A49E013BB3B2 AS DateTime))
SET IDENTITY_INSERT [dbo].[login] ON 

INSERT [dbo].[login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (64, 2, CAST(0x0000A4BB016A8C80 AS DateTime), CAST(0x0000A4BB016A8C80 AS DateTime), CAST(0x0000A4BC00735B40 AS DateTime), CAST(0x0000A4BC009450C0 AS DateTime), 0, 0, 0, 0, 5, CAST(0x0000A4BB0128EA89 AS DateTime), NULL)
INSERT [dbo].[login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (65, 5, CAST(0x0000A4BB01499700 AS DateTime), CAST(0x0000A4BB0136DC0A AS DateTime), CAST(0x0000A4BC005265C0 AS DateTime), CAST(0x0000A4BC00735B40 AS DateTime), 0, 0, 0, 0, 5, CAST(0x0000A4BB0136DC0B AS DateTime), NULL)
INSERT [dbo].[login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (66, 2, CAST(0x0000A4BC00E3B5B3 AS DateTime), CAST(0x0000A4BC00F20188 AS DateTime), CAST(0x0000A4BC011826C0 AS DateTime), CAST(0x0000A4BD000D79F3 AS DateTime), 3124, -8333, 1, 0, 4, CAST(0x0000A4BC00E3B5C6 AS DateTime), NULL)
INSERT [dbo].[login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (70, 5, CAST(0x0000A4BF00B54640 AS DateTime), CAST(0x0000A4BF00B54640 AS DateTime), CAST(0x0000A4BF00B54640 AS DateTime), CAST(0x0000A4BF00B54640 AS DateTime), 0, 0, 0, 0, 4, CAST(0x0000A4BF0107AF82 AS DateTime), NULL)
INSERT [dbo].[login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (71, 5, CAST(0x0000A4C000B54640 AS DateTime), CAST(0x0000A4C000B54640 AS DateTime), CAST(0x0000A4C000B54640 AS DateTime), CAST(0x0000A4C000B54640 AS DateTime), 0, 0, 0, 0, 4, CAST(0x0000A4BF0107AF83 AS DateTime), NULL)
INSERT [dbo].[login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (72, 5, CAST(0x0000A4C100B54640 AS DateTime), CAST(0x0000A4C100B54640 AS DateTime), CAST(0x0000A4C100B54640 AS DateTime), CAST(0x0000A4C100B54640 AS DateTime), 0, 0, 0, 0, 4, CAST(0x0000A4BF0107AF84 AS DateTime), NULL)
INSERT [dbo].[login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (73, 5, CAST(0x0000A4C200B54640 AS DateTime), CAST(0x0000A4C200B54640 AS DateTime), CAST(0x0000A4C200B54640 AS DateTime), CAST(0x0000A4C200B54640 AS DateTime), 0, 0, 0, 0, 4, CAST(0x0000A4BF0107AF84 AS DateTime), NULL)
INSERT [dbo].[login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (74, 5, CAST(0x0000A4C300B54640 AS DateTime), CAST(0x0000A4C300B54640 AS DateTime), CAST(0x0000A4C300B54640 AS DateTime), CAST(0x0000A4C300B54640 AS DateTime), 0, 0, 0, 0, 4, CAST(0x0000A4BF0107AF85 AS DateTime), NULL)
INSERT [dbo].[login] ([id], [user_id], [first_login], [last_login], [logout_time], [start_overtime], [login_elapse_time], [overtime_elapse_time], [is_late], [is_full], [login_type], [timestamp], [is_overtime]) VALUES (75, 5, CAST(0x0000A4C400B54640 AS DateTime), CAST(0x0000A4C400B54640 AS DateTime), CAST(0x0000A4C400B54640 AS DateTime), CAST(0x0000A4C400B54640 AS DateTime), 0, 0, 0, 0, 4, CAST(0x0000A4BF0107AF86 AS DateTime), NULL)
SET IDENTITY_INSERT [dbo].[login] OFF
INSERT [dbo].[login_history] ([login_id], [mac_id], [login_date], [ip_address], [createdate]) VALUES (65, 11, CAST(0x0000A4BB0136DC0A AS DateTime), N'192.168.0.111', CAST(0x0000A4BB0136DC10 AS DateTime))
INSERT [dbo].[login_history] ([login_id], [mac_id], [login_date], [ip_address], [createdate]) VALUES (66, 3, CAST(0x0000A4BC00E3B5B3 AS DateTime), N'192.168.0.111', CAST(0x0000A4BC00E3B5D4 AS DateTime))
INSERT [dbo].[login_history] ([login_id], [mac_id], [login_date], [ip_address], [createdate]) VALUES (66, 3, CAST(0x0000A4BC00ED023B AS DateTime), N'192.168.0.111', CAST(0x0000A4BC00ED023C AS DateTime))
INSERT [dbo].[login_history] ([login_id], [mac_id], [login_date], [ip_address], [createdate]) VALUES (66, 3, CAST(0x0000A4BC00F10895 AS DateTime), N'192.168.12.12', CAST(0x0000A4BC00F10897 AS DateTime))
INSERT [dbo].[login_history] ([login_id], [mac_id], [login_date], [ip_address], [createdate]) VALUES (66, 3, CAST(0x0000A4BC00F14525 AS DateTime), N'192.168.12.12', CAST(0x0000A4BC00F14525 AS DateTime))
INSERT [dbo].[login_history] ([login_id], [mac_id], [login_date], [ip_address], [createdate]) VALUES (66, 3, CAST(0x0000A4BC00F20188 AS DateTime), N'192.168.12.12', CAST(0x0000A4BC00F20189 AS DateTime))
SET IDENTITY_INSERT [dbo].[login_type] ON 

INSERT [dbo].[login_type] ([id], [login_type]) VALUES (1, N'Normal')
INSERT [dbo].[login_type] ([id], [login_type]) VALUES (2, N'Permit')
INSERT [dbo].[login_type] ([id], [login_type]) VALUES (3, N'Leave')
INSERT [dbo].[login_type] ([id], [login_type]) VALUES (4, N'Sick')
INSERT [dbo].[login_type] ([id], [login_type]) VALUES (5, N'Allowed Late')
INSERT [dbo].[login_type] ([id], [login_type]) VALUES (6, N'Early Leave')
INSERT [dbo].[login_type] ([id], [login_type]) VALUES (8, N'Absent')
SET IDENTITY_INSERT [dbo].[login_type] OFF
INSERT [dbo].[mac] ([id], [mac], [owner], [can_approve], [status]) VALUES (1, N'1234567', N'test', 0, 1)
INSERT [dbo].[mac] ([id], [mac], [owner], [can_approve], [status]) VALUES (2, N'1224566', N'test2', 0, 1)
INSERT [dbo].[mac] ([id], [mac], [owner], [can_approve], [status]) VALUES (3, N'1234444', N'test3', 1, 1)
INSERT [dbo].[mac] ([id], [mac], [owner], [can_approve], [status]) VALUES (4, N'1235555', N'test4', 0, 1)
INSERT [dbo].[mac] ([id], [mac], [owner], [can_approve], [status]) VALUES (5, N'1236666', N'test5', 0, 1)
INSERT [dbo].[mac] ([id], [mac], [owner], [can_approve], [status]) VALUES (6, N'1456777', N'test6', 0, 1)
INSERT [dbo].[mac] ([id], [mac], [owner], [can_approve], [status]) VALUES (7, N'1676777', N'test7', 0, 1)
INSERT [dbo].[mac] ([id], [mac], [owner], [can_approve], [status]) VALUES (8, N'1777777', N'test8', 0, 1)
INSERT [dbo].[mac] ([id], [mac], [owner], [can_approve], [status]) VALUES (9, N'1565677', N'test9', 0, 1)
INSERT [dbo].[mac] ([id], [mac], [owner], [can_approve], [status]) VALUES (10, N'1878787', N'test10', 0, 1)
INSERT [dbo].[mac] ([id], [mac], [owner], [can_approve], [status]) VALUES (11, N'1567888', N'test11', 0, 1)
INSERT [dbo].[mac] ([id], [mac], [owner], [can_approve], [status]) VALUES (12, N'1444888', N'test12', 0, 1)
INSERT [dbo].[mac] ([id], [mac], [owner], [can_approve], [status]) VALUES (13, N'1234488', N'test13', 0, 1)
INSERT [dbo].[mac] ([id], [mac], [owner], [can_approve], [status]) VALUES (14, N'1778222', N'test14', 0, 1)
INSERT [dbo].[mac] ([id], [mac], [owner], [can_approve], [status]) VALUES (15, N'1237777', N'test15', 0, 1)
SET IDENTITY_INSERT [dbo].[rights] ON 

INSERT [dbo].[rights] ([id], [name], [createdate], [timestamp]) VALUES (1, N'oktok', CAST(0x0000A49E013BA1A2 AS DateTime), CAST(0x0000A49E013BA1A2 AS DateTime))
SET IDENTITY_INSERT [dbo].[rights] OFF
SET IDENTITY_INSERT [dbo].[users] ON 

INSERT [dbo].[users] ([id], [company_id], [name], [status], [createddate], [timestamp]) VALUES (2, 1, N'rrtrtrtrt', 1, CAST(0x0000A49E013B4669 AS DateTime), CAST(0x0000A49E013B4669 AS DateTime))
INSERT [dbo].[users] ([id], [company_id], [name], [status], [createddate], [timestamp]) VALUES (3, 1, N'qwqewqe', 1, CAST(0x0000A49F010C5D4A AS DateTime), CAST(0x0000A49F010C5D4A AS DateTime))
INSERT [dbo].[users] ([id], [company_id], [name], [status], [createddate], [timestamp]) VALUES (4, 1, N'head', 1, CAST(0x0000A4A300F6882E AS DateTime), CAST(0x0000A4A300F6882E AS DateTime))
INSERT [dbo].[users] ([id], [company_id], [name], [status], [createddate], [timestamp]) VALUES (5, 1, N'goodtest', 1, CAST(0x0000A4B400DD688D AS DateTime), CAST(0x0000A4B400DD688D AS DateTime))
INSERT [dbo].[users] ([id], [company_id], [name], [status], [createddate], [timestamp]) VALUES (6, 1, N'modaltest', 1, CAST(0x0000A4B400DD7716 AS DateTime), CAST(0x0000A4B400DD7716 AS DateTime))
INSERT [dbo].[users] ([id], [company_id], [name], [status], [createddate], [timestamp]) VALUES (7, 1, N'alright', 1, CAST(0x0000A4B400DD8663 AS DateTime), CAST(0x0000A4B400DD8663 AS DateTime))
INSERT [dbo].[users] ([id], [company_id], [name], [status], [createddate], [timestamp]) VALUES (9, 1, N'walllright', 1, CAST(0x0000A4B400DDD7B3 AS DateTime), CAST(0x0000A4B400DDD7B3 AS DateTime))
INSERT [dbo].[users] ([id], [company_id], [name], [status], [createddate], [timestamp]) VALUES (10, 1, N'woow', 1, CAST(0x0000A4B400E30429 AS DateTime), CAST(0x0000A4B400E30429 AS DateTime))
INSERT [dbo].[users] ([id], [company_id], [name], [status], [createddate], [timestamp]) VALUES (11, 1, N'lol', 1, CAST(0x0000A4B400E3126F AS DateTime), CAST(0x0000A4B400E3126F AS DateTime))
INSERT [dbo].[users] ([id], [company_id], [name], [status], [createddate], [timestamp]) VALUES (12, 1, N'yooo', 1, CAST(0x0000A4B400E31CC6 AS DateTime), CAST(0x0000A4B400E31CC6 AS DateTime))
INSERT [dbo].[users] ([id], [company_id], [name], [status], [createddate], [timestamp]) VALUES (13, 1, N'deeep', 1, CAST(0x0000A4B400E3287F AS DateTime), CAST(0x0000A4B400E3287F AS DateTime))
INSERT [dbo].[users] ([id], [company_id], [name], [status], [createddate], [timestamp]) VALUES (14, 1, N'away', 1, CAST(0x0000A4B400E32F26 AS DateTime), CAST(0x0000A4B400E32F26 AS DateTime))
INSERT [dbo].[users] ([id], [company_id], [name], [status], [createddate], [timestamp]) VALUES (15, 1, N'unstopale', 1, CAST(0x0000A4B400E339F4 AS DateTime), CAST(0x0000A4B400E339F4 AS DateTime))
INSERT [dbo].[users] ([id], [company_id], [name], [status], [createddate], [timestamp]) VALUES (16, 1, N'possible', 1, CAST(0x0000A4B400E3405D AS DateTime), CAST(0x0000A4B400E3405D AS DateTime))
INSERT [dbo].[users] ([id], [company_id], [name], [status], [createddate], [timestamp]) VALUES (17, 1, N'Letgo', 1, CAST(0x0000A4B400E34585 AS DateTime), CAST(0x0000A4B400E34585 AS DateTime))
SET IDENTITY_INSERT [dbo].[users] OFF
INSERT [dbo].[users_groups] ([user_id], [group_id], [status], [createdate]) VALUES (2, 1, 1, CAST(0x0000A49E013BF1D9 AS DateTime))
INSERT [dbo].[users_groups] ([user_id], [group_id], [status], [createdate]) VALUES (3, 1, 1, CAST(0x0000A49F010CC920 AS DateTime))
INSERT [dbo].[users_groups] ([user_id], [group_id], [status], [createdate]) VALUES (4, 1, 1, CAST(0x0000A4A301006D9E AS DateTime))
INSERT [dbo].[users_groups] ([user_id], [group_id], [status], [createdate]) VALUES (5, 1, 1, CAST(0x0000A4B400FD1B86 AS DateTime))
INSERT [dbo].[users_groups] ([user_id], [group_id], [status], [createdate]) VALUES (6, 1, 1, CAST(0x0000A4B400FD21B7 AS DateTime))
INSERT [dbo].[users_groups] ([user_id], [group_id], [status], [createdate]) VALUES (7, 1, 1, CAST(0x0000A4B400FD2789 AS DateTime))
INSERT [dbo].[users_groups] ([user_id], [group_id], [status], [createdate]) VALUES (9, 1, 1, CAST(0x0000A4B400FD2C06 AS DateTime))
INSERT [dbo].[users_groups] ([user_id], [group_id], [status], [createdate]) VALUES (10, 1, 1, CAST(0x0000A4B400FD39EB AS DateTime))
INSERT [dbo].[users_groups] ([user_id], [group_id], [status], [createdate]) VALUES (11, 1, 1, CAST(0x0000A4B400FD3EB7 AS DateTime))
INSERT [dbo].[users_groups] ([user_id], [group_id], [status], [createdate]) VALUES (12, 1, 1, CAST(0x0000A4B400FD42CF AS DateTime))
INSERT [dbo].[users_groups] ([user_id], [group_id], [status], [createdate]) VALUES (13, 1, 1, CAST(0x0000A4B400FD4E66 AS DateTime))
INSERT [dbo].[users_groups] ([user_id], [group_id], [status], [createdate]) VALUES (14, 1, 1, CAST(0x0000A4B400FD5385 AS DateTime))
INSERT [dbo].[users_groups] ([user_id], [group_id], [status], [createdate]) VALUES (15, 1, 1, CAST(0x0000A4B400FD57A0 AS DateTime))
INSERT [dbo].[users_groups] ([user_id], [group_id], [status], [createdate]) VALUES (16, 1, 1, CAST(0x0000A4B400FD60DB AS DateTime))
INSERT [dbo].[users_groups] ([user_id], [group_id], [status], [createdate]) VALUES (17, 1, 1, CAST(0x0000A4B400FD6A6A AS DateTime))
SET IDENTITY_INSERT [dbo].[users_macs] ON 

INSERT [dbo].[users_macs] ([id], [user_id], [name], [mac], [status], [createdate], [timestamp]) VALUES (3, 2, N'rorororo', N'1234567', 1, CAST(0x0000A49E013B5169 AS DateTime), CAST(0x0000A49E013B5169 AS DateTime))
INSERT [dbo].[users_macs] ([id], [user_id], [name], [mac], [status], [createdate], [timestamp]) VALUES (5, 3, N'qweqe', N'1224566', 1, CAST(0x0000A49F010C9620 AS DateTime), CAST(0x0000A49F010C9620 AS DateTime))
INSERT [dbo].[users_macs] ([id], [user_id], [name], [mac], [status], [createdate], [timestamp]) VALUES (6, 4, N'head', N'1234444', 1, CAST(0x0000A4A301005D1E AS DateTime), CAST(0x0000A4A301005D1E AS DateTime))
INSERT [dbo].[users_macs] ([id], [user_id], [name], [mac], [status], [createdate], [timestamp]) VALUES (11, 5, N'goodtest', N'1235555', 1, CAST(0x0000A4B400E0AD63 AS DateTime), CAST(0x0000A4B400E0AD63 AS DateTime))
INSERT [dbo].[users_macs] ([id], [user_id], [name], [mac], [status], [createdate], [timestamp]) VALUES (12, 6, N'test', N'1236666', 1, CAST(0x0000A4B400E0D99F AS DateTime), CAST(0x0000A4B400E0D99F AS DateTime))
INSERT [dbo].[users_macs] ([id], [user_id], [name], [mac], [status], [createdate], [timestamp]) VALUES (13, 7, N'test', N'1456777', 1, CAST(0x0000A4B400E0FEEF AS DateTime), CAST(0x0000A4B400E0FEEF AS DateTime))
INSERT [dbo].[users_macs] ([id], [user_id], [name], [mac], [status], [createdate], [timestamp]) VALUES (14, 9, N'test', N'1676777', 1, CAST(0x0000A4B400E1215F AS DateTime), CAST(0x0000A4B400E1215F AS DateTime))
INSERT [dbo].[users_macs] ([id], [user_id], [name], [mac], [status], [createdate], [timestamp]) VALUES (15, 10, N'test', N'1777777', 1, CAST(0x0000A4B400E4A8AF AS DateTime), CAST(0x0000A4B400E4A8AF AS DateTime))
INSERT [dbo].[users_macs] ([id], [user_id], [name], [mac], [status], [createdate], [timestamp]) VALUES (16, 11, N'My Device', N'1565677', 1, CAST(0x0000A4B400E4C011 AS DateTime), CAST(0x0000A4B400E4C011 AS DateTime))
INSERT [dbo].[users_macs] ([id], [user_id], [name], [mac], [status], [createdate], [timestamp]) VALUES (17, 12, N'My Device', N'1878787', 1, CAST(0x0000A4B400E4E5AD AS DateTime), CAST(0x0000A4B400E4E5AD AS DateTime))
INSERT [dbo].[users_macs] ([id], [user_id], [name], [mac], [status], [createdate], [timestamp]) VALUES (18, 13, N'My Device', N'1567888', 1, CAST(0x0000A4B400E4FE6A AS DateTime), CAST(0x0000A4B400E4FE6A AS DateTime))
INSERT [dbo].[users_macs] ([id], [user_id], [name], [mac], [status], [createdate], [timestamp]) VALUES (21, 14, N'My Device', N'1444888', 1, CAST(0x0000A4B400E5295B AS DateTime), CAST(0x0000A4B400E5295B AS DateTime))
INSERT [dbo].[users_macs] ([id], [user_id], [name], [mac], [status], [createdate], [timestamp]) VALUES (22, 15, N'My Device', N'1234488', 1, CAST(0x0000A4B400E58232 AS DateTime), CAST(0x0000A4B400E58232 AS DateTime))
INSERT [dbo].[users_macs] ([id], [user_id], [name], [mac], [status], [createdate], [timestamp]) VALUES (23, 16, N'My Device', N'1778222', 1, CAST(0x0000A4B400E5994D AS DateTime), CAST(0x0000A4B400E5994D AS DateTime))
INSERT [dbo].[users_macs] ([id], [user_id], [name], [mac], [status], [createdate], [timestamp]) VALUES (24, 17, N'My Device', N'1237777', 1, CAST(0x0000A4B400E5B0CA AS DateTime), CAST(0x0000A4B400E5B0CA AS DateTime))
SET IDENTITY_INSERT [dbo].[users_macs] OFF
SET ANSI_PADDING ON

GO
/****** Object:  Index [UQ__mac__DF5071E6FAF51893]    Script Date: 6/26/2015 5:42:35 PM ******/
ALTER TABLE [dbo].[mac] ADD  CONSTRAINT [UQ__mac__DF5071E6FAF51893] UNIQUE NONCLUSTERED 
(
	[mac] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[company_setting] ADD  CONSTRAINT [DF_company_setting_status]  DEFAULT ((0)) FOR [status]
GO
ALTER TABLE [dbo].[company_setting] ADD  CONSTRAINT [DF_company_setting_createdate]  DEFAULT (getdate()) FOR [createdate]
GO
ALTER TABLE [dbo].[company_setting] ADD  CONSTRAINT [DF_company_setting_timestamp]  DEFAULT (getdate()) FOR [timestamp]
GO
ALTER TABLE [dbo].[Excuse] ADD  CONSTRAINT [DF_Excuse_created_date]  DEFAULT (getdate()) FOR [created_date]
GO
ALTER TABLE [dbo].[groups] ADD  CONSTRAINT [DF_groups_createdate]  DEFAULT (getdate()) FOR [createdate]
GO
ALTER TABLE [dbo].[groups] ADD  CONSTRAINT [DF_groups_timestamp]  DEFAULT (getdate()) FOR [timestamp]
GO
ALTER TABLE [dbo].[groups_rights] ADD  CONSTRAINT [DF_groups_rights_createdate]  DEFAULT (getdate()) FOR [createdate]
GO
ALTER TABLE [dbo].[login] ADD  CONSTRAINT [DF_login_login_elapse_time]  DEFAULT ((0)) FOR [login_elapse_time]
GO
ALTER TABLE [dbo].[login] ADD  CONSTRAINT [DF_login_count_login_time]  DEFAULT ((0)) FOR [overtime_elapse_time]
GO
ALTER TABLE [dbo].[login] ADD  CONSTRAINT [DF_login_is_full]  DEFAULT ((0)) FOR [is_full]
GO
ALTER TABLE [dbo].[login] ADD  CONSTRAINT [DF_login_status]  DEFAULT ((0)) FOR [login_type]
GO
ALTER TABLE [dbo].[login] ADD  CONSTRAINT [DF_login_timestamp]  DEFAULT (getdate()) FOR [timestamp]
GO
ALTER TABLE [dbo].[login_history] ADD  CONSTRAINT [DF_login_history_timestamp]  DEFAULT (getdate()) FOR [createdate]
GO
ALTER TABLE [dbo].[login_monthly] ADD  CONSTRAINT [DF_archive_monthly_createdate]  DEFAULT (getdate()) FOR [createdate]
GO
ALTER TABLE [dbo].[mac] ADD  CONSTRAINT [DF_mac_can_approve]  DEFAULT ((0)) FOR [can_approve]
GO
ALTER TABLE [dbo].[rights] ADD  CONSTRAINT [DF_rights_createdate]  DEFAULT (getdate()) FOR [createdate]
GO
ALTER TABLE [dbo].[rights] ADD  CONSTRAINT [DF_rights_timestamp]  DEFAULT (getdate()) FOR [timestamp]
GO
ALTER TABLE [dbo].[users] ADD  CONSTRAINT [DF_users_createddate]  DEFAULT (getdate()) FOR [createddate]
GO
ALTER TABLE [dbo].[users] ADD  CONSTRAINT [DF_users_timestamp]  DEFAULT (getdate()) FOR [timestamp]
GO
ALTER TABLE [dbo].[users_groups] ADD  CONSTRAINT [DF_users_groups_status]  DEFAULT ((0)) FOR [status]
GO
ALTER TABLE [dbo].[users_groups] ADD  CONSTRAINT [DF_users_groups_createdate]  DEFAULT (getdate()) FOR [createdate]
GO
ALTER TABLE [dbo].[users_macs] ADD  CONSTRAINT [DF_users_macs_name]  DEFAULT ('My Device') FOR [name]
GO
ALTER TABLE [dbo].[users_macs] ADD  CONSTRAINT [DF_users_macs_status]  DEFAULT ((1)) FOR [status]
GO
ALTER TABLE [dbo].[users_macs] ADD  CONSTRAINT [DF_users_macs_createdate]  DEFAULT (getdate()) FOR [createdate]
GO
ALTER TABLE [dbo].[users_macs] ADD  CONSTRAINT [DF_users_macs_timestamp]  DEFAULT (getdate()) FOR [timestamp]
GO
ALTER TABLE [dbo].[archive_login]  WITH NOCHECK ADD  CONSTRAINT [FK_archive_login_users] FOREIGN KEY([user_id])
REFERENCES [dbo].[users] ([id])
GO
ALTER TABLE [dbo].[archive_login] CHECK CONSTRAINT [FK_archive_login_users]
GO
ALTER TABLE [dbo].[archive_login_history]  WITH CHECK ADD  CONSTRAINT [FK_archive_login_history_archive_login] FOREIGN KEY([login_id])
REFERENCES [dbo].[archive_login] ([id])
GO
ALTER TABLE [dbo].[archive_login_history] CHECK CONSTRAINT [FK_archive_login_history_archive_login]
GO
ALTER TABLE [dbo].[archive_login_history]  WITH CHECK ADD  CONSTRAINT [FK_archive_login_history_users_macs] FOREIGN KEY([mac_id])
REFERENCES [dbo].[users_macs] ([id])
GO
ALTER TABLE [dbo].[archive_login_history] CHECK CONSTRAINT [FK_archive_login_history_users_macs]
GO
ALTER TABLE [dbo].[device_Log]  WITH NOCHECK ADD  CONSTRAINT [FK_device_Log_device_Logtype] FOREIGN KEY([type])
REFERENCES [dbo].[device_Logtype] ([id])
GO
ALTER TABLE [dbo].[device_Log] CHECK CONSTRAINT [FK_device_Log_device_Logtype]
GO
ALTER TABLE [dbo].[device_Log]  WITH NOCHECK ADD  CONSTRAINT [FK_device_Log_users_macs] FOREIGN KEY([mac_id])
REFERENCES [dbo].[users_macs] ([id])
GO
ALTER TABLE [dbo].[device_Log] CHECK CONSTRAINT [FK_device_Log_users_macs]
GO
ALTER TABLE [dbo].[Excuse]  WITH NOCHECK ADD  CONSTRAINT [FK_Excuse_Excuse_Type] FOREIGN KEY([type])
REFERENCES [dbo].[Excuse_Type] ([id])
GO
ALTER TABLE [dbo].[Excuse] CHECK CONSTRAINT [FK_Excuse_Excuse_Type]
GO
ALTER TABLE [dbo].[Excuse]  WITH NOCHECK ADD  CONSTRAINT [FK_Excuse_mac] FOREIGN KEY([mac_id])
REFERENCES [dbo].[mac] ([id])
GO
ALTER TABLE [dbo].[Excuse] CHECK CONSTRAINT [FK_Excuse_mac]
GO
ALTER TABLE [dbo].[Excuse]  WITH NOCHECK ADD  CONSTRAINT [FK_Excuse_users] FOREIGN KEY([user_id])
REFERENCES [dbo].[users] ([id])
GO
ALTER TABLE [dbo].[Excuse] CHECK CONSTRAINT [FK_Excuse_users]
GO
ALTER TABLE [dbo].[groups_rights]  WITH CHECK ADD  CONSTRAINT [FK_groups_rights_groups] FOREIGN KEY([group_id])
REFERENCES [dbo].[groups] ([id])
GO
ALTER TABLE [dbo].[groups_rights] CHECK CONSTRAINT [FK_groups_rights_groups]
GO
ALTER TABLE [dbo].[groups_rights]  WITH CHECK ADD  CONSTRAINT [FK_groups_rights_rights] FOREIGN KEY([right_id])
REFERENCES [dbo].[rights] ([id])
GO
ALTER TABLE [dbo].[groups_rights] CHECK CONSTRAINT [FK_groups_rights_rights]
GO
ALTER TABLE [dbo].[login]  WITH CHECK ADD  CONSTRAINT [FK_login_login_type] FOREIGN KEY([login_type])
REFERENCES [dbo].[login_type] ([id])
GO
ALTER TABLE [dbo].[login] CHECK CONSTRAINT [FK_login_login_type]
GO
ALTER TABLE [dbo].[login]  WITH CHECK ADD  CONSTRAINT [FK_login_users] FOREIGN KEY([user_id])
REFERENCES [dbo].[users] ([id])
GO
ALTER TABLE [dbo].[login] CHECK CONSTRAINT [FK_login_users]
GO
ALTER TABLE [dbo].[login_history]  WITH CHECK ADD  CONSTRAINT [FK_login_history_login] FOREIGN KEY([login_id])
REFERENCES [dbo].[login] ([id])
GO
ALTER TABLE [dbo].[login_history] CHECK CONSTRAINT [FK_login_history_login]
GO
ALTER TABLE [dbo].[login_history]  WITH CHECK ADD  CONSTRAINT [FK_login_history_users_macs] FOREIGN KEY([mac_id])
REFERENCES [dbo].[users_macs] ([id])
GO
ALTER TABLE [dbo].[login_history] CHECK CONSTRAINT [FK_login_history_users_macs]
GO
ALTER TABLE [dbo].[login_monthly]  WITH NOCHECK ADD  CONSTRAINT [FK_archive_monthly_users] FOREIGN KEY([user_id])
REFERENCES [dbo].[users] ([id])
GO
ALTER TABLE [dbo].[login_monthly] CHECK CONSTRAINT [FK_archive_monthly_users]
GO
ALTER TABLE [dbo].[loginhistory]  WITH CHECK ADD  CONSTRAINT [FK_loginhistory_users_macs] FOREIGN KEY([mac_id])
REFERENCES [dbo].[users_macs] ([id])
GO
ALTER TABLE [dbo].[loginhistory] CHECK CONSTRAINT [FK_loginhistory_users_macs]
GO
ALTER TABLE [dbo].[users]  WITH CHECK ADD  CONSTRAINT [FK_users_company_setting] FOREIGN KEY([company_id])
REFERENCES [dbo].[company_setting] ([id])
GO
ALTER TABLE [dbo].[users] CHECK CONSTRAINT [FK_users_company_setting]
GO
ALTER TABLE [dbo].[users_groups]  WITH CHECK ADD  CONSTRAINT [FK_users_groups_groups] FOREIGN KEY([group_id])
REFERENCES [dbo].[groups] ([id])
GO
ALTER TABLE [dbo].[users_groups] CHECK CONSTRAINT [FK_users_groups_groups]
GO
ALTER TABLE [dbo].[users_groups]  WITH CHECK ADD  CONSTRAINT [FK_users_groups_users] FOREIGN KEY([user_id])
REFERENCES [dbo].[users] ([id])
GO
ALTER TABLE [dbo].[users_groups] CHECK CONSTRAINT [FK_users_groups_users]
GO
ALTER TABLE [dbo].[users_macs]  WITH CHECK ADD  CONSTRAINT [FK_users_macs_mac] FOREIGN KEY([mac])
REFERENCES [dbo].[mac] ([mac])
GO
ALTER TABLE [dbo].[users_macs] CHECK CONSTRAINT [FK_users_macs_mac]
GO
ALTER TABLE [dbo].[users_macs]  WITH CHECK ADD  CONSTRAINT [FK_users_macs_users] FOREIGN KEY([user_id])
REFERENCES [dbo].[users] ([id])
GO
ALTER TABLE [dbo].[users_macs] CHECK CONSTRAINT [FK_users_macs_users]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Company Identifier' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'company_setting', @level2type=N'COLUMN',@level2name=N'id'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Company Name' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'company_setting', @level2type=N'COLUMN',@level2name=N'name'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Timezone used by Company' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'company_setting', @level2type=N'COLUMN',@level2name=N'timezone'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Begin of day (in Hour)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'company_setting', @level2type=N'COLUMN',@level2name=N'time_begin'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'End of Day (total hours after Begin of Day)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'company_setting', @level2type=N'COLUMN',@level2name=N'time_end'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Minimum time before counted as Overtime of Day (in Hours)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'company_setting', @level2type=N'COLUMN',@level2name=N'time_overtime'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Time as Today start (in Hour)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'company_setting', @level2type=N'COLUMN',@level2name=N'today_time_begin'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Enable/Disable Company Status' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'company_setting', @level2type=N'COLUMN',@level2name=N'status'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Date/Time Company registered' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'company_setting', @level2type=N'COLUMN',@level2name=N'createdate'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Last update date/time' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'company_setting', @level2type=N'COLUMN',@level2name=N'timestamp'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'device mac _id' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'device_Log', @level2type=N'COLUMN',@level2name=N'mac_id'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'log date' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'device_Log', @level2type=N'COLUMN',@level2name=N'logdate'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'log type' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'device_Log', @level2type=N'COLUMN',@level2name=N'type'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'main error message' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'device_Log', @level2type=N'COLUMN',@level2name=N'message'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'log stack trace' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'device_Log', @level2type=N'COLUMN',@level2name=N'stacktrace'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'sever time on input' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'device_Log', @level2type=N'COLUMN',@level2name=N'timestamp'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'identification number' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Excuse', @level2type=N'COLUMN',@level2name=N'id'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'excuse start date' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Excuse', @level2type=N'COLUMN',@level2name=N'from_date'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'excuse end date' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Excuse', @level2type=N'COLUMN',@level2name=N'to_date'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'user who request excuse' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Excuse', @level2type=N'COLUMN',@level2name=N'user_id'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'user''s device mac id' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Excuse', @level2type=N'COLUMN',@level2name=N'mac_id'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'excuse reason' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Excuse', @level2type=N'COLUMN',@level2name=N'excuse_reason'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'excuse approved or not ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Excuse', @level2type=N'COLUMN',@level2name=N'approved'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'approval type 1: SPV 2:HRD 3:HRD_override 4: unapproved' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Excuse', @level2type=N'COLUMN',@level2name=N'type'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Excuse entry date GTM+7' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Excuse', @level2type=N'COLUMN',@level2name=N'entry_date'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'excuse entry date by db date' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Excuse', @level2type=N'COLUMN',@level2name=N'created_date'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Excuse Table' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Excuse'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Date/Time Group registered' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'groups', @level2type=N'COLUMN',@level2name=N'createdate'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Last update date/time' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'groups', @level2type=N'COLUMN',@level2name=N'timestamp'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Group Identifier (FK of [groups])' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'groups_rights', @level2type=N'COLUMN',@level2name=N'group_id'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Right Identifier (FK of [rights])' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'groups_rights', @level2type=N'COLUMN',@level2name=N'right_id'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Date/Time Groups-Rights registered' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'groups_rights', @level2type=N'COLUMN',@level2name=N'createdate'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'User Identifier (FK of [users])' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'login', @level2type=N'COLUMN',@level2name=N'user_id'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Date/Time of First time login' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'login', @level2type=N'COLUMN',@level2name=N'first_login'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Date/Time of subsequence login' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'login', @level2type=N'COLUMN',@level2name=N'last_login'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Date/Time of official logout time' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'login', @level2type=N'COLUMN',@level2name=N'logout_time'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Date/Time of Overtime' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'login', @level2type=N'COLUMN',@level2name=N'start_overtime'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Elapse for Login' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'login', @level2type=N'COLUMN',@level2name=N'login_elapse_time'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Elapse for Overtime' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'login', @level2type=N'COLUMN',@level2name=N'overtime_elapse_time'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Flag for Late/Not Late' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'login', @level2type=N'COLUMN',@level2name=N'is_late'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Flag for User logout at/after [logout_time]' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'login', @level2type=N'COLUMN',@level2name=N'is_full'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'0: job generated entry, no Login/Logout occured
1: Login occured
2: Considered as excuse ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'login', @level2type=N'COLUMN',@level2name=N'login_type'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Last update date/time' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'login', @level2type=N'COLUMN',@level2name=N'timestamp'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'MAC Identifier (FK to [users_macs])' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'login_history', @level2type=N'COLUMN',@level2name=N'mac_id'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Date/Time of login' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'login_history', @level2type=N'COLUMN',@level2name=N'login_date'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'IP Address from which login occured' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'login_history', @level2type=N'COLUMN',@level2name=N'ip_address'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Login History create time' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'login_history', @level2type=N'COLUMN',@level2name=N'createdate'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Right Identifier' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'rights', @level2type=N'COLUMN',@level2name=N'id'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Right name' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'rights', @level2type=N'COLUMN',@level2name=N'name'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Date/Time Right registered' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'rights', @level2type=N'COLUMN',@level2name=N'createdate'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Last update date/time' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'rights', @level2type=N'COLUMN',@level2name=N'timestamp'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'User Identifier' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'users', @level2type=N'COLUMN',@level2name=N'id'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Company Identifier (FK of [company_setting])' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'users', @level2type=N'COLUMN',@level2name=N'company_id'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'User name' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'users', @level2type=N'COLUMN',@level2name=N'name'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Enable/Disable User Status' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'users', @level2type=N'COLUMN',@level2name=N'status'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Date/Time User registered' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'users', @level2type=N'COLUMN',@level2name=N'createddate'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Last update date/time' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'users', @level2type=N'COLUMN',@level2name=N'timestamp'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'User Identifer (FK of [users])' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'users_groups', @level2type=N'COLUMN',@level2name=N'user_id'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Group Identifer (FK of [groups])' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'users_groups', @level2type=N'COLUMN',@level2name=N'group_id'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Enable/Disable Users in Groups Status' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'users_groups', @level2type=N'COLUMN',@level2name=N'status'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Date/Time Users-Groups registered' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'users_groups', @level2type=N'COLUMN',@level2name=N'createdate'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'MAC Identifier' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'users_macs', @level2type=N'COLUMN',@level2name=N'id'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'User Identifier (FK of [users])' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'users_macs', @level2type=N'COLUMN',@level2name=N'user_id'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Device name which the MAC address belong to' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'users_macs', @level2type=N'COLUMN',@level2name=N'name'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'MAC Address' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'users_macs', @level2type=N'COLUMN',@level2name=N'mac'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Enable/Disable MAC address' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'users_macs', @level2type=N'COLUMN',@level2name=N'status'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Date/Time MAC registered' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'users_macs', @level2type=N'COLUMN',@level2name=N'createdate'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Last update date/time' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'users_macs', @level2type=N'COLUMN',@level2name=N'timestamp'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "um"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 135
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "u"
            Begin Extent = 
               Top = 6
               Left = 246
               Bottom = 135
               Right = 416
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "m"
            Begin Extent = 
               Top = 6
               Left = 454
               Bottom = 135
               Right = 624
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ug"
            Begin Extent = 
               Top = 6
               Left = 662
               Bottom = 135
               Right = 832
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "cs"
            Begin Extent = 
               Top = 138
               Left = 38
               Bottom = 267
               Right = 286
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'UserCompanyByMAC'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'UserCompanyByMAC'
GO
USE [master]
GO
ALTER DATABASE [TKPAbsen] SET  READ_WRITE 
GO
