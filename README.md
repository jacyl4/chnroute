电信移动 策略路由规则

IP 段由多个国内 IP／运营商列表合并生成，来源与分流口径见下文。

由 GitLab CI 自动构建；GitHub Actions 保留手动构建入口。

## 国内 IPv4 总表（IPchnroute）

GitLab CI（定时／手动）和 GitHub Actions（手动）均运行
`python3 -B scripts/update_ipchnroute.py`，合并以下来源：

- [APNIC 官方统计](https://ftp.apnic.net/stats/apnic/delegated-apnic-extended-latest)，
  以及项目原有的 IANA、LACNIC 镜像（相同数据的冗余下载入口）。
- [17mon/china_ip_list](https://github.com/17mon/china_ip_list)。
- [Clang ISP IP](https://ispip.clang.cn/) 的 `all_cn.txt` 和 `all_cn_apnic.txt`。
- [gaoyifan/china-operator-ip](https://github.com/gaoyifan/china-operator-ip) 的 `china.txt`。
- [misakaio/chnroutes2](https://github.com/misakaio/chnroutes2) 的 `chnroutes.txt`。
- [RIPEstat Country Resource List](https://stat.ripe.net/docs/data-api/api-endpoints/country-resource-list)
  的 CN IPv4 资源列表。

各来源分别下载并校验，跳过失败、空内容或格式异常的来源；将成功来源取并集，
去重并合并包含／相邻的 CIDR，按地址排序输出，同时生成 `IPchnroute.sha256sum`。
所有来源均失败时返回非零状态，保留现有文件，停止 CI 后续步骤。
单源失败时仍生成其余成功来源的并集，因此覆盖范围可能比上一次缩小。

多源并集优先保证覆盖，不保证地理／运营商归属绝对准确；登记数据与 BGP 数据的
统计口径不同。上游数据的使用与再分发需遵守各自许可。

本地回归测试：`python3 -B -m unittest discover -s tests -v`。

## 运营商出口分组

运行 `./scripts/ros-dpbr.sh`（兼容原 CI 入口），使用同一份分类结果生成三个文件：

| 文件 | CT 出口 | 另一个出口 |
| --- | --- | --- |
| `ros-dpbr-CT-CMCC.rsc` | 电信及未标注网段 | CMCC |
| `ros-dpbr-CT-CU.rsc` | 电信及未标注网段 | CU |
| `ros-pbr-CT-CMCC.rsc` | 电信及未标注网段 | CMCC |

**这里的 CMCC／CU 是出口名称，不表示组内所有 IP 都属于移动／联通。**
联通、移动、广电、教育网、鹏博士／长宽、科技网、谷歌中国等明确标注的非电信网段
均归另一个出口；没有明确运营商标注的国内网段归 CT，`othernet` 不作为明确归属。
因此相较旧脚本，教育网、长宽在 CT-CMCC 文件中改归另一个出口，CT-CU 中未标注部分改归 CT。

运营商来源与冲突处理（这是本项目的确定性策略，不代表来源准确度的绝对排名）：

1. 优先使用 [Clang](https://ispip.clang.cn/) 普通运营商列表（IPNetDB）。
2. 未被上述列表标注的部分，使用
   [gaoyifan/china-operator-ip](https://github.com/gaoyifan/china-operator-ip) 的 BGP 分类补充。
3. 仍未标注的部分，使用 Clang `_apnic` 运营商列表补充。
4. 同级来源按更具体的 CIDR 优先；同一 CIDR 同时标注电信与非电信时归 CT。
5. 仍无标注的部分归 CT。所有结果裁剪到 `IPchnroute`，不扩展到国外地址。

每次生成检查 CT 与另一组无交集，且并集完整覆盖 `IPchnroute`；三份文件使用相同网段分组。
若某运营商的所有来源均失败、分组为空或覆盖检查失败，返回非零状态，保留原规则文件。
`drpeng`、`googlecn` 是 gaoyifan 上游标为试验阶段的分类；在线归属数据可能有误，
上述校验保证的是输出规则的一致性、无重叠和覆盖性，不保证真实网络归属绝对准确。

策略路由分流有两种实现方法：

方法一：
**ros-pbr-CT-CMCC.rsc** 是往route - rules 里生ip段列表。

ros script 例子

```
:local addr "https://cdn.jsdelivr.net/gh/jacyl4/chnroute@main/ros-pbr-CT-CMCC.rsc"
:local result ([/tool fetch mode=https output=user url=$addr as-value])
:if ($result->"status" = "finished") do={
/file remove [find name="ros-pbr-CT-CMCC.rsc"]
/tool fetch url=$addr
/ip route rule remove [find table=main]
/ip route rule remove [find table=CT]
/ip route rule remove [find table=CMCC]
/ip route rule remove [find table=CT2]
/ip route rule remove [find table=CT3]
/ip route rule add src-address=10.0.0.14/32 action=lookup table=main
/ip route rule add src-address=10.0.101.2/32 action=lookup table=CT2
/ip route rule add src-address=10.0.102.2/32 action=lookup table=CT3
/ip route rule add src-address=10.0.2.2/32 action=lookup table=CMCC
/import ros-pbr-CT-CMCC.rsc
}
```

方法二：
**ros-dpbr-CT-CMCC.rsc** 是往Firewall - address lists 里生ip段列表。
```
:local addr "https://cdn.jsdelivr.net/gh/jacyl4/chnroute@main/ros-dpbr-CT-CMCC.rsc"
:local result ([/tool fetch mode=https output=user url=$addr as-value])
:if ($result->"status" = "finished") do={
/file remove [find name="ros-dpbr-CT-CMCC.rsc"]
/tool fetch url=$addr
/ip firewall address-list remove [find list="dpbr-CT"]
/ip firewall address-list remove [find list="dpbr-CMCC"]
/import ros-dpbr-CT-CMCC.rsc
}
```

这个可以用于Firewall - mangle页，通过dst-addrss= 引用
