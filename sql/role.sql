SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO
USE TeaShopCourse;
GO
IF DATABASE_PRINCIPAL_ID('tea_cashier') IS NULL CREATE ROLE tea_cashier;
IF DATABASE_PRINCIPAL_ID('tea_maker') IS NULL CREATE ROLE tea_maker;
IF DATABASE_PRINCIPAL_ID('tea_stock') IS NULL CREATE ROLE tea_stock;
IF DATABASE_PRINCIPAL_ID('tea_manager') IS NULL CREATE ROLE tea_manager;
GRANT SELECT ON dbo.v_Menu TO tea_cashier;
GRANT SELECT ON dbo.v_OrderSummary TO tea_cashier;
GRANT SELECT ON dbo.v_MakingQueue TO tea_maker;
GRANT SELECT ON dbo.v_StockAvailable TO tea_stock;
GRANT SELECT ON dbo.Ingredient TO tea_stock;
GRANT SELECT ON dbo.StockMovement TO tea_stock;
GRANT SELECT ON dbo.v_Menu TO tea_manager;
GRANT SELECT ON dbo.v_OrderSummary TO tea_manager;
GRANT SELECT ON dbo.v_DailySales TO tea_manager;
GRANT SELECT ON dbo.v_ProductSales TO tea_manager;
GRANT SELECT ON dbo.v_StockAvailable TO tea_manager;
GRANT INSERT, UPDATE ON dbo.Product TO tea_manager;
GRANT SELECT ON dbo.Product TO tea_manager;
GRANT SELECT, INSERT, UPDATE ON dbo.Coupon TO tea_manager;
-- Financial/stock/order writes span tables; no direct writes for operational roles.
-- Do not grant db_owner or db_datawriter to these roles.
IF DATABASE_PRINCIPAL_ID('demo_cashier') IS NULL CREATE USER demo_cashier WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID('demo_maker') IS NULL CREATE USER demo_maker WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID('demo_stock') IS NULL CREATE USER demo_stock WITHOUT LOGIN;
IF DATABASE_PRINCIPAL_ID('demo_manager') IS NULL CREATE USER demo_manager WITHOUT LOGIN;
ALTER ROLE tea_cashier ADD MEMBER demo_cashier;
ALTER ROLE tea_maker ADD MEMBER demo_maker;
ALTER ROLE tea_stock ADD MEMBER demo_stock;
ALTER ROLE tea_manager ADD MEMBER demo_manager;
GO


