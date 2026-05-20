# 洗煤厂 KEPServer 点位导入说明

## 导入文件

- SQL：`deploy/sql/seed-coal-kepserver-tags.sql`
- 来源表：
  - `洗煤厂设备新.csv`
  - `洗煤厂模拟量信号1.csv`

## 导入范围

- 设备台账：283 个现场设备，写入 `asset_device`
- IoT 点位：1123 个点位，写入 `iot_tag`
- 业务映射：1123 条映射，写入 `iot_tag_mapping`

`source_path` 按来源文件分别保存：

```text
洗煤厂设备新.csv: NS2|String|洗煤厂PLC.洗煤厂设备新.<tagname>
洗煤厂模拟量信号1.csv: NS2|String|洗煤厂PLC.洗煤厂模拟量信号.<tagname>
```

例如：

```text
NS2|String|洗煤厂PLC.洗煤厂设备新.404.运行
NS2|String|洗煤厂PLC.洗煤厂模拟量信号.404电流
```

后端订阅时会自动转换为 OPC-UA `NodeId`，兼容以下三种写法：

- `NS2|String|洗煤厂PLC.洗煤厂模拟量信号.404电流`
- `ns=2;s=洗煤厂PLC.洗煤厂模拟量信号.404电流`
- `洗煤厂PLC.洗煤厂模拟量信号.404电流`

## 页面使用建议

| 点位类型 | 示例 | 建议页面/模块 |
| --- | --- | --- |
| 带电、挂牌、运行、漏电、过热、急停 | `404.运行`、`404.急停` | 设备管理、设备大屏、报警中心 |
| 电流、频率、温度、轴温 | `404电流`、`314轴伸端轴温度` | 设备管理、设备大屏、趋势分析、报警中心 |
| 流量、瞬时量、用水 | `生活用水流量1`、`121AWTA瞬时流量` | 生产总览、能耗管理、趋势分析 |
| 浓度、浊度、压力、液位、料位、开度 | `ND1X浓度1`、`分级旋流器压力` | 生产总览、工艺流程、质量管理、趋势分析 |
| 其他模拟量 | `生活水箱`、`消防水池1` | 系统设置、点位台账、趋势分析 |

## 404 循环水泵样例

导入后 `404` 设备会包含以下点位：

| tagCode | tagName | sourcePath |
| --- | --- | --- |
| `coal.kep.device.404.power_feedback` | `404.带电` | `NS2|String|洗煤厂PLC.洗煤厂设备新.404.带电` |
| `coal.kep.device.404.tag_count` | `404.挂牌` | `NS2|String|洗煤厂PLC.洗煤厂设备新.404.挂牌` |
| `coal.kep.device.404.running` | `404.运行` | `NS2|String|洗煤厂PLC.洗煤厂设备新.404.运行` |
| `coal.kep.device.404.current` | `404电流` | `NS2|String|洗煤厂PLC.洗煤厂模拟量信号.404电流` |

## 执行方式

确认后端已启动过一次并创建表结构后，在 PostgreSQL 执行：

```bash
psql -U coal_user -d coal_platform -f deploy/sql/seed-coal-kepserver-tags.sql
```

现场切换真实 KEPServer 时，环境变量至少设置：

```env
PLATFORM_IOT_PROVIDER=kepserver
PLATFORM_IOT_FALLBACK_TO_MOCK=false
PLATFORM_IOT_KEPSERVER_ENABLED=true
PLATFORM_IOT_KEPSERVER_ENDPOINT=opc.tcp://<KEPServer IP>:49320
PLATFORM_IOT_KEPSERVER_OPCUA_NAMESPACE_INDEX=2
```
