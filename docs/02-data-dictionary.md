# 第二周：关系模式与数据字典

## 1. 设计约定

采用SQL Server。金额使用decimal(10,2)，原料数量使用decimal(12,3)，时间使用datetime2(0)并统一为门店当地时间。PK为主码，UK为唯一候选码，FK为外码；除标注“可空”的属性外均不可空。实验显式分配整数编号，后续应用再改为统一发号；不得直接用MAX+1处理并发。姓名和业务中文使用nvarchar，状态和业务编号使用varchar。布尔属性使用bit。

本版没有单独的“杯型表”：一种商品的一种杯型就是一个可售SKU，例如原味奶茶中杯和大杯分别编码。库存管理原料，杯具也视为原料。单位由原料定义，配方和库存沿用同一单位，不进行隐式单位转换。

## 2. 关系模式与属性域

### Product：商品

ProductID int（PK）；ProductCode varchar(20)（UK）；ProductName nvarchar(60)；CupSize nvarchar(10)；Price decimal(10,2)（>0）；IsActive bit（默认1）。商品编码唯一，名称不是候选码，因为不同杯型可同名。

### Ingredient：原料

IngredientID int（PK）；IngredientName nvarchar(60)（UK，单店统一命名）；Unit nvarchar(10)。示例单位为毫升、套。

### Recipe：标准配方

ProductID int（PK组成、FK→Product）；IngredientID int（PK组成、FK→Ingredient）；Quantity decimal(12,3)（>0，每杯标准用量）。联合主码为(ProductID, IngredientID)，同一配方不能重复出现同一种原料。

### Stock：库存

IngredientID int（PK、FK→Ingredient）；OnHand decimal(12,3)（现存量）；Reserved decimal(12,3)（预留量，默认0）。要求0≤Reserved≤OnHand。可用量为OnHand−Reserved，通过视图提供。

### Employee：员工

EmployeeID int（PK）；EmployeeCode varchar(20)（UK）；EmployeeName nvarchar(40)；Job varchar(20)（MANAGER/CASHIER/MAKER/STOCK/RIDER）；IsActive bit（默认1）。Job记录主要职务，SQL角色控制实际数据库授权，两者不自动联动。

### Member：会员

MemberID int（PK）；MemberCode varchar(20)（UK）；DisplayName nvarchar(40)；Phone varchar(20)（UK，本版每个联系方式对应一个会员）；Balance decimal(10,2)（≥0，默认0）；Points int（≥0，默认0）。样例电话使用TEST-PHONE标识，不是实际手机号。

### Coupon：券活动

CouponID int（PK）；CouponName nvarchar(60)；MinimumAmount decimal(10,2)；DiscountAmount decimal(10,2)；StartsAt、ExpiresAt datetime2(0)。要求最低金额≥优惠金额>0、开始时间<结束时间。有效时间采用左闭右开区间。不同活动可同名，所以名称不是候选码。

### MemberCoupon：会员领券

MemberCouponID int（PK）；MemberID int（FK→Member）；CouponID int（FK→Coupon）；Status varchar(12)（AVAILABLE/RESERVED/USED/EXPIRED）。候选码(MemberID, CouponID)表示本版每个活动每人一张；另有(MemberCouponID, MemberID)唯一约束用于订单校验归属，该组合是超码而非最小候选码。

### SalesOrder：订单

OrderID int（PK）；OrderNo varchar(30)（UK）；MemberID int（可空，FK→Member）；EmployeeID int（可空，FK→Employee）；Channel varchar(10)（ONLINE/COUNTER）；Fulfillment varchar(10)（PICKUP/DELIVERY）；Status varchar(16)；CreatedAt datetime2(0)（默认当前时间）；CompletedAt datetime2(0)（可空）；GoodsAmount、DiscountAmount、DeliveryFee decimal(10,2)；Payable为持久化计算属性；MemberCouponID int（可空）。

状态域：PENDING、PAID、MAKING、READY、DELIVERING、COMPLETED、CANCELLED、REFUNDED。商品总额>0，0≤优惠≤商品总额，配送费≥0；Payable=商品总额−优惠+配送费。自提配送费为0；线上订单必须关联会员。完成订单必须有完成时间。

联合FK(MemberCouponID, MemberID)→MemberCoupon，防止使用他人的券。有效订单中的MemberCouponID有过滤唯一索引，取消和退款订单不占用券。订单通过唯一OrderNo识别，会员编号不是订单候选码。

### OrderItem：订单明细

OrderID int（PK组成、FK→SalesOrder）；LineNumber int（PK组成，>0）；ProductID int（FK→Product）；ProductName nvarchar(60)、CupSize nvarchar(10)（历史快照）；Quantity int（>0）；UnitPrice decimal(10,2)（>0）；Sugar nvarchar(10)（无糖/三分糖/半糖/全糖）；Temperature nvarchar(10)（热/常温/少冰/正常冰）；LineAmount为Quantity×UnitPrice计算属性。

联合主码(OrderID, LineNumber)允许同一商品因糖度不同在订单中出现多行；不能用(OrderID, ProductID)作为候选码。

### Payment：支付及退款

PaymentID int（PK）；OrderID int（FK→SalesOrder）；Kind varchar(10)（PAY/REFUND）；Channel varchar(10)（CASH/EXTERNAL/BALANCE）；Amount decimal(10,2)（≥0，允许券后0元订单）；Status varchar(10)（PENDING/SUCCESS/FAILED）；ReferenceNo varchar(60)（UK，实验业务参考号）；OriginalPaymentID int（可空，FK→Payment）；CreatedAt datetime2(0)（默认当前时间）。

退款必须关联不同于自身的原支付，普通支付不填原支付。过滤唯一索引保证每单最多一笔成功支付和一笔成功退款；这与整单退款、单渠道规则对应。原支付是否同单同渠道、退款是否等于原实付属于跨行规则，尚非CHECK自动保证。

### WalletLedger：储值流水

WalletID int（PK）；MemberID int（FK→Member）；Kind varchar(10)（RECHARGE/SPEND/REFUND）；Delta decimal(10,2)；OrderID int（可空，FK→SalesOrder）；ReferenceNo varchar(60)（UK）；CreatedAt datetime2(0)。充值为正且不关联销售订单；消费为负、退款为正且必须关联订单。充值本身不作为奶茶销售额。

### PointLedger：积分流水

PointID int（PK）；MemberID int（FK→Member）；OrderID int（FK→SalesOrder）；Kind varchar(10)（EARN/REVERSE）；Delta int（发放为正、冲正为负）。候选码(OrderID, Kind)限制每单每类变动一次；0积分订单不生成积分行。

### Delivery：配送

OrderID int（PK、FK→SalesOrder，每单最多一条）；Recipient nvarchar(40)；Phone varchar(20)；Address nvarchar(200)；RiderID int（可空，FK→Employee）；Status varchar(12)（WAITING/ASSIGNED/IN_TRANSIT/DELIVERED/FAILED）；PickedAt、DeliveredAt datetime2(0)（可空）；ExceptionNote nvarchar(200)（可空）。已指派及配送阶段必须有骑手；送达必须有取餐和送达时间，送达不得早于取餐。骑手必须属于RIDER职务、配送单必须属于DELIVERY订单，后续由业务服务进一步保证。

### StockMovement：库存流水

MovementID int（PK）；IngredientID int（FK→Ingredient）；Kind varchar(12)（INBOUND/RETURN/SALE/LOSS/ADJUST）；Delta decimal(12,3)；OrderID int（可空，FK→SalesOrder）；EmployeeID int（FK→Employee）；Note nvarchar(200)；CreatedAt datetime2(0)。入库和退回为正，销售和损耗为负，盘点调整非0。销售耗用与退款报损不能重复扣同一份原料。

## 3. 主要关联

- 一个会员有多笔订单、领券记录、资金流水和积分流水。
- 一个订单有多条明细、多次支付尝试，最多一条配送记录。
- 商品和原料通过配方形成多对多关系；一种原料有一条汇总库存和多条库存流水。
- 员工可经办多笔订单与库存操作，骑手可承接多笔配送。
- 所有FK默认不级联删除；已有销售引用的商品不能直接删除，应下架。会员资金和已完成订单不作演示性的物理删除。

## 4. 样例元组与预期结果

`sql/02-seed.sql`提供全部15张表的可执行虚构样例。课程要求理解真实经营含义，不使用真实个人隐私。

| 对象 | 样例 | 含义 |
| --- | --- | --- |
| 商品 | (1, TEA-M, 原味奶茶, 中杯, 12.00) | 一个可售规格 |
| 配方 | (1, 茶汤, 200毫升) | 每杯标准耗用 |
| 库存 | 茶汤8950、牛奶9350、杯具995，预留均0 | 从入库扣除5杯饮品用料后的余额 |
| 会员甲 | 充值100，消费12，余额88，积分33 | 余额和积分均有流水依据 |
| 订单DEMO-001 | 线上配送，2杯×12−3券+3配送=24 | 完成且由外部渠道支付 |
| 订单DEMO-002 | 非会员柜台自提，大杯16 | 验证会员关联可空 |
| 订单DEMO-003 | 会员乙线上自提，鲜奶茶18 | 会员也可不用券和余额 |
| 订单DEMO-004 | 会员甲柜台自提，中杯12，余额支付 | 验证储值消费 |

合计4单5杯，商品原额70、优惠3、配送费3，订单实收70。充值100不再叠加到销售额。原味奶茶中杯3杯，大杯1杯，鲜奶茶1杯。
