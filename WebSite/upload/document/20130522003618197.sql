USE [document]
GO
/****** Object:  Role [System.Activities.DurableInstancing.InstanceStoreObservers]    Script Date: 05/13/2013 09:42:20 ******/
CREATE ROLE [System.Activities.DurableInstancing.InstanceStoreObservers] AUTHORIZATION [dbo]
GO
/****** Object:  Role [System.Activities.DurableInstancing.InstanceStoreUsers]    Script Date: 05/13/2013 09:42:20 ******/
CREATE ROLE [System.Activities.DurableInstancing.InstanceStoreUsers] AUTHORIZATION [dbo]
GO
/****** Object:  Role [System.Activities.DurableInstancing.WorkflowActivationUsers]    Script Date: 05/13/2013 09:42:20 ******/
CREATE ROLE [System.Activities.DurableInstancing.WorkflowActivationUsers] AUTHORIZATION [dbo]
GO
/****** Object:  Schema [System.Activities.DurableInstancing]    Script Date: 05/13/2013 09:42:14 ******/
CREATE SCHEMA [System.Activities.DurableInstancing] AUTHORIZATION [dbo]
GO
/****** Object:  UserDefinedFunction [System.Activities.DurableInstancing].[GetExpirationTime]    Script Date: 05/13/2013 09:42:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [System.Activities.DurableInstancing].[GetExpirationTime] (@offsetInMilliseconds bigint)
returns datetime
as
begin

	if (@offsetInMilliseconds is null)
	begin
		return null
	end

	declare @hourInMillisecond bigint
	declare @offsetInHours bigint
	declare @remainingOffsetInMilliseconds bigint
	declare @expirationTimer datetime

	set @hourInMillisecond = 60*60*1000
	set @offsetInHours = @offsetInMilliseconds / @hourInMillisecond
	set @remainingOffsetInMilliseconds = @offsetInMilliseconds % @hourInMillisecond

	set @expirationTimer = getutcdate()
	set @expirationTimer = dateadd (hour, @offsetInHours, @expirationTimer)
	set @expirationTimer = dateadd (millisecond,@remainingOffsetInMilliseconds, @expirationTimer)

	return @expirationTimer

end
GO
/****** Object:  StoredProcedure [dbo].[PRO_DELETE_DB]    Script Date: 05/13/2013 09:42:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
------------------------------
CREATE  PROC [dbo].[PRO_DELETE_DB]
	@TABLE_NAME VARCHAR(50),	--表名
	@FIELD_WHERE VARCHAR(200),	--条件
	@NUM INT OUTPUT
	AS
	SET NOCOUNT ON
	BEGIN
		BEGIN TRANSACTION
		DECLARE @DEL_STATEMENT VARCHAR(250)	--执行字符串
		SET @DEL_STATEMENT = 'DELETE '+@TABLE_NAME+' '+ @FIELD_WHERE
		EXEC (@DEL_STATEMENT)
			IF(@@ERROR = 0)
				BEGIN
					SET @NUM = 1
					COMMIT TRANSACTION
				END
			ELSE
				BEGIN
					SET @NUM = 0
					ROLLBACK TRANSACTION
				END	
	END
GO
/****** Object:  StoredProcedure [dbo].[PRO_UPDATE_DB]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
------------------------------------------------
CREATE      PROC [dbo].[PRO_UPDATE_DB]
	@TABLE_NAME VARCHAR(50),	--表名
	@FIELD_NAME VARCHAR(1000),	--表中字段名
	@FIELD_VALUE VARCHAR(1500),	--对应字段的值
	@FIELD_WHERE VARCHAR(200),	--条件
	@NUM INT OUTPUT
	AS
	SET NOCOUNT ON
	BEGIN
		BEGIN TRANSACTION
		DECLARE @UPDATE_STATEMENT VARCHAR(2500)	--执行字符串
		DECLARE @FN_CURRENT_INDEX INT	--字段名称字符串截取的起始坐标
		DECLARE @FN_NEXT_INDEX INT	--字段名称字符串截取的结束坐标
		DECLARE @FV_CURRENT_INDEX INT	--字段值字符串截取的起始坐标
		DECLARE @FV_NEXT_INDEX INT	--字段值字符串截取的结束坐标
		SET @UPDATE_STATEMENT='UPDATE '+@TABLE_NAME+' SET '	--给执行字符串赋值
		SET @FN_CURRENT_INDEX= 1	--给FN当前坐标赋值
		SET @FV_CURRENT_INDEX= 1	--给FV当前坐标赋值
		IF(@FIELD_WHERE IS NULL OR @FIELD_WHERE = '')
			SET @FIELD_WHERE =' WHERE 1=1'
		ELSE
			SET @FIELD_WHERE =' WHERE 1=1 AND '+@FIELD_WHERE
		WHILE(@FN_CURRENT_INDEX <= LEN(@FIELD_NAME) AND @FV_CURRENT_INDEX <= LEN(@FIELD_VALUE)+1)
			BEGIN
				--获取FN截取字符串的结束坐标
				SET @FN_NEXT_INDEX=CHARINDEX('&',@FIELD_NAME,@FN_CURRENT_INDEX)
					IF (@FN_NEXT_INDEX = 0 OR @FN_NEXT_INDEX IS NULL)
						SET @FN_NEXT_INDEX = LEN(@FIELD_NAME)+1
				--获取FV截取字符串的结束坐标
				SET @FV_NEXT_INDEX=CHARINDEX('&',@FIELD_VALUE,@FV_CURRENT_INDEX)
					IF (@FV_NEXT_INDEX =0 OR @FV_NEXT_INDEX IS NULL)
						SET @FV_NEXT_INDEX = LEN(@FIELD_VALUE)+1
				IF(SUBSTRING(@FIELD_NAME,@FN_CURRENT_INDEX,@FN_NEXT_INDEX) IS NULL OR SUBSTRING(@FIELD_NAME,@FN_CURRENT_INDEX,@FN_NEXT_INDEX)='')
					BEGIN
						SET @NUM = 0
						ROLLBACK TRANSACTION
					END
				SET @UPDATE_STATEMENT = @UPDATE_STATEMENT+SUBSTRING(@FIELD_NAME,@FN_CURRENT_INDEX,@FN_NEXT_INDEX-@FN_CURRENT_INDEX)
				IF(@FV_NEXT_INDEX = LEN(@FIELD_VALUE)+1)
					begin
					IF(SUBSTRING(@FIELD_VALUE,@FV_CURRENT_INDEX,@FV_NEXT_INDEX-@FV_CURRENT_INDEX) IS NULL OR SUBSTRING(@FIELD_VALUE,@FV_CURRENT_INDEX,@FV_NEXT_INDEX-@FV_CURRENT_INDEX) ='')
						SET @UPDATE_STATEMENT = @UPDATE_STATEMENT +'= NULL'
					ELSE
						SET @UPDATE_STATEMENT = @UPDATE_STATEMENT +'= '+ SUBSTRING(@FIELD_VALUE,@FV_CURRENT_INDEX,@FV_NEXT_INDEX-@FV_CURRENT_INDEX)
					end
				ELSE
					begin
					IF(SUBSTRING(@FIELD_VALUE,@FV_CURRENT_INDEX,@FV_NEXT_INDEX-@FV_CURRENT_INDEX) IS NULL OR SUBSTRING(@FIELD_VALUE,@FV_CURRENT_INDEX,@FV_NEXT_INDEX-@FV_CURRENT_INDEX) ='')
						SET @UPDATE_STATEMENT = @UPDATE_STATEMENT +'= NULL ,'
					ELSE
						SET @UPDATE_STATEMENT = @UPDATE_STATEMENT +'= '+ SUBSTRING(@FIELD_VALUE,@FV_CURRENT_INDEX,@FV_NEXT_INDEX-@FV_CURRENT_INDEX)+','
					end
				--重新给当前ID赋值
				SET @FN_CURRENT_INDEX = @FN_NEXT_INDEX+1
				SET @FV_CURRENT_INDEX = @FV_NEXT_INDEX+1
			END
		SET @UPDATE_STATEMENT = @UPDATE_STATEMENT+@FIELD_WHERE
		EXEC(@UPDATE_STATEMENT)
		IF(@@ERROR = 0)
			BEGIN 
				SET @NUM = 1
				COMMIT TRANSACTION
			END
		ELSE
			BEGIN
				SET @NUM = 0
				ROLLBACK TRANSACTION
			END

	end
GO
/****** Object:  Table [dbo].[SystemInfo]    Script Date: 05/13/2013 09:42:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SystemInfo](
	[id] [tinyint] NOT NULL,
	[name] [varchar](50) NULL,
	[value] [varchar](max) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [System.Activities.DurableInstancing].[SqlWorkflowInstanceStoreVersionTable]    Script Date: 05/13/2013 09:42:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [System.Activities.DurableInstancing].[SqlWorkflowInstanceStoreVersionTable](
	[Major] [bigint] NULL,
	[Minor] [bigint] NULL,
	[Build] [bigint] NULL,
	[Revision] [bigint] NULL,
	[LastUpdated] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[Split]    Script Date: 05/13/2013 09:42:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Split]
(
@SplitString varchar(8000),-- nvarchar(4000)
@Separator varchar(2) 
)
RETURNS @SplitStringsTable TABLE
(
[id] int identity(1,1),
[value] varchar(8000)-- nvarchar(4000)
)
AS
BEGIN
    DECLARE @CurrentIndex int;
    DECLARE @NextIndex int;
    DECLARE @ReturnText varchar(8000);-- nvarchar(4000)
    SELECT @CurrentIndex=1;
    WHILE(@CurrentIndex<=len(@SplitString))
    BEGIN
        SELECT @NextIndex=charindex(@Separator,@SplitString,@CurrentIndex);
        IF(@NextIndex=0 OR @NextIndex IS NULL)
            SELECT @NextIndex=len(@SplitString)+1;
       
        SELECT @ReturnText=substring(@SplitString,@CurrentIndex,@NextIndex-@CurrentIndex);

        INSERT INTO @SplitStringsTable([value])
        VALUES(@ReturnText);
       
        SELECT @CurrentIndex=@NextIndex+1;
    END
    RETURN;
END
GO
/****** Object:  Table [System.Activities.DurableInstancing].[ServiceDeploymentsTable]    Script Date: 05/13/2013 09:42:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [System.Activities.DurableInstancing].[ServiceDeploymentsTable](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ServiceDeploymentHash] [uniqueidentifier] NOT NULL,
	[SiteName] [nvarchar](max) NOT NULL,
	[RelativeServicePath] [nvarchar](max) NOT NULL,
	[RelativeApplicationPath] [nvarchar](max) NOT NULL,
	[ServiceName] [nvarchar](max) NOT NULL,
	[ServiceNamespace] [nvarchar](max) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [System.Activities.DurableInstancing].[InstancePromotedPropertiesTable]    Script Date: 05/13/2013 09:42:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [System.Activities.DurableInstancing].[InstancePromotedPropertiesTable](
	[SurrogateInstanceId] [bigint] NOT NULL,
	[PromotionName] [nvarchar](400) NOT NULL,
	[Value1] [sql_variant] NULL,
	[Value2] [sql_variant] NULL,
	[Value3] [sql_variant] NULL,
	[Value4] [sql_variant] NULL,
	[Value5] [sql_variant] NULL,
	[Value6] [sql_variant] NULL,
	[Value7] [sql_variant] NULL,
	[Value8] [sql_variant] NULL,
	[Value9] [sql_variant] NULL,
	[Value10] [sql_variant] NULL,
	[Value11] [sql_variant] NULL,
	[Value12] [sql_variant] NULL,
	[Value13] [sql_variant] NULL,
	[Value14] [sql_variant] NULL,
	[Value15] [sql_variant] NULL,
	[Value16] [sql_variant] NULL,
	[Value17] [sql_variant] NULL,
	[Value18] [sql_variant] NULL,
	[Value19] [sql_variant] NULL,
	[Value20] [sql_variant] NULL,
	[Value21] [sql_variant] NULL,
	[Value22] [sql_variant] NULL,
	[Value23] [sql_variant] NULL,
	[Value24] [sql_variant] NULL,
	[Value25] [sql_variant] NULL,
	[Value26] [sql_variant] NULL,
	[Value27] [sql_variant] NULL,
	[Value28] [sql_variant] NULL,
	[Value29] [sql_variant] NULL,
	[Value30] [sql_variant] NULL,
	[Value31] [sql_variant] NULL,
	[Value32] [sql_variant] NULL,
	[Value33] [varbinary](max) NULL,
	[Value34] [varbinary](max) NULL,
	[Value35] [varbinary](max) NULL,
	[Value36] [varbinary](max) NULL,
	[Value37] [varbinary](max) NULL,
	[Value38] [varbinary](max) NULL,
	[Value39] [varbinary](max) NULL,
	[Value40] [varbinary](max) NULL,
	[Value41] [varbinary](max) NULL,
	[Value42] [varbinary](max) NULL,
	[Value43] [varbinary](max) NULL,
	[Value44] [varbinary](max) NULL,
	[Value45] [varbinary](max) NULL,
	[Value46] [varbinary](max) NULL,
	[Value47] [varbinary](max) NULL,
	[Value48] [varbinary](max) NULL,
	[Value49] [varbinary](max) NULL,
	[Value50] [varbinary](max) NULL,
	[Value51] [varbinary](max) NULL,
	[Value52] [varbinary](max) NULL,
	[Value53] [varbinary](max) NULL,
	[Value54] [varbinary](max) NULL,
	[Value55] [varbinary](max) NULL,
	[Value56] [varbinary](max) NULL,
	[Value57] [varbinary](max) NULL,
	[Value58] [varbinary](max) NULL,
	[Value59] [varbinary](max) NULL,
	[Value60] [varbinary](max) NULL,
	[Value61] [varbinary](max) NULL,
	[Value62] [varbinary](max) NULL,
	[Value63] [varbinary](max) NULL,
	[Value64] [varbinary](max) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  StoredProcedure [dbo].[PRO_INSERT_DB]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
------------------------------

CREATE  PROC [dbo].[PRO_INSERT_DB]
	@TABLE_NAME VARCHAR(50),        --表名
	@FIELD_NAME VARCHAR(1000),     --表中字段名
	@FIELD_VALUE VARCHAR(1500),     --对应字段的值
	@NUM INT OUTPUT	--返回值
	AS
	SET NOCOUNT ON
	BEGIN
		BEGIN TRANSACTION	--启动事务
		DECLARE @INSERT_STATEMENT VARCHAR(2500)
		if (@FIELD_NAME IS NULL or @FIELD_NAME ='')
			SET @INSERT_STATEMENT = 'INSERT INTO '+ @TABLE_NAME+' VALUES ('+@FIELD_VALUE+')'
		ELSE
			SET @INSERT_STATEMENT = 'INSERT INTO '+ @TABLE_NAME+'('+@FIELD_NAME+') VALUES ('+@FIELD_VALUE+')'
		EXEC(@INSERT_STATEMENT)
		IF(@@ERROR = 0)
			BEGIN 
				SET @NUM = 1
				COMMIT TRANSACTION
			END
		ELSE
			BEGIN
				SET @NUM = 0
				ROLLBACK TRANSACTION
			END
	END
GO
/****** Object:  Table [System.Activities.DurableInstancing].[RunnableInstancesTable]    Script Date: 05/13/2013 09:42:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [System.Activities.DurableInstancing].[RunnableInstancesTable](
	[SurrogateInstanceId] [bigint] NOT NULL,
	[WorkflowHostType] [uniqueidentifier] NULL,
	[ServiceDeploymentId] [bigint] NULL,
	[RunnableTime] [datetime] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RoleUsers]    Script Date: 05/13/2013 09:42:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RoleUsers](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[roleid] [int] NULL,
	[userid] [int] NULL,
	[isState] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Role]    Script Date: 05/13/2013 09:42:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Role](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](50) NULL,
	[isState] [int] NULL,
 CONSTRAINT [UQ__WF_ROLE__523A0C7E] UNIQUE NONCLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  UserDefinedFunction [System.Activities.DurableInstancing].[ParseBinaryPropertyValue]    Script Date: 05/13/2013 09:42:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [System.Activities.DurableInstancing].[ParseBinaryPropertyValue] (@startPosition int, @length int, @concatenatedKeyProperties varbinary(max))
returns varbinary(max)
as
begin
	if (@length > 0)
		return substring(@concatenatedKeyProperties, @startPosition + 1, @length)
	return null
end
GO
/****** Object:  Table [dbo].[Need_Send_Email]    Script Date: 05/13/2013 09:42:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Need_Send_Email](
	[detailsID] [int] NOT NULL,
	[EmailType] [int] NOT NULL,
	[IsState] [int] NOT NULL,
	[CreateTime] [datetime] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MenuRight]    Script Date: 05/13/2013 09:42:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MenuRight](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[flowid] [int] NOT NULL,
	[roleid] [int] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Menu]    Script Date: 05/13/2013 09:42:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Menu](
	[id] [int] NOT NULL,
	[parentid] [int] NOT NULL,
	[name] [varchar](50) NOT NULL,
	[url] [varchar](50) NULL,
	[orderum] [int] NOT NULL,
	[Display] [smallint] NOT NULL,
 CONSTRAINT [UQ__WF_FLOW__4F5D9FD3] UNIQUE NONCLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [System.Activities.DurableInstancing].[LockOwnersTable]    Script Date: 05/13/2013 09:42:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [System.Activities.DurableInstancing].[LockOwnersTable](
	[Id] [uniqueidentifier] NOT NULL,
	[SurrogateLockOwnerId] [bigint] IDENTITY(1,1) NOT NULL,
	[LockExpiration] [datetime] NOT NULL,
	[WorkflowHostType] [uniqueidentifier] NULL,
	[MachineName] [nvarchar](128) NOT NULL,
	[EnqueueCommand] [bit] NOT NULL,
	[DeletesInstanceOnCompletion] [bit] NOT NULL,
	[PrimitiveLockOwnerData] [varbinary](max) NULL,
	[ComplexLockOwnerData] [varbinary](max) NULL,
	[WriteOnlyPrimitiveLockOwnerData] [varbinary](max) NULL,
	[WriteOnlyComplexLockOwnerData] [varbinary](max) NULL,
	[EncodingOption] [tinyint] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [System.Activities.DurableInstancing].[KeysTable]    Script Date: 05/13/2013 09:42:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [System.Activities.DurableInstancing].[KeysTable](
	[Id] [uniqueidentifier] NOT NULL,
	[SurrogateKeyId] [bigint] IDENTITY(1,1) NOT NULL,
	[SurrogateInstanceId] [bigint] NULL,
	[EncodingOption] [tinyint] NULL,
	[Properties] [varbinary](max) NULL,
	[IsAssociated] [bit] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [System.Activities.DurableInstancing].[InstancesTable]    Script Date: 05/13/2013 09:42:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [System.Activities.DurableInstancing].[InstancesTable](
	[Id] [uniqueidentifier] NOT NULL,
	[SurrogateInstanceId] [bigint] IDENTITY(1,1) NOT NULL,
	[SurrogateLockOwnerId] [bigint] NULL,
	[PrimitiveDataProperties] [varbinary](max) NULL,
	[ComplexDataProperties] [varbinary](max) NULL,
	[WriteOnlyPrimitiveDataProperties] [varbinary](max) NULL,
	[WriteOnlyComplexDataProperties] [varbinary](max) NULL,
	[MetadataProperties] [varbinary](max) NULL,
	[DataEncodingOption] [tinyint] NULL,
	[MetadataEncodingOption] [tinyint] NULL,
	[Version] [bigint] NOT NULL,
	[PendingTimer] [datetime] NULL,
	[CreationTime] [datetime] NOT NULL,
	[LastUpdated] [datetime] NULL,
	[WorkflowHostType] [uniqueidentifier] NULL,
	[ServiceDeploymentId] [bigint] NULL,
	[SuspensionExceptionName] [nvarchar](450) NULL,
	[SuspensionReason] [nvarchar](max) NULL,
	[BlockingBookmarks] [nvarchar](max) NULL,
	[LastMachineRunOn] [nvarchar](450) NULL,
	[ExecutionStatus] [nvarchar](450) NULL,
	[IsInitialized] [bit] NULL,
	[IsSuspended] [bit] NULL,
	[IsReadyToRun] [bit] NULL,
	[IsCompleted] [bit] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Document]    Script Date: 05/13/2013 09:42:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Document](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](100) NOT NULL,
	[URL] [varchar](200) NULL,
	[Remark] [varchar](255) NULL,
	[WID] [int] NULL,
	[Result] [tinyint] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [System.Activities.DurableInstancing].[InstanceMetadataChangesTable]    Script Date: 05/13/2013 09:42:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [System.Activities.DurableInstancing].[InstanceMetadataChangesTable](
	[SurrogateInstanceId] [bigint] NOT NULL,
	[ChangeTime] [bigint] IDENTITY(1,1) NOT NULL,
	[EncodingOption] [tinyint] NOT NULL,
	[Change] [varbinary](max) NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[UsersBackstageLog]    Script Date: 05/13/2013 09:42:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[UsersBackstageLog](
	[id] [int] IDENTITY(1000,1) NOT NULL,
	[uid] [int] NOT NULL,
	[ActionType] [varchar](20) NOT NULL,
	[Descriptions] [varchar](100) NULL,
	[createtime] [datetime] NULL,
	[isState] [int] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Users]    Script Date: 05/13/2013 09:42:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Users](
	[ID] [int] IDENTITY(1001,1) NOT NULL,
	[UserID] [varchar](30) NOT NULL,
	[Email] [varchar](50) NOT NULL,
	[Password] [varchar](50) NOT NULL,
	[UserName] [varchar](20) NULL,
	[Telephone] [varchar](20) NULL,
	[QQ] [varchar](20) NULL,
	[IsState] [int] NOT NULL,
	[CreateTime] [datetime] NOT NULL,
	[LastLogin] [datetime] NOT NULL,
 CONSTRAINT [PK__Users__25DB9BFC] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY],
 CONSTRAINT [UQ__Users__26CFC035] UNIQUE NONCLUSTERED 
(
	[UserID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  StoredProcedure [dbo].[CheckUser]    Script Date: 05/13/2013 09:42:15 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  Procedure [dbo].[CheckUser]--用户检测

@userid varchar(50),--用户名
@userpass varchar(50),--密码
@num int output
as

begin
if exists(select UserID from [user] where (userid=@userid or email=@userid)and [password]=@userpass)
set @num=1
else if exists(select Userid from [user] where (userid=@userid or email=@userid))
set @num=2
else
set @num=3
end
GO
/****** Object:  StoredProcedure [dbo].[SelectRecord]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  Procedure [dbo].[SelectRecord]
@tablename varchar(100),
@record varchar(200),
@columnlist varchar(300),
@condition varchar(8000)
as
declare @sql varchar(8000)
begin
set @sql='select  '+@record+'  '+ @columnlist+' from '+@tablename+' '+@condition
Exec(@sql)
end
GO
/****** Object:  StoredProcedure [dbo].[SelectField]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SelectField]


@TableName varchar(100),

@Field varchar(100),

@NewField varchar(100),

@Condition varchar(8000)

as
declare @sql varchar(8000)
begin

set @sql='select count('+@Field+') as '+@NewField+' from '+@tablename+'  '+@Condition

Exec(@sql)
end
GO
/****** Object:  Table [dbo].[WorkFlowRole]    Script Date: 05/13/2013 09:42:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WorkFlowRole](
	[ID] [int] NOT NULL,
	[UID] [int] NULL,
	[WID] [int] NULL,
	[WSTEP] [int] NULL,
	[WParentStep] [int] NULL,
	[State] [tinyint] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[WorkFlowExecution]    Script Date: 05/13/2013 09:42:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[WorkFlowExecution](
	[ID] [int] NOT NULL,
	[DID] [int] NULL,
	[UID] [int] NULL,
	[Result] [varchar](16) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[WorkFlow]    Script Date: 05/13/2013 09:42:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[WorkFlow](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[Url] [varchar](100) NULL,
	[Remark] [varchar](255) NULL,
	[State] [tinyint] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[view_Users_Log]    Script Date: 05/13/2013 09:42:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[view_Users_Log]
	as
	select l.*,u.userID from UsersBackstageLog l join users u on l.uid=u.id
GO
/****** Object:  View [dbo].[view_UserPermissions]    Script Date: 05/13/2013 09:42:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[view_UserPermissions]
AS
SELECT     f.id, f.name, u.ID AS uid, u.UserID, u.Password, ru.isState, f.url, f.orderum, f.Display, f.parentid
FROM         dbo.Menu AS f INNER JOIN
                      dbo.MenuRight AS fr ON f.id = fr.flowid INNER JOIN
                      dbo.Role AS r ON fr.roleid = r.id INNER JOIN
                      dbo.RoleUsers AS ru ON ru.roleid = r.id INNER JOIN
                      dbo.Users AS u ON u.ID = ru.userid
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
         Begin Table = "fr"
            Begin Extent = 
               Top = 6
               Left = 218
               Bottom = 110
               Right = 360
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ru"
            Begin Extent = 
               Top = 6
               Left = 578
               Bottom = 125
               Right = 720
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "u"
            Begin Extent = 
               Top = 126
               Left = 38
               Bottom = 245
               Right = 195
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "f"
            Begin Extent = 
               Top = 6
               Left = 398
               Bottom = 125
               Right = 540
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "r"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 125
               Right = 180
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'view_UserPermissions'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'view_UserPermissions'
GO
/****** Object:  View [dbo].[view_UpdatePasswordForemail]    Script Date: 05/13/2013 09:42:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[view_UpdatePasswordForemail]
AS
SELECT     (SELECT     COUNT(*) AS Expr1
                       FROM          dbo.Users AS e2
                       WHERE      (ID >= e1.ID) AND (UserName = '') AND (Telephone = '') AND (CreateTime > '2010-08-11')) AS irows, ID, UserID, Email, Password, UserName AS Question, 
                      Telephone AS Answer, QQ AS UserName, IsState, CreateTime, LastLogin
FROM         dbo.Users AS e1
WHERE     (UserName = '') AND (Telephone = '') AND (CreateTime > '2010-08-11')
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
         Begin Table = "e1"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 125
               Right = 182
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'view_UpdatePasswordForemail'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'view_UpdatePasswordForemail'
GO
/****** Object:  View [dbo].[view_RoleUser]    Script Date: 05/13/2013 09:42:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[view_RoleUser]
AS
SELECT     rl.id AS rid, u.ID, u.UserID, rl.name, ru.isState, u.Email, u.UserName
FROM         dbo.Role AS rl INNER JOIN
                      dbo.RoleUsers AS ru ON rl.id = ru.roleid INNER JOIN
                      dbo.Users AS u ON ru.userid = u.ID
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
         Begin Table = "ru"
            Begin Extent = 
               Top = 6
               Left = 413
               Bottom = 125
               Right = 555
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "u"
            Begin Extent = 
               Top = 66
               Left = 38
               Bottom = 185
               Right = 195
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "rl"
            Begin Extent = 
               Top = 6
               Left = 233
               Bottom = 125
               Right = 375
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'view_RoleUser'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'view_RoleUser'
GO
/****** Object:  StoredProcedure [System.Activities.DurableInstancing].[InsertRunnableInstanceEntry]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [System.Activities.DurableInstancing].[InsertRunnableInstanceEntry]
	@surrogateInstanceId bigint,
	@workflowHostType uniqueidentifier,
	@serviceDeploymentId bigint, 
	@isSuspended bit,
	@isReadyToRun bit,
	@pendingTimer datetime
AS
begin    
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;	
	
	declare @runnableTime datetime
	
	if (@isSuspended  = 0)
	begin
		if (@isReadyToRun = 1)
		begin
			set @runnableTime = getutcdate()					
		end
		else if (@pendingTimer is not null)
		begin
			set @runnableTime = @pendingTimer
		end
	end
		
	if (@runnableTime is not null and @workflowHostType is not null)
	begin	
		insert into [RunnableInstancesTable]
			([SurrogateInstanceId], [WorkflowHostType], [ServiceDeploymentId], [RunnableTime])
			values( @surrogateInstanceId, @workflowHostType, @serviceDeploymentId, @runnableTime)
	end
end
GO
/****** Object:  StoredProcedure [System.Activities.DurableInstancing].[InsertPromotedProperties]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [System.Activities.DurableInstancing].[InsertPromotedProperties]
	@instanceId uniqueidentifier,
	@promotionName nvarchar(400),
	@value1 sql_variant = null,
	@value2 sql_variant = null,
	@value3 sql_variant = null,
	@value4 sql_variant = null,
	@value5 sql_variant = null,
	@value6 sql_variant = null,
	@value7 sql_variant = null,
	@value8 sql_variant = null,
	@value9 sql_variant = null,
	@value10 sql_variant = null,
	@value11 sql_variant = null,
	@value12 sql_variant = null,
	@value13 sql_variant = null,
	@value14 sql_variant = null,
	@value15 sql_variant = null,
	@value16 sql_variant = null,
	@value17 sql_variant = null,
	@value18 sql_variant = null,
	@value19 sql_variant = null,
	@value20 sql_variant = null,
	@value21 sql_variant = null,
	@value22 sql_variant = null,
	@value23 sql_variant = null,
	@value24 sql_variant = null,
	@value25 sql_variant = null,
	@value26 sql_variant = null,
	@value27 sql_variant = null,
	@value28 sql_variant = null,
	@value29 sql_variant = null,
	@value30 sql_variant = null,
	@value31 sql_variant = null,
	@value32 sql_variant = null,
	@value33 varbinary(max) = null,
	@value34 varbinary(max) = null,
	@value35 varbinary(max) = null,
	@value36 varbinary(max) = null,
	@value37 varbinary(max) = null,
	@value38 varbinary(max) = null,
	@value39 varbinary(max) = null,
	@value40 varbinary(max) = null,
	@value41 varbinary(max) = null,
	@value42 varbinary(max) = null,
	@value43 varbinary(max) = null,
	@value44 varbinary(max) = null,
	@value45 varbinary(max) = null,
	@value46 varbinary(max) = null,
	@value47 varbinary(max) = null,
	@value48 varbinary(max) = null,
	@value49 varbinary(max) = null,
	@value50 varbinary(max) = null,
	@value51 varbinary(max) = null,
	@value52 varbinary(max) = null,
	@value53 varbinary(max) = null,
	@value54 varbinary(max) = null,
	@value55 varbinary(max) = null,
	@value56 varbinary(max) = null,
	@value57 varbinary(max) = null,
	@value58 varbinary(max) = null,
	@value59 varbinary(max) = null,
	@value60 varbinary(max) = null,
	@value61 varbinary(max) = null,
	@value62 varbinary(max) = null,
	@value63 varbinary(max) = null,
	@value64 varbinary(max) = null
as
begin
	set nocount on
	set transaction isolation level read committed		
	set xact_abort on;	

	declare @surrogateInstanceId bigint

	select @surrogateInstanceId = [SurrogateInstanceId]
	from [InstancesTable]
	where [Id] = @instanceId

	insert into [System.Activities.DurableInstancing].[InstancePromotedPropertiesTable]
	values (@surrogateInstanceId, @promotionName, @value1, @value2, @value3, @value4, @value5, @value6, @value7, @value8,
			@value9, @value10, @value11, @value12, @value13, @value14, @value15, @value16, @value17, @value18, @value19,
			@value20, @value21, @value22, @value23, @value24, @value25, @value26, @value27, @value28, @value29, @value30,
			@value31, @value32, @value33, @value34, @value35, @value36, @value37, @value38, @value39, @value40, @value41,
			@value42, @value43, @value44, @value45, @value46, @value47, @value48, @value49, @value50, @value51, @value52,
			@value53, @value54, @value55, @value56, @value57, @value58, @value59, @value60, @value61, @value62, @value63,
			@value64)
end
GO
/****** Object:  View [dbo].[DocumentReviewTask]    Script Date: 05/13/2013 09:42:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[DocumentReviewTask]
AS
SELECT [SurrogateInstanceId]
      ,[PromotionName]
      ,[Value1] AS TicketId
FROM [document].[System.Activities.DurableInstancing].[InstancePromotedPropertiesTable]
GO
/****** Object:  StoredProcedure [System.Activities.DurableInstancing].[AssociateKeys]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [System.Activities.DurableInstancing].[AssociateKeys]
	@surrogateInstanceId bigint,
	@keysToAssociate xml = null,
	@concatenatedKeyProperties varbinary(max) = null,
	@encodingOption tinyint,
	@singleKeyId uniqueidentifier
as
begin	
	set nocount on
	set transaction isolation level read committed
	set xact_abort on;	
	
	declare @badKeyId uniqueidentifier
	declare @numberOfKeys int
	declare @result int
	declare @keys table([KeyId] uniqueidentifier, [Properties] varbinary(max))
	
	set @result = 0
	
	if (@keysToAssociate is not null)
	begin
		insert into @keys
		select T.Item.value('@KeyId', 'uniqueidentifier') as [KeyId],
			   [System.Activities.DurableInstancing].[ParseBinaryPropertyValue](T.Item.value('@StartPosition', 'int'), T.Item.value('@BinaryLength', 'int'), @concatenatedKeyProperties) as [Properties]
	    from @keysToAssociate.nodes('/CorrelationKeys/CorrelationKey') as T(Item)
		option (maxdop 1)

		select @numberOfKeys = count(1) from @keys
		
		insert into [KeysTable] ([Id], [SurrogateInstanceId], [IsAssociated])
		select [KeyId], @surrogateInstanceId, 1
		from @keys as [Keys]
		
		if (@@rowcount != @numberOfKeys)
		begin
			select top 1 @badKeyId = [Keys].[KeyId] 
			from @keys as [Keys]
			join [KeysTable] on [Keys].[KeyId] = [KeysTable].[Id]
			where [KeysTable].[SurrogateInstanceId] != @surrogateInstanceId
			
			if (@@rowcount != 0)
			begin
				select 3 as 'Result', @badKeyId
				return 3
			end
		end
		
		update [KeysTable]
		set [Properties] = [Keys].[Properties],
			[EncodingOption] = @encodingOption
		from @keys as [Keys]
		join [KeysTable] on [Keys].[KeyId] = [KeysTable].[Id]
		where [KeysTable].[EncodingOption] is null
	end
	
	if (@singleKeyId is not null)
	begin
InsertSingleKey:
		update [KeysTable]
		set [Properties] = @concatenatedKeyProperties,
			[EncodingOption] = @encodingOption
		where ([Id] = @singleKeyId) and ([SurrogateInstanceId] = @surrogateInstanceId)
			  
		if (@@rowcount != 1)
		begin
			if exists (select [Id] from [KeysTable] where [Id] = @singleKeyId)
			begin
				select 3 as 'Result', @singleKeyId
				return 3
			end
			
			insert into [KeysTable] ([Id], [SurrogateInstanceId], [IsAssociated], [Properties], [EncodingOption])
			values (@singleKeyId, @surrogateInstanceId, 1, @concatenatedKeyProperties, @encodingOption)
			
			if (@@rowcount = 0)
				goto InsertSingleKey
		end
	end
end
GO
/****** Object:  StoredProcedure [System.Activities.DurableInstancing].[DetectRunnableInstances]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [System.Activities.DurableInstancing].[DetectRunnableInstances]
	@workflowHostType uniqueidentifier
as
begin
	set nocount on
	set transaction isolation level read committed	
	set xact_abort on;	
	set deadlock_priority low
	
	declare @nextRunnableTime datetime

	select top 1 @nextRunnableTime = [RunnableInstancesTable].[RunnableTime]
			  from [RunnableInstancesTable] with (readpast)
			  where [WorkflowHostType] = @workflowHostType
			  order by [WorkflowHostType], [RunnableTime]
			  
	select 0 as 'Result', @nextRunnableTime, getutcdate()
end
GO
/****** Object:  StoredProcedure [System.Activities.DurableInstancing].[DeleteLockOwner]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [System.Activities.DurableInstancing].[DeleteLockOwner]
	@surrogateLockOwnerId bigint
as
begin
	set nocount on
	set transaction isolation level read committed
	set deadlock_priority low
	set xact_abort on;	
	
	begin transaction
	
	declare @lockAcquired bigint
	declare @result int
	set @result = 0
	
	exec @lockAcquired = sp_getapplock @Resource = 'InstanceStoreLock', @LockMode = 'Shared', @LockTimeout = 10000
		
	if (@lockAcquired < 0)
	begin
		select @result as 'Result'
		set @result = 13
	end
	
	if (@result = 0)
	begin
		update [LockOwnersTable]
		set [LockExpiration] = '2000-01-01T00:00:00'
		where [SurrogateLockOwnerId] = @surrogateLockOwnerId
	end
	
	if (@result != 13)
		exec sp_releaseapplock @Resource = 'InstanceStoreLock' 
	
	if (@result = 0)
	begin
		commit transaction
		select 0 as 'Result'
	end
	else
		rollback transaction
end
GO
/****** Object:  StoredProcedure [System.Activities.DurableInstancing].[DeleteInstance]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [System.Activities.DurableInstancing].[DeleteInstance]
	@surrogateInstanceId bigint = null
as
begin	
	set nocount on
	set transaction isolation level read committed		
	set xact_abort on;	
	
	delete [InstancePromotedPropertiesTable]
	where [SurrogateInstanceId] = @surrogateInstanceId
		
	delete [KeysTable]
	where [SurrogateInstanceId] = @surrogateInstanceId
		
	delete [InstanceMetadataChangesTable]
	where [SurrogateInstanceId] = @surrogateInstanceId

	delete [RunnableInstancesTable] 
	where [SurrogateInstanceId] = @surrogateInstanceId

	delete [InstancesTable] 
	where [SurrogateInstanceId] = @surrogateInstanceId

end
GO
/****** Object:  StoredProcedure [System.Activities.DurableInstancing].[CreateServiceDeployment]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [System.Activities.DurableInstancing].[CreateServiceDeployment]	
	@serviceDeploymentHash uniqueIdentifier,
	@siteName nvarchar(max),
	@relativeServicePath nvarchar(max),
	@relativeApplicationPath nvarchar(max),
	@serviceName nvarchar(max),
    @serviceNamespace nvarchar(max),
    @serviceDeploymentId bigint output
as
begin
	set nocount on
	set transaction isolation level read committed		
	set xact_abort on;	
	
		--Create or select the service deployment id
		insert into [ServiceDeploymentsTable]
			([ServiceDeploymentHash], [SiteName], [RelativeServicePath], [RelativeApplicationPath], [ServiceName], [ServiceNamespace])
			values (@serviceDeploymentHash, @siteName, @relativeServicePath, @relativeApplicationPath, @serviceName, @serviceNamespace)
			
		if (@@rowcount = 0)
		begin		
			select @serviceDeploymentId = [Id]
			from [ServiceDeploymentsTable]
			where [ServiceDeploymentHash] = @serviceDeploymentHash		
		end
		else			
		begin
			set @serviceDeploymentId = scope_identity()		
		end	
		
		select 0 as 'Result', @serviceDeploymentId		
end
GO
/****** Object:  StoredProcedure [System.Activities.DurableInstancing].[CreateLockOwner]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [System.Activities.DurableInstancing].[CreateLockOwner]
	@lockOwnerId uniqueidentifier,
	@lockTimeout int,
	@workflowHostType uniqueidentifier,
	@enqueueCommand bit,
	@deleteInstanceOnCompletion bit,	
	@primitiveLockOwnerData varbinary(max),
	@complexLockOwnerData varbinary(max),
	@writeOnlyPrimitiveLockOwnerData varbinary(max),
	@writeOnlyComplexLockOwnerData varbinary(max),
	@encodingOption tinyint,
	@machineName nvarchar(128)
as
begin
	set nocount on
	set transaction isolation level read committed
	set xact_abort on;	
	
	begin transaction
	
	declare @lockAcquired bigint
	declare @lockExpiration datetime
	declare @now datetime
	declare @result int
	declare @surrogateLockOwnerId bigint
	
	set @result = 0
	
	exec @lockAcquired = sp_getapplock @Resource = 'InstanceStoreLock', @LockMode = 'Shared', @LockTimeout = 10000
		
	if (@lockAcquired < 0)
	begin
		select @result as 'Result'
		set @result = 13
	end
	
	if (@result = 0)
	begin
		set @now = getutcdate()
		
		if (@lockTimeout = 0)
			set @lockExpiration = '9999-12-31T23:59:59';
		else 
			set @lockExpiration = dateadd(second, @lockTimeout, getutcdate());
		
		insert into [LockOwnersTable] ([Id], [LockExpiration], [MachineName], [WorkflowHostType], [EnqueueCommand], [DeletesInstanceOnCompletion], [PrimitiveLockOwnerData], [ComplexLockOwnerData], [WriteOnlyPrimitiveLockOwnerData], [WriteOnlyComplexLockOwnerData], [EncodingOption])
		values (@lockOwnerId, @lockExpiration, @machineName, @workflowHostType, @enqueueCommand, @deleteInstanceOnCompletion, @primitiveLockOwnerData, @complexLockOwnerData, @writeOnlyPrimitiveLockOwnerData, @writeOnlyComplexLockOwnerData, @encodingOption)
		
		set @surrogateLockOwnerId = scope_identity()
	end
	
	if (@result != 13)
		exec sp_releaseapplock @Resource = 'InstanceStoreLock'
	
	if (@result = 0)
	begin
		commit transaction
		select 0 as 'Result', @surrogateLockOwnerId
	end
	else
		rollback transaction
end
GO
/****** Object:  StoredProcedure [System.Activities.DurableInstancing].[CreateInstance]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [System.Activities.DurableInstancing].[CreateInstance]
	@instanceId uniqueidentifier,
	@surrogateLockOwnerId bigint,
	@workflowHostType uniqueidentifier,
	@serviceDeploymentId bigint,
	@surrogateInstanceId bigint output,
	@result int output
as
begin
	set nocount on
	set transaction isolation level read committed
	set xact_abort on;	
	
	set @surrogateInstanceId = 0
	set @result = 0
	
	begin try
		insert into [InstancesTable] ([Id], [SurrogateLockOwnerId], [CreationTime], [WorkflowHostType], [ServiceDeploymentId], [Version])
		values (@instanceId, @surrogateLockOwnerId, getutcdate(), @workflowHostType, @serviceDeploymentId, 1)
		
		set @surrogateInstanceId = scope_identity()		
	end try
	begin catch
		if (error_number() != 2601)
		begin
			set @result = 99
			select @result as 'Result'
		end
	end catch
end
GO
/****** Object:  StoredProcedure [System.Activities.DurableInstancing].[CompleteKeys]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [System.Activities.DurableInstancing].[CompleteKeys]
	@surrogateInstanceId bigint,
	@keysToComplete xml = null
as
begin	
	set nocount on
	set transaction isolation level read committed
	set xact_abort on;	
	
	declare @badKeyId uniqueidentifier
	declare @numberOfKeys int
	declare @result int
	declare @keyIds table([KeyId] uniqueidentifier)
	
	set @result = 0
	
	if (@keysToComplete is not null)
	begin
		insert into @keyIds
		select T.Item.value('@KeyId', 'uniqueidentifier')
		from @keysToComplete.nodes('//CorrelationKey') as T(Item)
		option(maxdop 1)
		
		select @numberOfKeys = count(1) from @keyIds
		
		update [KeysTable]
		set [IsAssociated] = 0
		from @keyIds as [KeyIds]
		join [KeysTable] on [KeyIds].[KeyId] = [KeysTable].[Id]
		where [SurrogateInstanceId] = @surrogateInstanceId
		
		if (@@rowcount != @numberOfKeys)
		begin
			select top 1 @badKeyId = [MissingKeys].[MissingKeyId]
			from
				(select [KeyIds].[KeyId] as [MissingKeyId] 
				 from @keyIds as [KeyIds]
				 except
				 select [Id] from [KeysTable] where [SurrogateInstanceId] = @surrogateInstanceId) as MissingKeys
		
			select 4 as 'Result', @badKeyId
			return 4
		end
	end
end
GO
/****** Object:  StoredProcedure [dbo].[checkUserID]    Script Date: 05/13/2013 09:42:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[checkUserID]
@UserID varchar(50),
@num int output
as
begin
	declare @countnum int 
	select @countnum = count(*) from users where userID = @UserID
	if @countnum = 0
		select @num  = 1
	else
		select @num = 0
end
GO
/****** Object:  StoredProcedure [dbo].[checkUserEmail]    Script Date: 05/13/2013 09:42:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[checkUserEmail]
@UserEmail varchar(50),
@num int output
as
begin
	declare @countnum int 
	select @countnum = count(*) from users where Email = @UserEmail
	if @countnum = 0
		select @num  = 1
	else
		select @num = 0
end
GO
/****** Object:  View [System.Activities.DurableInstancing].[Instances]    Script Date: 05/13/2013 09:42:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [System.Activities.DurableInstancing].[Instances] as
      select [InstancesTable].[Id] as [InstanceId],
             [PendingTimer],
             [CreationTime],
             [LastUpdated] as [LastUpdatedTime],
             [InstancesTable].[ServiceDeploymentId],
             [SuspensionExceptionName],
             [SuspensionReason],
             [BlockingBookmarks] as [ActiveBookmarks],
             case when [LockOwnersTable].[LockExpiration] > getutcdate()
				then [LockOwnersTable].[MachineName]
				else null
				end as [CurrentMachine],
             [LastMachineRunOn] as [LastMachine],
             [ExecutionStatus],
             [IsInitialized],
             [IsSuspended],
             [IsCompleted],
             [InstancesTable].[DataEncodingOption] as [EncodingOption],
             [PrimitiveDataProperties] as [ReadWritePrimitiveDataProperties],
             [WriteOnlyPrimitiveDataProperties],
             [ComplexDataProperties] as [ReadWriteComplexDataProperties],
             [WriteOnlyComplexDataProperties]
      from [System.Activities.DurableInstancing].[InstancesTable]
      left outer join [System.Activities.DurableInstancing].[LockOwnersTable]
      on [InstancesTable].[SurrogateLockOwnerId] = [LockOwnersTable].[SurrogateLockOwnerId]
GO
/****** Object:  StoredProcedure [System.Activities.DurableInstancing].[LockInstance]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [System.Activities.DurableInstancing].[LockInstance]
	@instanceId uniqueidentifier,
	@surrogateLockOwnerId bigint,
	@handleInstanceVersion bigint,
	@handleIsBoundToLock bit,
	@surrogateInstanceId bigint output,
	@lockVersion bigint output,
	@result int output
as
begin
	set nocount on
	set transaction isolation level read committed
	set xact_abort on;	
	
	declare @isCompleted bit
	declare @currentLockOwnerId bigint
	declare @currentVersion bigint

TryLockInstance:
	set @currentLockOwnerId = 0
	set @surrogateInstanceId = 0
	set @result = 0
	
	update [InstancesTable]
	set [SurrogateLockOwnerId] = @surrogateLockOwnerId,
		@lockVersion = [Version] = case when ([InstancesTable].[SurrogateLockOwnerId] is null or 
											  [InstancesTable].[SurrogateLockOwnerId] != @surrogateLockOwnerId)
									then [Version] + 1
									else [Version]
								  end,
		@surrogateInstanceId = [SurrogateInstanceId]
	from [InstancesTable]
	left outer join [LockOwnersTable] on [InstancesTable].[SurrogateLockOwnerId] = [LockOwnersTable].[SurrogateLockOwnerId]
	where ([InstancesTable].[Id] = @instanceId) and
		  ([InstancesTable].[IsCompleted] = 0) and
		  (
		   (@handleIsBoundToLock = 0 and
		    (
		     ([InstancesTable].[SurrogateLockOwnerId] is null) or
		     ([LockOwnersTable].[SurrogateLockOwnerId] is null) or
			  (
		       ([LockOwnersTable].[LockExpiration] < getutcdate()) and
               ([LockOwnersTable].[SurrogateLockOwnerId] != @surrogateLockOwnerId)
			  )
		    )
		   ) or 
		   (
			(@handleIsBoundToLock = 1) and
		    ([LockOwnersTable].[SurrogateLockOwnerId] = @surrogateLockOwnerId) and
		    ([LockOwnersTable].[LockExpiration] > getutcdate()) and
		    ([InstancesTable].[Version] = @handleInstanceVersion)
		   )
		  )
	
	if (@@rowcount = 0)
	begin
		if not exists (select * from [LockOwnersTable] where ([SurrogateLockOwnerId] = @surrogateLockOwnerId) and ([LockExpiration] > getutcdate()))
		begin
			if exists (select * from [LockOwnersTable] where [SurrogateLockOwnerId] = @surrogateLockOwnerId)
				set @result = 11
			else
				set @result = 12
			
			select @result as 'Result'
			return 0
		end
		
		select @currentLockOwnerId = [SurrogateLockOwnerId],
			   @isCompleted = [IsCompleted],
			   @currentVersion = [Version]
		from [InstancesTable]
		where [Id] = @instanceId
	
		if (@@rowcount = 1)
		begin
			if (@isCompleted = 1)
				set @result = 7
			else if (@currentLockOwnerId = @surrogateLockOwnerId)
			begin
				if (@handleIsBoundToLock = 1)
					set @result = 10
				else
					set @result = 14
			end
			else if (@handleIsBoundToLock = 0)
				set @result = 2
			else
				set @result = 6
		end
		else if (@handleIsBoundToLock = 1)
			set @result = 6
	end

	if (@result != 0 and @result != 2)
		select @result as 'Result', @instanceId, @currentVersion
	else if (@result = 2)
	begin
		select @result as 'Result', @instanceId, [LockOwnersTable].[Id], [LockOwnersTable].[EncodingOption], [PrimitiveLockOwnerData], [ComplexLockOwnerData]
		from [LockOwnersTable]
		join [InstancesTable] on [InstancesTable].[SurrogateLockOwnerId] = [LockOwnersTable].[SurrogateLockOwnerId]
		where [InstancesTable].[SurrogateLockOwnerId] = @currentLockOwnerId and
			  [InstancesTable].[Id] = @instanceId
		
		if (@@rowcount = 0)
			goto TryLockInstance
	end
end
GO
/****** Object:  StoredProcedure [System.Activities.DurableInstancing].[RecoverInstanceLocks]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [System.Activities.DurableInstancing].[RecoverInstanceLocks]
as
begin
	set nocount on;
	set transaction isolation level read committed;
	set xact_abort on;
	set deadlock_priority low;
    
	declare @now as datetime
	set @now = getutcdate()	
	
	insert into [RunnableInstancesTable] ([SurrogateInstanceId], [WorkflowHostType], [ServiceDeploymentId], [RunnableTime])
		select top (1000) instances.[SurrogateInstanceId], instances.[WorkflowHostType], instances.[ServiceDeploymentId], @now
		from [LockOwnersTable] lockOwners with (readpast) inner loop join
			 [InstancesTable] instances with (readpast)
				on instances.[SurrogateLockOwnerId] = lockOwners.[SurrogateLockOwnerId]
			where 
				lockOwners.[LockExpiration] <= @now and
				instances.[IsInitialized] = 1 and
				instances.[IsSuspended] = 0

	delete from [LockOwnersTable] with (readpast)
	from [LockOwnersTable] lockOwners
	where [LockExpiration] <= @now
	and not exists
	(
		select top (1) 1
		from [InstancesTable] instances with (nolock)
		where instances.[SurrogateLockOwnerId] = lockOwners.[SurrogateLockOwnerId]
	)
end
GO
/****** Object:  StoredProcedure [dbo].[proc_EditUserInfo]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[proc_EditUserInfo]
	@id int,--会员id
	@username nvarchar(50), --真实姓名
	@qq nvarchar(12),  --联系QQ
	@countryid nvarchar(20), --所属区域
	@intention varchar(5), --网站意向
	@PaymentType int,--支付方式
	@PaymentName nvarchar(50), --支付姓名
	@Payment nvarchar(50),--支付帐号
	@flag int,--1修改支付宝 -2不修改支付宝
	@pwd nvarchar(50),--密码
	@num int output
as
set xact_abort on  
begin
	declare @password nvarchar(50)
	set @password=(select password from users where id=@id)
	set @num=0
	begin tran
		if @password=@pwd
		begin
			if @flag=1
				update users set username=@username,QQ=@qq,countryid=@countryid,PaymentType=@PaymentType,PaymentName=@PaymentName,Payment=@Payment	where id=@id
			else
				update users set username=@username,QQ=@qq,countryid=@countryid where id=@id
			update UserExpandInfo  set intention=@intention where uid=@id
			set @num=1
		end
		else
			set @num=2
	commit tran
end
GO
/****** Object:  StoredProcedure [dbo].[proc_EditPwdProtect]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[proc_EditPwdProtect]
	@uid int,--用户id
	@answer nvarchar(30),--密保答案
	@newquestion varchar(10),--新密保问题
	@newanswer nvarchar(30),--新密保答案
	@flag int,--1:添加 2:修改
	@num int output
as
begin
	if @flag=2
	begin
		declare @oldanswer nvarchar(30)
		set @oldanswer=(select answer from users where id=@uid)
		if (@oldanswer='' or @oldanswer<>@answer)
			set @num=2
		else
		begin
			update users set question=@newquestion,answer=@newanswer where id=@uid
			set @num=1
		end
	end
	else
	begin
		update users set question=@newquestion,answer=@newanswer where id=@uid
		set @num=1
	end
end
GO
/****** Object:  StoredProcedure [dbo].[proc_EditPwd]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[proc_EditPwd]
	@uid int,--用户id
	@oldpwd nvarchar(50),--旧密码
	@pwd varchar(50),--新密码
	@num int output
as
begin
	declare @password nvarchar(30)
	set @password=(select password from users where id=@uid)
	if (@oldpwd<>@password)
		set @num=2
	else
	begin
		update users set password=@pwd where id=@uid
		set @num=1
	end
end
GO
/****** Object:  StoredProcedure [dbo].[pro_WorkFlow_Update]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[pro_WorkFlow_Update]
@ID int,
@Name	Varchar(50),
@URL	Varchar(100),
@Remark Varchar(255),
@State	int,
@num int output
as
	set nocount on
begin
	begin transaction
	update WorkFlow set Name=@Name,URL=@URL,Remark=@Remark,[State]=@State where [ID] = @ID
	if @@error = 0
		begin
			select @num = 1
			commit transaction
		end
	else
		begin
			select @num = 0
			rollback transaction
		end
end
GO
/****** Object:  StoredProcedure [dbo].[pro_WorkFlow_Del]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[pro_WorkFlow_Del]
@ID int,
@num int output
as
begin
	set @num=1
	begin transaction   --开始事务
	delete from WorkFlow where [ID] = @ID  --删除有关用户信息
	if @@error<>0
	begin
		set @num=0
	end
	if @num=1
	begin
		commit  /*提交*/
	end
	else
	begin
		rollback  /*回滚*/
	end
end
GO
/****** Object:  StoredProcedure [dbo].[pro_WorkFlow_Add]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pro_WorkFlow_Add]
	@Name	Varchar(50),
	@URL	Varchar(100),
	@Remark Varchar(255),
	@State	int,
	@num int output
as
begin
	insert into WorkFlow values(@Name,@URL,@Remark,@State)
	select @@identity
	if @@error = 0
		select @num = @@identity
	else
		select @num = 0
end
GO
/****** Object:  StoredProcedure [dbo].[pro_User_Update]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[pro_User_Update]
@ID int,
@UserID	Varchar(30),
@Email	Varchar(50),
@Password Varchar(50),
@UserName Varchar(20),
@Telephone Varchar(20),
@QQ Varchar(20),
@num int output
as
	set nocount on
begin
	begin transaction
	update Users set UserID=@UserID,Email=@Email,[Password]=@Password,UserName=@UserName,Telephone=@Telephone,QQ=@QQ where [ID] = @ID
	if @@error = 0
		begin
			select @num = 1
			commit transaction
		end
	else
		begin
			select @num = 0
			rollback transaction
		end
end
GO
/****** Object:  StoredProcedure [dbo].[pro_User_NoPasswordUpdate]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[pro_User_NoPasswordUpdate]
@ID int,
@UserID	Varchar(30),
@Email	Varchar(50),
@UserName Varchar(20),
@Telephone Varchar(20),
@QQ Varchar(20),
@num int output
as
	set nocount on
begin
	begin transaction
	update Users set UserID=@UserID,Email=@Email,UserName=@UserName,Telephone=@Telephone,QQ=@QQ where [ID] = @ID
	if @@error = 0
		begin
			select @num = 1
			commit transaction
		end
	else
		begin
			select @num = 0
			rollback transaction
		end
end
GO
/****** Object:  StoredProcedure [dbo].[pro_User_Del]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pro_User_Del]
@ID int,
@num int output
as
begin
	set @num=1
	begin transaction   --开始事务
	delete from Users where [ID] = @ID  --删除有关用户信息
	if @@error<>0
	begin
		set @num=0
	end
	if @num=1
	begin
		commit  /*提交*/
	end
	else
	begin
		rollback  /*回滚*/
	end
end
GO
/****** Object:  StoredProcedure [dbo].[pro_User_Add]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pro_User_Add]
	@UserID	Varchar(30),
	@Email	Varchar(50),
	@Password Varchar(50),
	@UserName Varchar(20),
	@Telephone Varchar(20),
	@QQ Varchar(20),
	@num int output
as
begin
	declare @countnum int
	select @countnum = count(*) from users where userID = @UserID or Email = @Email
	if @countnum = 0
	begin  
		insert into Users values(@UserID,@Email,@Password,@UserName,@Telephone,@QQ,default,default,default)
		select @@identity
		if @@error = 0
			select @num = @@identity
		else
			select @num = 0
	end
	else
		select @num = -1
end
GO
/****** Object:  StoredProcedure [dbo].[pro_UpdateRole]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[pro_UpdateRole]
	@id int,
	@name varchar(50),
	@isState int,
	@num int output
	as
	set nocount on 
	begin
		begin transaction
		update Role set name= @name,isState =@isState where id =@id
		if @@error =0
			begin
				set @num=1
				commit transaction
			end
		else
			begin
				set @num =0
				rollback transaction
			end
	end
GO
/****** Object:  StoredProcedure [dbo].[pro_UpdateInfo]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[pro_UpdateInfo]
	@id int,
	@value varchar(max),
	@num int output
	as
	set nocount on 
	begin
		begin transaction
		update SystemInfo set value =@value where id =@id
		if @@error =0
			begin
				set @num=1
				commit transaction
			end
		else
			begin
				set @num =0
				rollback transaction
			end
	end
GO
/****** Object:  StoredProcedure [dbo].[pro_InputUserOperating]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[pro_InputUserOperating]
	@uid int,
	@ActionType varchar(20),
	@Descriptions varchar(100),
	@num int output
	as
	set nocount on
	begin
		begin transaction
		insert into UsersBackstageLog values(@uid,@ActionType,@Descriptions,getdate(),1)
		if @@error =0
			begin 
				set @num=1
				commit transaction
			end
		else
			begin
				set @num=0
				rollback transaction
			end
	end
GO
/****** Object:  StoredProcedure [dbo].[pro_getBackPassword]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[pro_getBackPassword]
@UserId varchar(50),
@Question Varchar(100),
@Answer	Varchar(100),
@NewPassword varchar(50),
@num int output
as
begin
	declare @count int
	select @count = count(*) from Users where UserId = @UserId and Question =@Question and Answer = @Answer
	if @count > 0
	begin
		update users set [Password] = @NewPassword where UserId = @UserId and Question =@Question and Answer = @Answer
		if @@error = 0
		       select @num = 1
		else
		       select @num = 0
	end
	else
		select @num = 0
end
GO
/****** Object:  StoredProcedure [dbo].[pro_Edit_RoleUsers]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pro_Edit_RoleUsers]
	@roleid	int,
	@userid	int,
	@num int output
as
begin
	update RoleUsers set [roleid]=@roleid where [userid] = @userid
	if @@error = 0
		select @num = 1
	else
		select @num = 0
end
GO
/****** Object:  StoredProcedure [dbo].[pro_Document_Del]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[pro_Document_Del]
@ID int,
@num int output
as
begin
	set @num=1
	begin transaction   --开始事务
	delete from Document where [ID] = @ID  --删除有关用户信息
	if @@error<>0
	begin
		set @num=0
	end
	if @num=1
	begin
		commit  /*提交*/
	end
	else
	begin
		rollback  /*回滚*/
	end
end
GO
/****** Object:  StoredProcedure [dbo].[pro_Document_Add]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pro_Document_Add]
	@Name	Varchar(50),
	@URL	Varchar(100),
	@Remark Varchar(255),
	@WID	int,
	@num int output
as
begin
	insert into Document values(@Name,@URL,@Remark,@WID,0)
	select @@identity
	if @@error = 0
		select @num = @@identity
	else
		select @num = 0
end
GO
/****** Object:  StoredProcedure [dbo].[pro_DelUserInfo]    Script Date: 05/13/2013 09:42:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[pro_DelUserInfo]
	@uid int,
	@isState int,
	@num int output
as
set xact_abort on
begin 
	begin transaction
	declare @flag int--可用余额
	declare @Tlag int
	set @flag =0
	set @Tlag =0
	if @isState <> 1 and @isState <> 0
	begin
		select @flag = @flag + count(*) from LinkOrder where uid=@uid
		select @flag = @flag + count(*) from UserFinanceLog where uid=@uid
		select @flag = @flag + count(*) from website where uid=@uid
		if @flag=0 --可以删除
		begin
			--下面是删除与UID相关联的
			delete from WF_ROLEUSER where userID =@uid --角色用户表
			delete from NewOrder_Notice where uid=@uid --邮件发送
			delete from Evidence where [type] =3 and EVid =@uid --处罚记录表
			delete from UserslinkStorage where uid =@uid --会员链接收藏
			delete from PageLink where uid =@uid --链接出售页面
			delete from SaveLinks where uid =@uid --购物车
			delete from SignOrders where sgbuid =@uid 
			delete from SignInfo where sguid =@uid 
			delete from AuditTradingInfo where tuid =@uid --审核信息表
			delete from TemplateOrders where uid =@uid --模板交易订单表
			delete from DomainOrders where uid =@uid --域名交易
			delete from SoftManOrders where uid =@uid --软文交易订单表
			delete from WebSiteOrders where uid =@uid --（网站交易订单表）
			delete from TemplateTrading where uid =@uid --模板交易
			delete from DomainTrading where uid =@uid --域名交易
			delete from SoftManTrading where uid =@uid --交换外链表
			delete from WebsiteTrading where uid =@uid --网站交易
			delete from SellerGroupbuySite where uid =@uid --卖家团购
			delete from SellerGroupbuy where uid =@uid --卖家发布针对于多个买家的团购信息表
			delete from RequireOrders where uid =@uid --链接求购表
			delete from LinkExchange where requid =@uid or resuid =@uid --交换外链表
			
			if @isState = -1
			begin
				update Users set isState =@isState where id=@uid --删除会员表信息
				set @num =1
			end
			else --传入-2，表示彻底删除
			begin
				select @Tlag = @Tlag + count(*) from Users where id=@uid and (Balance >0 or BlockedBalance >0)
				if(@Tlag = 0)
				begin
					delete from UserExpandInfo where uid =@uid --会员拓展表
					delete from Users where id =@uid --彻底删除会员表的信息
					set @num = 1
				end
				else
					set @num =0
			end
		end
		else
		   set @num= 0
	end
	else
	begin
		update Users set isState=@isState where id=@uid 
		set @num = 1
	end
	commit transaction
end
GO
/****** Object:  StoredProcedure [dbo].[pro_DeleteMenuRIGHT]    Script Date: 05/13/2013 09:42:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[pro_DeleteMenuRIGHT]
	@roleid int,
	@num int output
	as
	set nocount on
	begin
		begin transaction
		delete MenuRight where roleid=@roleid
		if @@error =0
			begin
				set @num=1
				commit transaction
			end
		else
			begin
				set @num =0
				rollback transaction
			end
	end
GO
/****** Object:  View [System.Activities.DurableInstancing].[InstancePromotedProperties]    Script Date: 05/13/2013 09:42:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [System.Activities.DurableInstancing].[InstancePromotedProperties] with schemabinding as
      select [InstancesTable].[Id] as [InstanceId],
			 [InstancesTable].[DataEncodingOption] as [EncodingOption],
			 [PromotionName],
			 [Value1],
			 [Value2],
			 [Value3],
			 [Value4],
			 [Value5],
			 [Value6],
			 [Value7],
			 [Value8],
			 [Value9],
			 [Value10],
			 [Value11],
			 [Value12],
			 [Value13],
			 [Value14],
			 [Value15],
			 [Value16],
			 [Value17],
			 [Value18],
			 [Value19],
			 [Value20],
			 [Value21],
			 [Value22],
			 [Value23],
			 [Value24],
			 [Value25],
			 [Value26],
			 [Value27],
			 [Value28],
			 [Value29],
			 [Value30],
			 [Value31],
			 [Value32],
			 [Value33],
			 [Value34],
			 [Value35],
			 [Value36],
			 [Value37],
			 [Value38],
			 [Value39],
			 [Value40],
			 [Value41],
			 [Value42],
			 [Value43],
			 [Value44],
			 [Value45],
			 [Value46],
			 [Value47],
			 [Value48],
			 [Value49],
			 [Value50],
			 [Value51],
			 [Value52],
			 [Value53],
			 [Value54],
			 [Value55],
			 [Value56],
			 [Value57],
			 [Value58],
			 [Value59],
			 [Value60],
			 [Value61],
			 [Value62],
			 [Value63],
			 [Value64]
    from [System.Activities.DurableInstancing].[InstancePromotedPropertiesTable]
    join [System.Activities.DurableInstancing].[InstancesTable]
    on [InstancePromotedPropertiesTable].[SurrogateInstanceId] = [InstancesTable].[SurrogateInstanceId]
GO
/****** Object:  View [System.Activities.DurableInstancing].[ServiceDeployments]    Script Date: 05/13/2013 09:42:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [System.Activities.DurableInstancing].[ServiceDeployments] as
      select [Id] as [ServiceDeploymentId],
             [SiteName],
             [RelativeServicePath],
             [RelativeApplicationPath],
             [ServiceName],
             [ServiceNamespace]
      from [System.Activities.DurableInstancing].[ServiceDeploymentsTable]
GO
/****** Object:  StoredProcedure [dbo].[pro_insertRole]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[pro_insertRole]
	@name varchar(50),
	@isState int,
	@num int output
	as
	set nocount on
	begin
		begin transaction
		insert into Role values(@name,@isState)
		select @@identity
		if @@error = 0
		begin
			set @num= @@identity
			commit transaction
		end
		else
		begin
			set @num=0
			rollback transaction
		end
	end
GO
/****** Object:  StoredProcedure [dbo].[pro_insertMenuRIGHT]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[pro_insertMenuRIGHT]
	@flowid int,
	@roleid int,
	@num int output
	as
	set nocount on
	begin
		begin transaction
		insert into MenuRight values(@flowid,@roleid)
		if @@error =0
		begin
			set @num=1
			commit transaction
		end
		else
		begin
			set @num =0
			rollback transaction
		end
	end
GO
/****** Object:  StoredProcedure [dbo].[pro_Add_RoleUsers]    Script Date: 05/13/2013 09:42:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[pro_Add_RoleUsers]
	@roleid	int,
	@userid	int,
	@num int output
as
begin
	insert into RoleUsers values(@roleid,@userid,1)
	if @@error = 0
		select @num = 1
	else
		select @num = 0
end
GO
/****** Object:  StoredProcedure [System.Activities.DurableInstancing].[GetActivatableWorkflowsActivationParameters]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [System.Activities.DurableInstancing].[GetActivatableWorkflowsActivationParameters]
	@machineName nvarchar(128)
as
begin
	set nocount on
	set transaction isolation level read committed	
	set xact_abort on;	
	set deadlock_priority low
	
	declare @now datetime
	set @now = getutcdate()
	
	select 0 as 'Result'
	
	select top(1000) serviceDeployments.[SiteName], serviceDeployments.[RelativeApplicationPath], serviceDeployments.[RelativeServicePath]
	from (
		select distinct [ServiceDeploymentId], [WorkflowHostType]
		from [RunnableInstancesTable] with (readpast)
		where [RunnableTime] <= @now
		) runnableWorkflows inner join [ServiceDeploymentsTable] serviceDeployments
		on runnableWorkflows.[ServiceDeploymentId] = serviceDeployments.[Id]
	where not exists (
						select top (1) 1
						from [LockOwnersTable] lockOwners
						where lockOwners.[LockExpiration] > @now
						and lockOwners.[MachineName] = @machineName
						and lockOwners.[WorkflowHostType] = runnableWorkflows.[WorkflowHostType]
					  )
end
GO
/****** Object:  StoredProcedure [System.Activities.DurableInstancing].[FreeKeys]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [System.Activities.DurableInstancing].[FreeKeys]
	@surrogateInstanceId bigint,
	@keysToFree xml = null
as
begin	
	set nocount on
	set transaction isolation level read committed
	set xact_abort on;	
	
	declare @badKeyId uniqueidentifier
	declare @numberOfKeys int
	declare @result int
	declare @keyIds table([KeyId] uniqueidentifier)
	
	set @result = 0
	
	if (@keysToFree is not null)
	begin
		insert into @keyIds
		select T.Item.value('@KeyId', 'uniqueidentifier')
		from @keysToFree.nodes('//CorrelationKey') as T(Item)
		option(maxdop 1)
		
		select @numberOfKeys = count(1) from @keyIds
		
		delete [KeysTable]
		from @keyIds as [KeyIds]
		join [KeysTable] on [KeyIds].[KeyId] = [KeysTable].[Id]
		where [SurrogateInstanceId] = @surrogateInstanceId

		if (@@rowcount != @numberOfKeys)
		begin
			select top 1 @badKeyId = [MissingKeys].[MissingKeyId] from
				(select [KeyIds].[KeyId] as [MissingKeyId]
				 from @keyIds as [KeyIds]
				 except
				 select [Id] from [KeysTable] where [SurrogateInstanceId] = @surrogateInstanceId) as MissingKeys
		
			select 4 as 'Result', @badKeyId
			return 4
		end
	end
end
GO
/****** Object:  StoredProcedure [System.Activities.DurableInstancing].[ExtendLock]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [System.Activities.DurableInstancing].[ExtendLock]
	@surrogateLockOwnerId bigint,
	@lockTimeout int	
as
begin
	set nocount on
	set transaction isolation level read committed
	set xact_abort on;	
	
	begin transaction	
	
	declare @now datetime
	declare @newLockExpiration datetime
	declare @result int
	
	set @now = getutcdate()
	set @result = 0
	
	if (@lockTimeout = 0)
		set @newLockExpiration = '9999-12-31T23:59:59'
	else
		set @newLockExpiration = dateadd(second, @lockTimeout, @now)
	
	update [LockOwnersTable]
	set [LockExpiration] = @newLockExpiration
	where ([SurrogateLockOwnerId] = @surrogateLockOwnerId) and
		  ([LockExpiration] > @now)
	
	if (@@rowcount = 0) 
	begin
		if exists (select * from [LockOwnersTable] where ([SurrogateLockOwnerId] = @surrogateLockOwnerId))
		begin
			exec [System.Activities.DurableInstancing].[DeleteLockOwner] @surrogateLockOwnerId
			set @result = 11
		end
		else
			set @result = 12
	end
	
	select @result as 'Result'
	commit transaction
end
GO
/****** Object:  StoredProcedure [System.Activities.DurableInstancing].[LoadInstance]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [System.Activities.DurableInstancing].[LoadInstance]
	@surrogateLockOwnerId bigint,
	@operationType tinyint,
	@handleInstanceVersion bigint,
	@handleIsBoundToLock bit,
	@keyToLoadBy uniqueidentifier = null,
	@instanceId uniqueidentifier = null,
	@keysToAssociate xml = null,
	@encodingOption tinyint,
	@concatenatedKeyProperties varbinary(max) = null,
	@singleKeyId uniqueidentifier,
	@operationTimeout int
as
begin
	set nocount on
	set transaction isolation level read committed	
	set xact_abort on;		
	set deadlock_priority low
	begin transaction
	
	declare @result int
	declare @lockAcquired bigint
	declare @isInitialized bit
	declare @createKey bit
	declare @createdInstance bit
	declare @keyIsAssociated bit
	declare @loadedByKey bit
	declare @now datetime
	declare @surrogateInstanceId bigint

	set @createdInstance = 0
	set @isInitialized = 0
	set @keyIsAssociated = 0
	set @result = 0
	set @surrogateInstanceId = null
	
	exec @lockAcquired = sp_getapplock @Resource = 'InstanceStoreLock', @LockMode = 'Shared', @LockTimeout = @operationTimeout
	
	if (@lockAcquired < 0)
	begin
		set @result = 13
		select @result as 'Result'
	end
	
	if (@result = 0)
	begin
		set @now = getutcdate()

		if (@operationType = 0) or (@operationType = 2)
		begin
MapKeyToInstanceId:
			set @loadedByKey = 0
			set @createKey = 0
			
			select @surrogateInstanceId = [SurrogateInstanceId],
				   @keyIsAssociated = [IsAssociated]
			from [KeysTable]
			where [Id] = @keyToLoadBy
			
			if (@@rowcount = 0)
			begin
				if (@operationType = 2)
				begin
					set @result = 4
					select @result as 'Result', @keyToLoadBy 
				end
					set @createKey = 1
			end
			else if (@keyIsAssociated = 0)
			begin
				set @result = 8
				select @result as 'Result', @keyToLoadBy
			end
			else
			begin
				select @instanceId = [Id]
				from [InstancesTable]
				where [SurrogateInstanceId] = @surrogateInstanceId

				if (@@rowcount = 0)
					goto MapKeyToInstanceId

				set @loadedByKey = 1
			end
		end
	end

	if (@result = 0)
	begin
LockOrCreateInstance:
		exec [System.Activities.DurableInstancing].[LockInstance] @instanceId, @surrogateLockOwnerId, @handleInstanceVersion, @handleIsBoundToLock, @surrogateInstanceId output, null, @result output
														  
		if (@result = 0 and @surrogateInstanceId = 0)
		begin
			if (@loadedByKey = 1)
				goto MapKeyToInstanceId
			
			if (@operationType > 1)
			begin
				set @result = 1
				select @result as 'Result', @instanceId as 'InstanceId'
			end
			else
			begin				
				exec [System.Activities.DurableInstancing].[CreateInstance] @instanceId, @surrogateLockOwnerId, null, null, @surrogateInstanceId output, @result output
			
				if (@result = 0 and @surrogateInstanceId = 0)
					goto LockOrCreateInstance
				else if (@surrogateInstanceId > 0)
					set @createdInstance = 1
			end
		end
		else if (@result = 0)
		begin
			delete from [RunnableInstancesTable]
			where [SurrogateInstanceId] = @surrogateInstanceId
		end
	end
		
	if (@result = 0)
	begin
		if (@createKey = 1) 
		begin
			select @isInitialized = [IsInitialized]
			from [InstancesTable]
			where [SurrogateInstanceId] = @surrogateInstanceId
			
			if (@isInitialized = 1)
			begin
				set @result = 5
				select @result as 'Result', @instanceId
			end
			else
			begin													
				insert into [KeysTable] ([Id], [SurrogateInstanceId], [IsAssociated])
				values (@keyToLoadBy, @surrogateInstanceId, 1)
				
				if (@@rowcount = 0)
				begin
					if (@createdInstance = 1)
					begin
						delete [InstancesTable]
						where [SurrogateInstanceId] = @surrogateInstanceId
					end
					else
					begin
						update [InstancesTable]
						set [SurrogateLockOwnerId] = null
						where [SurrogateInstanceId] = @surrogateInstanceId
					end
					
					goto MapKeyToInstanceId
				end
			end
		end
		else if (@loadedByKey = 1 and not exists(select [Id] from [KeysTable] where ([Id] = @keyToLoadBy) and ([IsAssociated] = 1)))
		begin
			set @result = 8
			select @result as 'Result', @keyToLoadBy
		end
		
		if (@operationType > 1 and not exists(select [Id] from [InstancesTable] where ([Id] = @instanceId) and ([IsInitialized] = 1)))
		begin
			set @result = 1
			select @result as 'Result', @instanceId as 'InstanceId'
		end
		
		if (@result = 0)
			exec @result = [System.Activities.DurableInstancing].[AssociateKeys] @surrogateInstanceId, @keysToAssociate, @concatenatedKeyProperties, @encodingOption, @singleKeyId
		
		-- Ensure that this key's data will never be overwritten.
		if (@result = 0 and @createKey = 1)
		begin
			update [KeysTable]
			set [EncodingOption] = @encodingOption
			where [Id] = @keyToLoadBy
		end
	end
	
	if (@result != 13)
		exec sp_releaseapplock @Resource = 'InstanceStoreLock'
		
	if (@result = 0)
	begin
		select @result as 'Result',
			   [Id],
			   [SurrogateInstanceId],
			   [PrimitiveDataProperties],
			   [ComplexDataProperties],
			   [MetadataProperties],
			   [DataEncodingOption],
			   [MetadataEncodingOption],
			   [Version],
			   [IsInitialized],
			   @createdInstance
		from [InstancesTable]
		where [SurrogateInstanceId] = @surrogateInstanceId
		
		if (@createdInstance = 0)
		begin
			select @result as 'Result',
				   [EncodingOption],
				   [Change]
			from [InstanceMetadataChangesTable]
			where [SurrogateInstanceId] = @surrogateInstanceId
			order by([ChangeTime])
			
			if (@@rowcount = 0)
			select @result as 'Result', null, null
				
			select @result as 'Result',
				   [Id],
				   [IsAssociated],
				   [EncodingOption],
				   [Properties]
			from [KeysTable] with (index(NCIX_KeysTable_SurrogateInstanceId))
			where ([KeysTable].[SurrogateInstanceId] = @surrogateInstanceId)
			
			if (@@rowcount = 0)
				select @result as 'Result', null, null, null, null
		end

		commit transaction
	end
	else if (@result = 2 or @result = 14)
		commit transaction
	else
		rollback transaction
end
GO
/****** Object:  StoredProcedure [System.Activities.DurableInstancing].[SaveInstance]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [System.Activities.DurableInstancing].[SaveInstance]
	@instanceId uniqueidentifier,
	@surrogateLockOwnerId bigint,
	@handleInstanceVersion bigint,
	@handleIsBoundToLock bit,
	@primitiveDataProperties varbinary(max),
	@complexDataProperties varbinary(max),
	@writeOnlyPrimitiveDataProperties varbinary(max),
	@writeOnlyComplexDataProperties varbinary(max),
	@metadataProperties varbinary(max),
	@metadataIsConsistent bit,
	@encodingOption tinyint,
	@timerDurationMilliseconds bigint,
	@suspensionStateChange tinyint,
	@suspensionReason nvarchar(max),
	@suspensionExceptionName nvarchar(450),
	@keysToAssociate xml,
	@keysToComplete xml,
	@keysToFree xml,
	@concatenatedKeyProperties varbinary(max),
	@unlockInstance bit,
	@isReadyToRun bit,
	@isCompleted bit,
	@singleKeyId uniqueidentifier,
	@lastMachineRunOn nvarchar(450),
	@executionStatus nvarchar(450),
	@blockingBookmarks nvarchar(max),
	@workflowHostType uniqueidentifier,
	@serviceDeploymentId bigint,
	@operationTimeout int
as
begin
	set nocount on
	set transaction isolation level read committed		
	set xact_abort on;	

	declare @currentInstanceVersion bigint
	declare @deleteInstanceOnCompletion bit
	declare @enqueueCommand bit
	declare @isSuspended bit
	declare @lockAcquired bigint
	declare @metadataUpdateOnly bit
	declare @now datetime
	declare @result int
	declare @surrogateInstanceId bigint
	declare @pendingTimer datetime
	
	set @result = 0
	set @metadataUpdateOnly = 0
	
	exec @lockAcquired = sp_getapplock @Resource = 'InstanceStoreLock', @LockMode = 'Shared', @LockTimeout = @operationTimeout
		
	if (@lockAcquired < 0)
	begin
		select @result as 'Result'
		set @result = 13
	end
	
	set @now = getutcdate()
	
	if (@primitiveDataProperties is null and @complexDataProperties is null and @writeOnlyPrimitiveDataProperties is null and @writeOnlyComplexDataProperties is null)
		set @metadataUpdateOnly = 1

LockOrCreateInstance:
	if (@result = 0)
	begin
		exec [System.Activities.DurableInstancing].[LockInstance] @instanceId, @surrogateLockOwnerId, @handleInstanceVersion, @handleIsBoundToLock, @surrogateInstanceId output, @currentInstanceVersion output, @result output
															  
		if (@result = 0 and @surrogateInstanceId = 0)
		begin
			exec [System.Activities.DurableInstancing].[CreateInstance] @instanceId, @surrogateLockOwnerId, @workflowHostType, @serviceDeploymentId, @surrogateInstanceId output, @result output
			
			if (@result = 0 and @surrogateInstanceId = 0)
				goto LockOrCreateInstance
			
			set @currentInstanceVersion = 1
		end
	end
	
	if (@result = 0)
	begin
		select @enqueueCommand = [EnqueueCommand],
			   @deleteInstanceOnCompletion = [DeletesInstanceOnCompletion]
		from [LockOwnersTable]
		where ([SurrogateLockOwnerId] = @surrogateLockOwnerId)
		
		if (@isCompleted = 1 and @deleteInstanceOnCompletion = 1)
		begin
			exec [System.Activities.DurableInstancing].[DeleteInstance] @surrogateInstanceId
			goto Finally
		end
		
		update [InstancesTable] 
		set @instanceId = [InstancesTable].[Id],
			@workflowHostType = [WorkflowHostType] = 
					case when (@workflowHostType is null)
						then [WorkflowHostType]
						else @workflowHostType 
					end,
			@serviceDeploymentId = [ServiceDeploymentId] = 
					case when (@serviceDeploymentId is null)
						then [ServiceDeploymentId]
						else @serviceDeploymentId 
					end,
			@pendingTimer = [PendingTimer] = 
					case when (@metadataUpdateOnly = 1)
						then [PendingTimer]
						else [System.Activities.DurableInstancing].[GetExpirationTime](@timerDurationMilliseconds)
					end,
			@isReadyToRun = [IsReadyToRun] = 
					case when (@metadataUpdateOnly = 1)
						then [IsReadyToRun]
						else @isReadyToRun
					end,
			@isSuspended = [IsSuspended] = 
					case when (@suspensionStateChange = 0) then [IsSuspended]
						 when (@suspensionStateChange = 1) then 1
						 else 0
					end,
			[SurrogateLockOwnerId] = case when (@unlockInstance = 1 or @isCompleted = 1)
										then null
										else @surrogateLockOwnerId
									 end,
			[PrimitiveDataProperties] = case when (@metadataUpdateOnly = 1)
										then [PrimitiveDataProperties]
										else @primitiveDataProperties
									   end,
			[ComplexDataProperties] = case when (@metadataUpdateOnly = 1)
										then [ComplexDataProperties]
										else @complexDataProperties
									   end,
			[WriteOnlyPrimitiveDataProperties] = case when (@metadataUpdateOnly = 1)
										then [WriteOnlyPrimitiveDataProperties]
										else @writeOnlyPrimitiveDataProperties
									   end,
			[WriteOnlyComplexDataProperties] = case when (@metadataUpdateOnly = 1)
										then [WriteOnlyComplexDataProperties]
										else @writeOnlyComplexDataProperties
									   end,
			[MetadataProperties] = case
									 when (@metadataIsConsistent = 1) then @metadataProperties
									 else [MetadataProperties]
								   end,
			[SuspensionReason] = case
									when (@suspensionStateChange = 0) then [SuspensionReason]
									when (@suspensionStateChange = 1) then @suspensionReason
									else null
								 end,
			[SuspensionExceptionName] = case
									when (@suspensionStateChange = 0) then [SuspensionExceptionName]
									when (@suspensionStateChange = 1) then @suspensionExceptionName
									else null
								 end,
			[IsCompleted] = @isCompleted,
			[IsInitialized] = case
								when (@metadataUpdateOnly = 0) then 1
								else [IsInitialized]
							  end,
			[DataEncodingOption] = case
									when (@metadataUpdateOnly = 0) then @encodingOption
									else [DataEncodingOption]
								   end,
			[MetadataEncodingOption] = case
									when (@metadataIsConsistent = 1) then @encodingOption
									else [MetadataEncodingOption]
								   end,
			[BlockingBookmarks] = case
									when (@metadataUpdateOnly = 0) then @blockingBookmarks
									else [BlockingBookmarks]
								  end,
			[LastUpdated] = @now,
			[LastMachineRunOn] = case
									when (@metadataUpdateOnly = 0) then @lastMachineRunOn
									else [LastMachineRunOn]
								 end,
			[ExecutionStatus] = case
									when (@metadataUpdateOnly = 0) then @executionStatus
									else [ExecutionStatus]
								end
		from [InstancesTable]		
		where ([InstancesTable].[SurrogateInstanceId] = @surrogateInstanceId)
	
		if (@@rowcount = 0)
		begin
			set @result = 99
			select @result as 'Result' 
		end
		else
		begin
			if (@keysToAssociate is not null or @singleKeyId is not null)
				exec @result = [System.Activities.DurableInstancing].[AssociateKeys] @surrogateInstanceId, @keysToAssociate, @concatenatedKeyProperties, @encodingOption, @singleKeyId
			
			if (@result = 0 and @keysToComplete is not null)
				exec @result = [System.Activities.DurableInstancing].[CompleteKeys] @surrogateInstanceId, @keysToComplete
			
			if (@result = 0 and @keysToFree is not null)
				exec @result = [System.Activities.DurableInstancing].[FreeKeys] @surrogateInstanceId, @keysToFree
			
			if (@result = 0) and (@metadataUpdateOnly = 0)
			begin
				delete from [InstancePromotedPropertiesTable]
				where [SurrogateInstanceId] = @surrogateInstanceId
			end
			
			if (@result = 0)
			begin
				if (@metadataIsConsistent = 1)
				begin
					delete from [InstanceMetadataChangesTable]
					where [SurrogateInstanceId] = @surrogateInstanceId
				end
				else if (@metadataProperties is not null)
				begin
					insert into [InstanceMetadataChangesTable] ([SurrogateInstanceId], [EncodingOption], [Change])
					values (@surrogateInstanceId, @encodingOption, @metadataProperties)
				end
			end
			
			if (@result = 0 and @unlockInstance = 1 and @isCompleted = 0)
				exec [System.Activities.DurableInstancing].[InsertRunnableInstanceEntry] @surrogateInstanceId, @workflowHostType, @serviceDeploymentId, @isSuspended, @isReadyToRun, @pendingTimer				
		end
	end

Finally:
	if (@result != 13)
		exec sp_releaseapplock @Resource = 'InstanceStoreLock'
	
	if (@result = 0)
		select @result as 'Result', @currentInstanceVersion

	return @result
end
GO
/****** Object:  StoredProcedure [System.Activities.DurableInstancing].[UnlockInstance]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [System.Activities.DurableInstancing].[UnlockInstance]
	@surrogateLockOwnerId bigint,
	@instanceId uniqueidentifier,
	@handleInstanceVersion bigint
as
begin
	set nocount on
	set transaction isolation level read committed		
	set xact_abort on;	
	begin transaction
	
	declare @pendingTimer datetime
	declare @surrogateInstanceId bigint
	declare @workflowHostType uniqueidentifier
	declare @serviceDeploymentId bigint
	declare @enqueueCommand bit	
	declare @isReadyToRun bit	
	declare @isSuspended bit
	declare @now datetime
	
	set @now = getutcdate()
		
	update [InstancesTable]
	set [SurrogateLockOwnerId] = null,
	    @surrogateInstanceId = [SurrogateInstanceId],
	    @workflowHostType = [WorkflowHostType],
   	    @serviceDeploymentId = [ServiceDeploymentId],
	    @pendingTimer = [PendingTimer],
	    @isReadyToRun =  [IsReadyToRun],
	    @isSuspended = [IsSuspended]
	where [Id] = @instanceId and
		  [SurrogateLockOwnerId] = @surrogateLockOwnerId and
		  [Version] = @handleInstanceVersion
	
	exec [System.Activities.DurableInstancing].[InsertRunnableInstanceEntry] @surrogateInstanceId, @workflowHostType, @serviceDeploymentId, @isSuspended, @isReadyToRun, @pendingTimer    
	
	commit transaction
end
GO
/****** Object:  StoredProcedure [System.Activities.DurableInstancing].[TryLoadRunnableInstance]    Script Date: 05/13/2013 09:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [System.Activities.DurableInstancing].[TryLoadRunnableInstance]
	@surrogateLockOwnerId bigint,
	@workflowHostType uniqueidentifier,
	@operationType tinyint,
	@handleInstanceVersion bigint,
	@handleIsBoundToLock bit,
	@encodingOption tinyint,	
	@operationTimeout int
as
begin
	set nocount on
	set transaction isolation level read committed	
	set xact_abort on;	
	set deadlock_priority low
	begin tran
	
	declare @instanceId uniqueIdentifier
	declare @now datetime
	set @now = getutcdate()
	
	select top (1) @instanceId = instances.[Id]
	from [RunnableInstancesTable] runnableInstances with (readpast, updlock)
		inner loop join [InstancesTable] instances with (readpast, updlock)
		on runnableInstances.[SurrogateInstanceId] = instances.[SurrogateInstanceId]
	where runnableInstances.[WorkflowHostType] = @workflowHostType
		  and 
	      runnableInstances.[RunnableTime] <= @now
    
    if (@@rowcount = 1)
    begin
		select 0 as 'Result', cast(1 as bit)				
		exec [System.Activities.DurableInstancing].[LoadInstance] @surrogateLockOwnerId, @operationType, @handleInstanceVersion, @handleIsBoundToLock, null, @instanceId, null, @encodingOption, null, null, @operationTimeout
    end	
    else
    begin
		select 0 as 'Result', cast(0 as bit)
    end
    
    if (@@trancount > 0)
    begin
		commit tran
    end
end
GO
/****** Object:  Default [DF_WF_FLOW_Display]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [dbo].[Menu] ADD  CONSTRAINT [DF_WF_FLOW_Display]  DEFAULT ((0)) FOR [Display]
GO
/****** Object:  Default [DF__Need_Send__Email__654CE0F2]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [dbo].[Need_Send_Email] ADD  DEFAULT ((1)) FOR [EmailType]
GO
/****** Object:  Default [DF__Need_Send__IsSta__6641052B]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [dbo].[Need_Send_Email] ADD  DEFAULT ((0)) FOR [IsState]
GO
/****** Object:  Default [DF__Need_Send__Creat__67352964]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [dbo].[Need_Send_Email] ADD  DEFAULT (getdate()) FOR [CreateTime]
GO
/****** Object:  Default [DF__Users__IsState__29AC2CE0]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF__Users__IsState__29AC2CE0]  DEFAULT ((2)) FOR [IsState]
GO
/****** Object:  Default [DF_Users_CreateTime]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF_Users_CreateTime]  DEFAULT (getdate()) FOR [CreateTime]
GO
/****** Object:  Default [DF_Users_LastLogin]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF_Users_LastLogin]  DEFAULT (getdate()) FOR [LastLogin]
GO
/****** Object:  Default [DF__UsersBack__creat__396E5EB4]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [dbo].[UsersBackstageLog] ADD  CONSTRAINT [DF__UsersBack__creat__396E5EB4]  DEFAULT (getdate()) FOR [createtime]
GO
/****** Object:  Default [DF__UsersBack__isSta__3A6282ED]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [dbo].[UsersBackstageLog] ADD  CONSTRAINT [DF__UsersBack__isSta__3A6282ED]  DEFAULT ((1)) FOR [isState]
GO
/****** Object:  Default [DF_WorkFlow_State]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [dbo].[WorkFlow] ADD  CONSTRAINT [DF_WorkFlow_State]  DEFAULT ((1)) FOR [State]
GO
/****** Object:  Default [DF__Instances__Primi__12748D24]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[InstancesTable] ADD  DEFAULT (NULL) FOR [PrimitiveDataProperties]
GO
/****** Object:  Default [DF__Instances__Compl__1368B15D]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[InstancesTable] ADD  DEFAULT (NULL) FOR [ComplexDataProperties]
GO
/****** Object:  Default [DF__Instances__Write__145CD596]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[InstancesTable] ADD  DEFAULT (NULL) FOR [WriteOnlyPrimitiveDataProperties]
GO
/****** Object:  Default [DF__Instances__Write__1550F9CF]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[InstancesTable] ADD  DEFAULT (NULL) FOR [WriteOnlyComplexDataProperties]
GO
/****** Object:  Default [DF__Instances__Metad__16451E08]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[InstancesTable] ADD  DEFAULT (NULL) FOR [MetadataProperties]
GO
/****** Object:  Default [DF__Instances__DataE__17394241]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[InstancesTable] ADD  DEFAULT ((0)) FOR [DataEncodingOption]
GO
/****** Object:  Default [DF__Instances__Metad__182D667A]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[InstancesTable] ADD  DEFAULT ((0)) FOR [MetadataEncodingOption]
GO
/****** Object:  Default [DF__Instances__LastU__19218AB3]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[InstancesTable] ADD  DEFAULT (NULL) FOR [LastUpdated]
GO
/****** Object:  Default [DF__Instances__Suspe__1A15AEEC]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[InstancesTable] ADD  DEFAULT (NULL) FOR [SuspensionExceptionName]
GO
/****** Object:  Default [DF__Instances__Suspe__1B09D325]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[InstancesTable] ADD  DEFAULT (NULL) FOR [SuspensionReason]
GO
/****** Object:  Default [DF__Instances__Block__1BFDF75E]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[InstancesTable] ADD  DEFAULT (NULL) FOR [BlockingBookmarks]
GO
/****** Object:  Default [DF__Instances__LastM__1CF21B97]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[InstancesTable] ADD  DEFAULT (NULL) FOR [LastMachineRunOn]
GO
/****** Object:  Default [DF__Instances__Execu__1DE63FD0]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[InstancesTable] ADD  DEFAULT (NULL) FOR [ExecutionStatus]
GO
/****** Object:  Default [DF__Instances__IsIni__1EDA6409]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[InstancesTable] ADD  DEFAULT ((0)) FOR [IsInitialized]
GO
/****** Object:  Default [DF__Instances__IsSus__1FCE8842]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[InstancesTable] ADD  DEFAULT ((0)) FOR [IsSuspended]
GO
/****** Object:  Default [DF__Instances__IsRea__20C2AC7B]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[InstancesTable] ADD  DEFAULT ((0)) FOR [IsReadyToRun]
GO
/****** Object:  Default [DF__Instances__IsCom__21B6D0B4]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[InstancesTable] ADD  DEFAULT ((0)) FOR [IsCompleted]
GO
/****** Object:  Default [DF__LockOwner__Primi__25876198]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[LockOwnersTable] ADD  DEFAULT (NULL) FOR [PrimitiveLockOwnerData]
GO
/****** Object:  Default [DF__LockOwner__Compl__267B85D1]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[LockOwnersTable] ADD  DEFAULT (NULL) FOR [ComplexLockOwnerData]
GO
/****** Object:  Default [DF__LockOwner__Write__276FAA0A]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[LockOwnersTable] ADD  DEFAULT (NULL) FOR [WriteOnlyPrimitiveLockOwnerData]
GO
/****** Object:  Default [DF__LockOwner__Write__2863CE43]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[LockOwnersTable] ADD  DEFAULT (NULL) FOR [WriteOnlyComplexLockOwnerData]
GO
/****** Object:  Default [DF__LockOwner__Encod__2957F27C]    Script Date: 05/13/2013 09:42:17 ******/
ALTER TABLE [System.Activities.DurableInstancing].[LockOwnersTable] ADD  DEFAULT ((0)) FOR [EncodingOption]
GO
