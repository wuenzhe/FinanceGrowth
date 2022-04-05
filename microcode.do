clear
cd D:\统计建模大赛\CFPS\2018
use cfps2018famecon_202101.dta, clear
keep fincome1 fm1 ft501 ft6 ft601 ft602 fid18 resp1pid provcd18 countyid18 cid18 urban18 familysize18
sum
label list ft901 fm1 ft501 ft6 ft601 ft602 fid18 resp1pid provcd18 countyid18 cid18 urban18
for var _all: replace X =. if inlist(X, -10, -9, -8, -2, -1)  //替换无法识别的变量
recode fm1 (1 = 1 "是")(5 = 0 "否"), gen(enterp)  //对变量重新进行编码
for var ft501 ft601 ft602: replace X =0 if inlist(X, .)  //替换无法识别的变量
drop fm1
gen credit = ft501 + ft601 + ft602  //生成贷款规模变量
drop ft501 ft6 ft601 ft602
save temp1, replace
clear
use cfps2018person_202012.dta, clear
keep age qa002 cfps2018eduy_im qea0 qn4001 qp201 qu201 qu202 qu1m fid18 pid provcd18 countyid18 cid18 urban18
sum
label list age qa002 cfps2018eduy_im qea0 qn4001 qp201 qu201 qu202 qu1m  fid18 pid provcd18 countyid18 cid18 urban18
for var _all: replace X =. if inlist(X, -10, -9, -8, -2, -1)
recode qa002 (1 = 1 "男")(5 = 0 "女"), gen(sex)  //对变量重新进行编码
recode qea0 (2 3 = 1 "有配偶")(1 4 5 = 0 "无配偶"), gen(spouse)  //对变量重新进行编码
//recode w01 (1  10 = 0 "文盲/半文盲")(3 = 1 "小学")(4 = 2 "初中")(5 = 3 "高中")(6 = 4 "大专")(7 = 5 "大学本科")(8 = 6 "硕士")(9 = 7 "博士"), gen(edu)
rename cfps2018eduy_im edu  //修改学历变量名
drop qa002 qea0
save temp2, replace
clear
use temp1
rename resp1pid pid  //修改户主变量名
merge 1:1 fid18 pid using temp2
keep if _merge == 3
drop _merge
rename (provcd18 countyid18 cid18 urban18 familysize18)(provcd countyid cid urban familysize)  //修改省份，区县，村居，城乡，家庭规模变量名
rename (qu1m qn4001 qp201 fincome1) (phone policy health fincome)  //修改手机、政治面貌、健康程度、家庭收入变量名
gen internet = qu201 + qu202  //生成互联网变量名
replace internet = 1 if internet == 2
drop qu201 qu202
gen year = 2018  //生成年份
order year
rename fid18 fid  //修改家庭编号变量名
rename provcd code
save final, replace
clear

import excel D:\统计建模大赛\micro2018.xlsx, sheet("Sheet1") firstrow
save D:\统计建模大赛\micro2018.dta, replace
cd D:\统计建模大赛\
use micro2018.dta, clear
recast float year
cd D:\统计建模大赛\CFPS\2018
merge 1:m year code using final
keep if _merge == 3
encode province, gen(pro)
drop _merge province
order pro year
cd D:\统计建模大赛\
save micro2018.dta, replace
clear

use micro2018
*****删除缺失值*****
egen m = rowmiss(_all)
drop if m > 0
gen lnfincome = log(fincome)  //对收入进行对数化处理
gen above = 0
su above
egen median_lnfincome = median(lnfincome)
su median_lnfincome
replace above = 1 if lnfincome >= median_lnfincome
tab above  //对收入进行中位数处理
gen up = 0
su up
replace up = 1 if edu > 6
tab up  //对教育进行分类处理

*****描述性统计*****
asdoc summarize fincome index enterp urban familysize age sex health spouse edu credit phone internet
asdoc summarize fincome index enterp urban familysize age sex health spouse edu credit phone internet if urban == 0
asdoc summarize fincome index enterp urban familysize age sex health spouse edu credit phone internet if urban == 1
asdoc summarize fincome index enterp urban familysize age sex health spouse edu credit phone internet if above == 0
asdoc summarize fincome index enterp urban familysize age sex health spouse edu credit phone internet if above == 1
asdoc summarize fincome index enterp urban familysize age sex health spouse edu credit phone internet if above == 0 & urban == 0
asdoc summarize fincome index enterp urban familysize age sex health spouse edu credit phone internet if above == 1 & urban == 0

*****对收入与数字金融指数进行回归*****
reg lnfincome index
outreg2 using result1.doc,append bdec(3) ctitle(1)
reg lnfincome index urban familysize age sex health spouse edu credit phone internet
outreg2 using result1.doc,append bdec(3) ctitle(1)
*****异质性检验*****
*****对收入与数字金融指数进行回归（城乡分组）*****
reg lnfincome index familysize age sex health spouse edu credit phone internet if urban == 0
outreg2 using result3.doc,append bdec(3) ctitle(1)
reg lnfincome index familysize age sex health spouse edu credit phone internet if urban == 1
outreg2 using result3.doc,append bdec(3) ctitle(1)
asdoc bdiff, group(urban) model(reg lnfincome index familysize age sex health spouse edu credit phone internet) reps(100) bsample  //对分组回归的系数进行显著性检验
outreg2 using result7.doc,append bdec(3) ctitle(1)
*****对收入与数字金融指数进行回归（性别分组）*****
reg lnfincome index urban familysize age health spouse edu credit phone internet if sex == 0
outreg2 using result3.doc,append bdec(3) ctitle(1)
reg lnfincome index urban familysize age health spouse edu credit phone internet if sex == 1
outreg2 using result3.doc,append bdec(3) ctitle(1)
asdoc bdiff, group(sex) model(reg lnfincome index urban familysize age health spouse edu credit phone internet) reps(100) bsample  //对分组回归的系数进行显著性检验
outreg2 using result7.doc,append bdec(3) ctitle(1)
*****对收入与数字金融指数进行回归（乡村收入分组）*****
reg lnfincome index familysize age sex health spouse edu credit phone internet if above == 0 & urban == 0
outreg2 using result3.doc,append bdec(3) ctitle(1)
reg lnfincome index familysize age sex health spouse edu credit phone internet if above == 1 & urban == 0
outreg2 using result3.doc,append bdec(3) ctitle(1)
asdoc bdiff, group(above) model(reg lnfincome index familysize age sex health spouse edu credit phone internet) reps(100) bsample  //对分组回归的系数进行显著性检验
outreg2 using result7.doc,append bdec(3) ctitle(1)

*****对是否创业与数字金融指数进行probit回归*****
probit enterp index
outreg2 using result4.doc,append bdec(3) ctitle(1)
probit enterp index urban familysize age sex health spouse edu credit phone internet
outreg2 using result4.doc,append bdec(3) ctitle(1)
*****异质性检验*****
*****对是否创业与数字金融指数进行probit回归（城乡分组）*****
probit enterp index familysize age sex health spouse edu credit phone internet if urban == 0
outreg2 using result5.doc,append bdec(3) ctitle(1)
probit enterp index familysize age sex health spouse edu credit phone internet if urban == 1
outreg2 using result5.doc,append bdec(3) ctitle(1)
asdoc bdiff, group(urban) model(probit enterp index familysize age sex health spouse edu credit phone internet) reps(100) bsample  //对分组回归的系数进行显著性检验
outreg2 using result8.doc,append bdec(3) ctitle(1)
*****对是否创业与数字金融指数进行probit回归（收入分组）*****
probit enterp index familysize age sex health spouse edu credit phone internet if above == 0 & urban == 0
outreg2 using result6.doc,append bdec(3) ctitle(1)
probit enterp index familysize age sex health spouse edu credit phone internet if above == 1 & urban == 0
outreg2 using result6.doc,append bdec(3) ctitle(1)
asdoc bdiff, group(above) model(probit enterp index urban familysize age sex health spouse edu credit phone internet) reps(100) bsample  //对分组回归的系数进行显著性检验
outreg2 using result8.doc,append bdec(3) ctitle(1)
*****对是否创业与数字金融指数进行probit回归（学历分组）*****
probit enterp index urban familysize age sex health spouse credit phone internet if up == 0
outreg2 using result5.doc,append bdec(3) ctitle(1)
probit enterp index urban familysize age sex health spouse credit phone internet if up == 1
outreg2 using result5.doc,append bdec(3) ctitle(1)
asdoc bdiff, group(up) model(probit enterp index urban familysize age sex health spouse credit phone internet) reps(100) bsample  //对分组回归的系数进行显著性检验
outreg2 using result8.doc,append bdec(3) ctitle(1)
save micro2018, replace

*****稳健性检验*****
*****缩尾处理*****
winsor2 lnfincome index, replace cut (1, 99) trim
reg lnfincome index urban familysize age sex health spouse edu credit phone internet
outreg2 using result2.doc,append bdec(3) ctitle(1)
*****替换核心解释变量*****
reg lnfincome nets urban familysize age sex health spouse edu credit phone internet
outreg2 using result2.doc,append bdec(3) ctitle(1)
*****删除四个直辖市样本*****
drop if code == 11
drop if code == 12
drop if code == 31
drop if code == 50
reg lnfincome index urban familysize age sex health spouse edu credit phone internet
outreg2 using result2.doc,append bdec(3) ctitle(1)