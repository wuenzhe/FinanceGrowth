clear
import excel D:\统计建模大赛\macro.xlsx, sheet("Sheet1") firstrow
save D:\统计建模大赛\macro.dta, replace
cd D:\统计建模大赛\
use macro.dta, clear
//修改变量类型
encode province, gen(pro)
recast float year
drop province  //删除多余变量
//对变量顺序进行排序
order pro, before(year)
order year, after(pro)
asdoc xtset pro year  //设置面板数据
asdoc xtdes  //显示面板数据结构
asdoc xtsum index factor  //面板数据描述性统计
//对变量一阶差分处理
gen dindex = d.index
gen dfactor = d.factor
xtline index, overlay  //作图
xtline factor, overlay  //作图
//删除缺失值
egen m = rowmiss(_all)
drop if m > 0
xtline dindex, overlay
xtline dfactor, overlay
//面板单位根检验LLC、IPS方法
asdoc xtunitroot llc index, demean lags(bic 2)
asdoc xtunitroot ips index, demean lags(bic 2)
asdoc xtunitroot llc dindex, demean lags(bic 2)
asdoc xtunitroot ips dindex, demean lags(bic 2)
asdoc xtunitroot llc factor, demean lags(bic 2)
asdoc xtunitroot ips factor, demean lags(bic 2)
asdoc xtunitroot llc dfactor, demean lags(bic 2)
asdoc xtunitroot ips dfactor, demean lags(bic 2)
set matsize 11000  //设置最大矩阵数
asdoc pvar2 dindex dfactor, lag(4) soc  //确定最优滞后阶数
//脉冲响应函数，蒙特卡洛模拟，方差分解，格兰杰因果检验
asdoc pvar2 dindex dfactor, lag(2) irf(10) reps(2000) decomp(10) granger
save macro, replace