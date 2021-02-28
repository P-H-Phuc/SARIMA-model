<style>
.section .reveal .state-background {
  background: #00688B;
} 
.section .reveal h1, h2 {
    color: white; text-align: center;
    font-weight: bold; font-size: 62px;
    font-family: Times New Roman;
}
.reveal h3 {
  font-weight: bold; text-align: center;
  font-family: Times New Roman; font-size: 36px;
  color: darkred;
}
.reveal .slides section .slideContent {
   font-size: 32px;
   color: black;
}
.anhnen .reveal .state-background {
   background-color: #00688B;
}
.small-code pre code {
  font-size: 1.2em;
  font-weight: bold;
}

div.hideme + pre {display: none;
}

#title {
  text-align: center; 
  font-weight: bold;
}
</style>

PHƯƠNG PHÁP DỰ BÁO BẰNG SARIMA
========================================================
font-family: Times New Roman
width: 1440

<script>
doclick = function(e){
code = e.parentNode.nextSibling.nextSibling.nextSibling.nextSibling
if(code.style.display=="block"){
 code.style.display='none';
 e.textContent="Show Code"
} else {
 code.style.display="block";
 e.textContent="Hide Code"
}
}
</script>

<p style  = "font-size: 42px; text-decoration: underline; font-family: Times New Roman; text-align: center; font-weight: bold;"> 
    Nhóm 9 </p>

<p style = "font-size: 36px; text-align: center;"> 1. Phan Hồng Phúc&emsp;&nbsp; K184131497 </p>

<p style = "font-size: 36px; text-align: center;"> 2. Lê Thị Kim Thuý&emsp;&nbsp; K184131504 </p>  

<p style = "font-size: 36px; text-align: center;"> 3. Nguyễn Thanh Trang &emsp; K184131506 </p>

Giới thiệu mô hình SARIMA
========================================================

Mô hình SARIMA là mô hình ARIMA nhưng được điều chỉnh được áp dụng cho những chuỗi thời gian có yếu tố mùa vụ:  
<p id = "title"> SARIMA(p, d, q) (P, D, Q)m </p>
Trong đó:
  - p, q lần lượt là bậc của quá trình tự hồi quy AR và trung bình trượt MA của chuỗi dữ liệu
  - d là bậc sai phân mà tại đó chuỗi là chuỗi dừng
  - P, Q lần lượt là bậc của quá trình tự hồi quy AR và trung bình trượt MA của chuỗi mùa vụ
  - D là bậc sai phân mà tại đó chuỗi mùa vụ là chuỗi dừng
  - m là số giai đoạn trong một chu kỳ

Nội dung
========================================================
<button class="hidecode" onclick="doclick(this);"> Show Code </button>
<div class="hideme"></div>  

```r
library(readxl)
library(tidyverse)
library(forecast)
library(tseries)
library(seastests)
library(lubridate)
library(lmtest)
library(knitr)
```
  - Tổng quan về dữ liệu nghiên cứu (thống kê mô tả, vẽ đồ thị, chia tách dữ liệu,...) 
  - Xây dựng mô hình SARIMA:
    - Kiểm tra tính dừng của chuỗi dữ liệu và chuỗi mùa vụ bằng kiểm định ADF
    - Lựa chọn các tham số cho mô hình
    - Ước lượng mô hình SARIMA từ các tham số tìm được, `auto.arima()` để tìm mô hình tốt nhất
    - Kiểm tra chuỗi phần dư
    - Dự báo và kiểm tra kết quả cho dữ liệu ngoài mẫu
  - Kết luận
  - Tải dữ liệu [tại đây](https://github.com/P-H-Phuc/Phantichdulieu/raw/main/VietnamGas.xlsx)

  
Dữ liệu giá trị xuất khẩu xăng, dầu hoả của Việt Nam 2010 - 2020
========================================================
class: small-code
type: prompt

<button class="hidecode" onclick="doclick(this);"> Show Code </button>
<div class="hideme"></div>


```r
# Read file
export <- readxl::read_xlsx('VietnamGas.xlsx', sheet = 'data')
export$time <- as.Date(export$time)
max = filter(export, value == max(value))
min = filter(export, value == min(value))
ggplot() +
  geom_line(data = export, aes(x = time, y = value), size = 1) +
  geom_smooth(data = export, aes(x = time, y = value), method = "lm", se = FALSE, size = 2) + 
  geom_point(data = max, 
             aes(x = time, y = value), color = "red", size = 7) +
  geom_point(data = min,
             aes(x = time, y = value), color = "red", size = 7) +
  geom_hline(yintercept = mean(export$value), size = 1, color = "red") +
  scale_x_date(date_breaks = "1 years", date_labels = "%Y") + 
  annotate('text', x = as.Date("2013-03-31", "%Y-%m-%d"), y = 230, label = paste0(" Time: ", max$time, "\nValue max: $", max$value, "M"), size = 6) +
  annotate('text', x = as.Date("2019-05-31", "%Y-%m-%d"), y = 40, label = paste0(" Time: ", min$time, "\nValue min: $", min$value, "M"), size = 6) + 
  annotate("text", x = as.Date("2020-08-31", "%Y-%m-%d"), y = 110, label = "bold(mean)", size = 6, parse = TRUE) +
  annotate("text", x = as.Date("2020-08-31", "%Y-%m-%d"), y = 100, label = round(mean(export$value), 3), size = 5) +
  labs(x = '', y = "Million USD") +
  theme_minimal()
```

<img src="Sarima-figure/unnamed-chunk-2-1.png" title="plot of chunk unnamed-chunk-2" alt="plot of chunk unnamed-chunk-2" style="display: block; margin: auto;" />

Thống kê mô tả
========================================================
type: prompt
left: 50%

Kết quả thống kê mô tả giá trị xuất khẩu xăng, dầu hoả:

```r
summary(export)
```

```
      time                value       
 Min.   :2010-01-29   Min.   : 37.00  
 1st Qu.:2012-10-22   1st Qu.: 70.75  
 Median :2015-07-15   Median : 97.00  
 Mean   :2015-07-15   Mean   :105.06  
 3rd Qu.:2018-04-06   3rd Qu.:136.00  
 Max.   :2020-12-31   Max.   :225.00  
```
<br></br>

<small> Quan sát box plot, ta thấy rằng dữ liệu có phân phối lệch phải và không chứa giá trị ngoại lệ. </small>
***
<button class="hidecode" onclick="doclick(this);"> Show Code </button>
<div class="hideme"></div>

```r
boxplot(export$value, col = "steelblue")
```

<img src="Sarima-figure/unnamed-chunk-4-1.png" title="plot of chunk unnamed-chunk-4" alt="plot of chunk unnamed-chunk-4" style="display: block; margin: auto;" />

Chia tách dữ liệu để xây dựng và kiểm tra mô hình
========================================================
class: small-code
type: prompt

<small> Chia tập training/testing sao cho năm 2018 - 2020 sẽ được sử dụng làm dữ liệu test và dữ liệu còn lại được sử dụng để huấn luyện mô hình. </small>

<button class="hidecode" onclick="doclick(this);"> Show Code </button>
<div class="hideme" style = "align: center"></div>


```r
# Split data
time_series <- ts(export$value, start = 2010, frequency = 12, class = "ts")
training <- window(time_series, 2010, c(2017, 12))
testing <- window(time_series, 2018, c(2020, 12))
autoplot(training, color = "blue", size = 1) +
  autolayer(testing, color = "red", size = 1) +
  theme_minimal()
```

<img src="Sarima-figure/unnamed-chunk-5-1.png" title="plot of chunk unnamed-chunk-5" alt="plot of chunk unnamed-chunk-5" style="display: block; margin: auto;" />

Kiểm tra tính dừng của chuỗi dữ liệu (training time series)
========================================================
class: small-code
type: prompt

```r
adf.test(training)
```

```

	Augmented Dickey-Fuller Test

data:  training
Dickey-Fuller = -2.5627, Lag order = 4, p-value = 0.3439
alternative hypothesis: stationary
```

*Với mức ý nghĩa 5%, ta kết luận rằng chuỗi dữ liệu gốc có nghiệm đơn vị và có tính chất không dừng.*

  - Khắc phục chuỗi không dừng bằng sai phân bậc 1

<button class="hidecode" onclick="doclick(this);"> Show Code </button>
<div class="hideme" style = "align: center"></div>


```r
#' Sử dụng `ndiffs(training)` để xem bậc sai phân mà chuỗi dừng
diff_1 = diff(training, differences = 1)
adf.test(diff_1)
```

```

	Augmented Dickey-Fuller Test

data:  diff_1
Dickey-Fuller = -4.3792, Lag order = 4, p-value = 0.01
alternative hypothesis: stationary
```

**Với kết quả trên, ta kết luận chuỗi dữ liệu là chuỗi dừng ở sai phân bậc 1 (d = 1).**

Đồ thị chuỗi sai phân bậc 1
========================================================
type: prompt
class: small-code


```r
tsdisplay(diff_1, lwd = 2, points = F)
```

<img src="Sarima-figure/unnamed-chunk-8-1.png" title="plot of chunk unnamed-chunk-8" alt="plot of chunk unnamed-chunk-8" style="display: block; margin: auto;" />
  - Từ đồ thị PACF, các bậc của AR có thể có: p = {0, 1}
  - Từ đồ thị ACF, các bậc của MA có thế có: q = {0, 1, 5}

Kiểm tra sự tồn tại tính mùa của chuỗi sai phân
========================================================
<small> Để thực hiện ước lượng mô hình SARIMA thì chuỗi thời gian phải tồn tại yếu tố mùa vụ. Thực hiện WO-test để kiểm tra tính mùa trong chuỗi: </small>

```r
summary(wo(diff_1))
```

```
Test used:  WO 
 
Test statistic:  1 
P-value:  0.0007835722 0.01270625 0.001566043 
 
The WO - test identifies seasonality
```

```r
# WO-test kết hợp giữa QS-test và Kruskall-Wallis test.
# Nếu p-value của QS-test dưới 0.01 hoặc p-value của kwman-test dưới 0.002, 
# WO-test sẽ phân loại chuỗi thời gian có tính mùa.
# isSeasonal(diff_1)
```

**Kết quả kiểm định cho thấy chuỗi dữ liệu giá trị xuất khẩu xăng, dầu hoả tồn tại yếu tố mùa vụ.**

Phân tách các yếu tố trong chuỗi sai phân
========================================================
type: prompt
class: small-code

<button class="hidecode" onclick="doclick(this);"> Show Code </button>
<div class="hideme" style = "align: center"></div>


```r
component <- decompose(diff_1)
plot(component, lwd = 2)
```

<img src="Sarima-figure/unnamed-chunk-10-1.png" title="plot of chunk unnamed-chunk-10" alt="plot of chunk unnamed-chunk-10" style="display: block; margin: auto;" />

Kiểm tra tính dừng chuỗi mùa vụ
========================================================
type: prompt


```r
adf.test(component$seasonal)
```

```

	Augmented Dickey-Fuller Test

data:  component$seasonal
Dickey-Fuller = -3.6685, Lag order = 4, p-value = 0.03118
alternative hypothesis: stationary
```
<br></br>
**Với kết quả trên, ta kết luận chuỗi mùa vụ là chuỗi dừng (D = 0).**

Lựa chọn tham số P, Q cho thành phần mùa AR, MA
========================================================
type: prompt
class: small-code


```r
tsdisplay(component$seasonal, lwd = 2, points = F, main = "")
```

<img src="Sarima-figure/unnamed-chunk-12-1.png" title="plot of chunk unnamed-chunk-12" alt="plot of chunk unnamed-chunk-12" style="display: block; margin: auto;" />

  - Từ đồ thị PACF: P = {0, 1}
  - Đồ thị ACF: Q = {0, 1}

Lựa chọn mô hình SARIMA
========================================================
<br></br>

Từ những phân tích trên, ta thu được các tham số: p = {0, 1}; q = {0, 1, 5}; d = 1; P = {0, 1}; Q = {0, 1}. Một số mô hình SARIMA:
  - SARIMA (0, 1, 0) (1, 0, 0) [12]
  - SARIMA (0, 1, 1) (1, 0, 1) [12] 
  - SARIMA (1, 1, 0) (1, 0, 1) [12]
  - SARIMA (1, 1, 1) (1, 0, 1) [12]
  - SARIMA (0, 1, 0) (0, 0, 0) [12]
  - ...

Chạy mô hình mẫu
========================================================
class: small-code
Giả sử chọn mô hình SARIMA(0, 1, 0)(1, 0, 0)[12]


```r
model = Arima(training, order = c(0, 1, 0), seasonal = c(1, 0, 0))
summary(model)
```

```
Series: training 
ARIMA(0,1,0)(1,0,0)[12] 

Coefficients:
        sar1
      0.2646
s.e.  0.1066

sigma^2 estimated as 503.9:  log likelihood=-430.3
AIC=864.6   AICc=864.73   BIC=869.71

Training set error measures:
                   ME     RMSE      MAE       MPE     MAPE     MASE       ACF1
Training set 0.227419 22.21359 16.86878 -1.841731 17.09018 0.498059 -0.2678051
```

**Thực hiện chạy các mô hình SARIMA, sau đó chọn mô hình tốt nhất thông qua AIC.**

Lựa chọn mô hình SARIMA
=========================================================
type: prompt
class: small-code

<button class="hidecode" onclick="doclick(this);"> Show Code </button>
<div class="hideme" style = "align: center"></div>

```r
# Function choose model
results = function(x, orders, seasonal) {
  .df = data.frame()
  for(i in 1:5) {
    for(j in 1:4) {
      .sarima = Arima(training, order = unlist(orders[i]), seasonal = unlist(seasonal[j]))
      .model_name = paste("SARIMA", orders[i], seasonal[j], "[12]")
      .sum = summary(.sarima)
      .AIC = .sarima$aic %>% round(digits = 3)
      .BIC = .sarima$bic %>% round(digit = 3)
      .RMSE = .sum[2] %>% round(digits = 3)
      .MAPE = .sum[5] %>% round(digits = 3)
      .df = rbind(.df, c(.model_name, .AIC, .BIC, .RMSE, .MAPE), stringsAsFactors = FALSE)
    }
  }
  colnames(.df) = c("NameModel", "AIC", "BIC", "RMSE", "MAPE")
  .df = .df %>% arrange(AIC)
  return(.df)
}
orders = list(c(0, 0 ,0 ), c(0,1,0), c(0,1,1), c(1,1,0), c(1,1,1))
seasonal = list(c(0, 0, 0), c(1,0,0), c(1,0,1), c(0, 0, 1))
choose_model = results(training, orders, seasonal)
```
<center>

```r
head(choose_model, 9) %>% knitr::kable()
```



|NameModel                         |AIC     |BIC     |RMSE   |MAPE   |
|:---------------------------------|:-------|:-------|:------|:------|
|SARIMA c(0, 1, 1) c(1, 0, 1) [12] |853.713 |863.929 |19.953 |16.683 |
|SARIMA c(1, 1, 1) c(1, 0, 1) [12] |855.537 |868.307 |19.958 |16.7   |
|SARIMA c(1, 1, 0) c(1, 0, 1) [12] |855.697 |865.913 |20.266 |16.607 |
|SARIMA c(0, 1, 1) c(1, 0, 0) [12] |857.492 |865.154 |21.194 |16.441 |
|SARIMA c(1, 1, 1) c(1, 0, 0) [12] |858.593 |868.809 |21.077 |16.618 |
|SARIMA c(0, 1, 1) c(0, 0, 1) [12] |858.645 |866.306 |21.356 |16.528 |
|SARIMA c(0, 1, 1) c(0, 0, 0) [12] |859.089 |864.197 |21.661 |16.681 |
|SARIMA c(1, 1, 0) c(1, 0, 0) [12] |859.312 |866.974 |21.403 |16.166 |
|SARIMA c(1, 1, 1) c(0, 0, 1) [12] |859.924 |870.14  |21.263 |16.706 |
</center>

<center> **Mô hình có chỉ số AIC nhỏ nhất là SARIMA (0, 1, 1) (1, 0, 1) [12]** </center>

auto.arima() function
========================================================
class: small-code
  - Lựa chọn mô hình


```r
model = auto.arima(training)
summary <- summary(model)
```

```
Series: training 
ARIMA(0,1,1)(0,0,2)[12] 

Coefficients:
          ma1    sma1    sma2
      -0.3524  0.1701  0.2083
s.e.   0.1076  0.1132  0.1069

sigma^2 estimated as 451.9:  log likelihood=-424.39
AIC=856.77   AICc=857.22   BIC=866.99

Training set error measures:
                    ME     RMSE     MAE       MPE     MAPE      MASE       ACF1
Training set 0.2593003 20.81134 16.3525 -2.089171 16.37493 0.4828156 0.02273757
```

Với kết quả bên trên, cho thấy mô hình <b> SARIMA (0,1,1)(0,0,2)[12] </b> là mô hình tốt nhất.

Ta sử dụng mô hình này để thực hiện các kiểm định liên quan và thực hiện dự báo.

Kiểm tra ý nghĩa thống kê của hệ số hồi quy
========================================================


```r
lmtest::coeftest(model)
```

```

z test of coefficients:

     Estimate Std. Error z value Pr(>|z|)   
ma1  -0.35241    0.10762 -3.2748 0.001058 **
sma1  0.17006    0.11322  1.5020 0.133110   
sma2  0.20826    0.10689  1.9484 0.051369 . 
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
```
<br></br>
**Kết quả cho thấy, ta chấp nhận rằng hệ số ma1 và sma2 có ý nghĩa thống kê ở mức 5%, hệ số sma1 có ý nghĩa thống kê ở mức 10%.**

Dự báo bằng SARIMA(0,1,1)(0,0,2)[12]
========================================================
type: prompt
class: small-code
<button class="hidecode" onclick="doclick(this);"> Show Code </button>
<div class="hideme" style = "align: center"></div>


```r
plot(training, col = "black", lwd = 2, type = "l")
lines(model$fitted, col = "red", lwd = 2, type = "l")
legend(2015, 230, legend = c("Data", "Forecast"), col = c("black", "red"), lty=1:1, box.lty=0, text.font=2)
```

<img src="Sarima-figure/unnamed-chunk-18-1.png" title="plot of chunk unnamed-chunk-18" alt="plot of chunk unnamed-chunk-18" style="display: block; margin: auto;" />


```
                    ME     RMSE     MAE       MPE     MAPE      MASE       ACF1
Training set 0.2593003 20.81134 16.3525 -2.089171 16.37493 0.4828156 0.02273757
```

Kiểm tra chuỗi phần dư
========================================================
class: small-code
type: prompt
left: 40%

```r
checkresiduals(model, plot = F, main = "Residuals from SARIMA(0, 1, 1)(0, 0, 2)[12]", lwd = 2, points = F)
```

```

	Ljung-Box test

data:  Residuals from ARIMA(0,1,1)(0,0,2)[12]
Q* = 18.249, df = 16, p-value = 0.3095

Model df: 3.   Total lags used: 19
```
<br></br>

**Chuỗi phần dư là chuỗi nhiễu trắng, không có tự tương quan bậc 1. Mô hình SARIMA này dự báo tốt.**

***
<center><img src = "checkresid.png" style = "width: 900px; height: 530px;"></center>

Dự báo ngoài mẫu
========================================================
type: prompt
class: small-code

<button class="hidecode" onclick="doclick(this);"> Show Code </button>
<div class="hideme" style = "align: center"></div>


```r
predict <- forecast(model, h = 36)
plot(predict, lwd = 2)
legend(2014, 280, legend = c("Data", "Forecast"), col = c("black", "#009ACD"), lty=1:1, box.lty=0, text.font=2)
```

<img src="Sarima-figure/unnamed-chunk-21-1.png" title="plot of chunk unnamed-chunk-21" alt="plot of chunk unnamed-chunk-21" style="display: block; margin: auto;" />

Kiểm tra kết quả dự báo
=========================================================
type: prompt
class: small-code
left: 75%
class: small

<button class="hidecode" onclick="doclick(this);"> Show Code </button>
<div class="hideme" style = "align: center"></div>

```r
plot(testing, lwd = 2)
lines(predict$mean, col = "red", lwd = 2)
legend(2020.1, 180, legend = c("Data", "Forecast"), col = c("black", "red"), lty=1:1, box.lty=0, text.font=2)
```

<img src="Sarima-figure/unnamed-chunk-22-1.png" title="plot of chunk unnamed-chunk-22" alt="plot of chunk unnamed-chunk-22" style="display: block; margin: auto;" />

***
<br></br>

Sai số dự báo RMSE:

```
[1] 18.888
```

Dự báo cho năm 2021
=========================================================
class: small-code
type: prompt

```r
model = Arima(time_series, order = c(0, 1, 1), seasonal = c(0, 0, 2))
predict = forecast(model, h = 12)
plot(predict, lwd = 2)
```

<img src="Sarima-figure/unnamed-chunk-24-1.png" title="plot of chunk unnamed-chunk-24" alt="plot of chunk unnamed-chunk-24" style="display: block; margin: auto;" />


Kết luận 
=========================================================

Kết quả cho thấy mô hình dự báo SARIMA đáng tin cậy và dự báo tốt trong ngắn hạn. Mô hình có thể được
dùng để dự báo giá trị xuất khẩu xăng, dầu hoả cho các giai đoạn tiếp theo, khi dữ
liệu được cập nhật.

Tuy nhiên, trên thực tế còn có rất nhiều yếu tố tác động đến giá trị xuất khẩu xăng dầu, trong đó có những yếu tố rất khó xác định và thường xuyên biến động (cung cầu, dịch bệnh, tỷ giá,...), hơn nữa giữa các yếu tố này còn có sự tác động qua lại lẫn nhau ở một độ trễ nhất định. Chính vì thế việc dự báo sẽ tồn tại những sai số nhất định. 

Việc sử dụng mô hình SARIMA là chưa đủ để có thể đo lường chính xác sự biến động. Để tăng độ chính xác cho kết quả dự báo, cần kết hợp nhiều mô hình khác nhau để đo lường hoặc sử dụng những mô hình nâng cao như mô hình ARCH, GARCH, VaR để phân tích.


=========================================================
type: anhnen
<br></br>
<br></br>
<br></br>
<p style = "color: white; font-weight: bold; font-family: Brush Script MT; font-size: 108px; text-align: center"> Thank you for listening! </p>



















