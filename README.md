# 茶序奶茶店数据库课程项目

单门店奶茶店，支持到店点单、自营线上商城、自提与外卖配送、会员优惠券和储值服务。经营场景贯穿17周，不随意更换。

## 当前版本

第一阶段v0.1：第1—4周数据库初建、CRUD、多表查询、视图、约束与权限。线上商城和配送在本阶段体现为数据库业务记录；网页、真实支付接口和骑手调度应用不属于本阶段交付。

## 提交入口

| 材料 | 文件 |
| --- | --- |
| 第一周：范围、角色、流程、数据边界 | [业务需求](docs/01-business.md) |
| 第二周：关系模式、域、键、样例 | [数据字典](docs/02-data-dictionary.md) |
| 阶段报告、实验说明和限制 | [阶段报告](docs/03-stage-report.md) |
| AI提示、输出、修改与验证记录 | [AI使用记录](docs/04-ai-record.md) |
| 2—3人组内分工 | [组内分工](docs/05-team.md) |
| 提交清单 | [提交说明](docs/06-submission.md) |
| 建库、样例、CRUD、查询、视图、约束、角色 | `sql/` |
| 实际验证输出 | `evidence/` |

## 环境与复现

- Microsoft SQL Server（建议2019或更新版本，支持SQL Server Express）。
- SSMS或sqlcmd；脚本使用T-SQL和GO，不适用于MySQL。
- 建库执行者需要建库权限；创建角色和无登录测试用户需要数据库管理权限。
- 全部姓名、联系方式、地址、支付编号均为虚构样例，无真实支付。

从项目根目录用PowerShell运行（实例名按实际环境修改）：

```powershell
sqlcmd -S '.\SQLEXPRESS' -E -C -b -f 65001 -i sql/00-create.sql
sqlcmd -S '.\SQLEXPRESS' -E -C -b -f 65001 -i sql/01-schema.sql
sqlcmd -S '.\SQLEXPRESS' -E -C -b -f 65001 -i sql/constraint.sql
sqlcmd -S '.\SQLEXPRESS' -E -C -b -f 65001 -i sql/02-seed.sql
sqlcmd -S '.\SQLEXPRESS' -E -C -b -f 65001 -i sql/view.sql
sqlcmd -S '.\SQLEXPRESS' -E -C -b -f 65001 -i sql/role.sql
sqlcmd -S '.\SQLEXPRESS' -E -C -b -f 65001 -i sql/crud.sql
sqlcmd -S '.\SQLEXPRESS' -E -C -b -f 65001 -i sql/services.sql
sqlcmd -S '.\SQLEXPRESS' -E -C -b -f 65001 -i sql/query.sql
sqlcmd -S '.\SQLEXPRESS' -E -C -b -f 65001 -i sql/test.sql
```

`00-create.sql`只创建不存在的TeaShopCourse数据库，不删除已有数据。结构和样例脚本面向空库；再次执行会主动失败或因重复对象/键而失败，不会清空现有数据库。重复验证可只执行crud.sql、query.sql、test.sql，其中写入演示均回滚。请勿对生产数据库使用本课程脚本。

完整业务链路：维护商品与配方→原料入库→会员充值/领券→线上或柜台下单→库存及券预留→支付→原料耗用→制作→自提或配送→完成→积分；取消退款释放预留或登记已耗用损失，按原支付渠道退款。
