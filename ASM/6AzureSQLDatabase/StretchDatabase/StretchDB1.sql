--Run some queries against the tables to be migrated and record the performance
USE AdventureWorks2016CTP3
GO

SELECT ot.SalesOrderID, ot.CarrierTrackingNumber, ot.OrderTrackingID, ot.TrackingEventID, te.EventName, ot.EventDetails, ot.EventDateTime
FROM Sales.OrderTracking ot JOIN Sales.TrackingEvent te ON ot.TrackingEventID = te.TrackingEventID
ORDER BY ot.SalesOrderID, ot.TrackingEventID;

--对本地SQL Server 2016，打开归档功能
EXEC sp_configure 'remote data archive' , '1';
RECONFIGURE;


--对云端Azure SQL Database的用户名和密码，进行加密，加密的密码同SQL Database的密码：
USE Adventureworks2016CTP3;
CREATE MASTER KEY ENCRYPTION BY PASSWORD='Abc@123456'
CREATE DATABASE SCOPED CREDENTIAL AzureDBCred WITH IDENTITY = 'sqladmin', SECRET = 'Abc@123456';


--将本地的SQL Server 2016的归档目标，指向到微软云SQL Database Server(l3cq1dckpd.database.chinacloudapi.cn)
--这个l3cq1dckpd.database.chinacloudapi.cn，是我们在准备工作中，创建的新的服务器
ALTER DATABASE [AdventureWorks2016CTP3] SET REMOTE_DATA_ARCHIVE = ON 
(SERVER = 'l3cq1dckpd.database.chinacloudapi.cn', CREDENTIAL = AzureDBCred);


--	Migrate an entire table, Specify MIGRATION_STATE = OUTBOUND to start data migration immediately 
ALTER TABLE Sales.OrderTracking SET (REMOTE_DATA_ARCHIVE = ON (MIGRATION_STATE = OUTBOUND));

--查看归档数据迁移的进度
SELECT * from sys.dm_db_rda_migration_status

-----------------------------------------------------------------------------------------------------
USE AdventureWorks2016CTP3
GO
--显示本地数据行和数据容量
EXEC sp_spaceused 'Sales.OrderTracking', 'true', 'LOCAL_ONLY';
GO

--显示云端Stretch Database的数据行和数据量
EXEC sp_spaceused 'Sales.OrderTracking', 'true', 'REMOTE_ONLY';
GO


---插入测试表
INSERT INTO [Sales].[OrderTracking]
([SalesOrderID],[CarrierTrackingNumber],[TrackingEventID],[EventDetails],[EventDateTime])
VALUES('6666','046DFAA-F901-442A-9D09-67',1,'This Data is generated by Lei Zhang',GetDate())


--检查插入结果
SELECT * FROM [Sales].[OrderTracking] WHERE [SalesOrderID]='6666'


--这句话会报错
UPDATE [Sales].[OrderTracking] SET [CarrierTrackingNumber]='6666' WHERE [EventDetails]='This Data is generated by Lei Zhang'

-----------------------------------------------------------------------------------------------------

--Disable Stretch Database and bring back remote data
ALTER TABLE Sales.OrderTracking SET (REMOTE_DATA_ARCHIVE (MIGRATION_STATE = INBOUND));


--Run the same queries during the migration and record the performance
SELECT ot.SalesOrderID, ot.CarrierTrackingNumber, ot.OrderTrackingID, ot.TrackingEventID, te.EventName, ot.EventDetails, ot.EventDateTime
FROM Sales.OrderTracking ot JOIN Sales.TrackingEvent te ON ot.TrackingEventID = te.TrackingEventID
ORDER BY ot.SalesOrderID, ot.TrackingEventID;