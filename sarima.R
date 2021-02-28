# Library ========================
library(tidyverse)
library(forecast)
library(tseries)
library(kableExtra)
# a$x[GenKern::nearest(a$y, max(a$y), outside = TRUE)]

# Read file ======================
export <- readxl::read_xlsx('VietnamGas.xlsx', sheet = 'data')
export$time <- as.Date(export$time)
max = filter(export, value == max(value))
min = filter(export, value == min(value))
# Plot data ===================
ggplot() +
  geom_line(data = export, aes(x = time, y = value), size = 1) +
  geom_smooth(data = export, aes(x = time, y = value), method = "lm", se = FALSE, size = 2) + 
  geom_point(data = max, 
             aes(x = time, y = value), color = "red", size = 7) +
  geom_point(data = min,
             aes(x = time, y = value), color = "red", size = 7) +
  geom_hline(yintercept = mean(export$value), size = 1, color = "red") +
  scale_x_date(date_breaks = "1 years", date_labels = "%Y") + 
  annotate('text', x = as.Date("2013-03-31", "%Y-%m-%d"), y = 230,
           label = paste0(" Time: ", max$time, "\nValue max: $", max$value, "M"), size = 6) +
  annotate('text', x = as.Date("2019-05-31", "%Y-%m-%d"), y = 40, 
           label = paste0(" Time: ", min$time, "\nValue min: $", min$value, "M"), size = 6) + 
  annotate("text", x = as.Date("2020-08-31", "%Y-%m-%d"), y = 110, 
           label = "bold(mean)", size = 6, parse = TRUE) +
  annotate("text", x = as.Date("2020-08-31", "%Y-%m-%d"), y = 100, 
           label = round(mean(export$value), 3), size = 5) +
  labs(x = '', y = "Million USD") +
  theme_minimal()

# Description ==========================
summary(export$value)
boxplot(export$value, col = "steelblue")

# Split data ===========================
time_series <- ts(export$value, start = 2010, frequency = 12, class = "ts")
training <- window(time_series, 2010, c(2017, 12))
testing <- window(time_series, 2018, c(2020, 12))
ggplot() +
  geom_line(data = filter(export,lubridate::year(time) <= 2017), aes(x = time, y = value),
            size = 1, color = "blue") +
  geom_line(data = filter(export,lubridate::year(time) > 2017), aes(x = time, y = value),
            size = 1, color = "red") +
  theme_minimal()

# Tính dừng ================
adf.test(training)
  #' Sử dụng `ndiffs(training)` để xem bậc sai phân mà chuỗi dừng
diff_1 = diff(training, differences = 1)
adf.test(diff_1)

# plot diff_1 ===========
tsdisplay(diff_1, lwd = 2, points = F)

# Kiểm tra sự tồn tại tính mùa ===========
library(seastests)
summary(wo(diff_1))
  #' WO-test kết hợp giữa QS-test và Kruskall-Wallis test.
  #' Nếu p-value của QS-test dưới 0.01 hoặc p-value của kwman-test dưới 0.002, 
  #' WO-test sẽ phân loại chuỗi thời gian có tính mùa.

# Phân tách các yếu tố trong chuỗi ================
component <- decompose(diff_1)
plot(component, lwd = 2)

# Tính dừng của chuỗi mùa vụ ===============
adf.test(component$seasonal)

# Plot chuỗi mùa vụ ==================
tsdisplay(component$seasonal, lwd = 2, points = F, main = "")

# Chạy mô hình mẫu ===================
model = Arima(training, order = c(0, 1, 0), seasonal = c(1, 0, 0))
summary(model)

# Function choose model ==================
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

# Auto-arima ================
model = auto.arima(training)
summary <- summary(model)
# Kiểm tra hệ số hồi quy =============
lmtest::coeftest(model)

# Plot dự báo
plot(training, col = "black", lwd = 2, type = "l")
lines(model$fitted, col = "red", lwd = 2, type = "l")
legend(2015, 230, legend = c("Data", "Forecast"), col = c("black", "red"),
       lty=1:1, box.lty=0, text.font=2)

# Kiểm tra chuỗi phần dư =============
checkresiduals(model, plot = F, main = "Residuals from SARIMA(0, 1, 1)(0, 0, 2)[12]", 
               lwd = 2, points = F)

# Dự báo ngoài mẫu ==============
predict <- forecast(model, h = 36)
plot(predict, lwd = 2)
legend(2014, 280, legend = c("Data", "Forecast"), 
       col = c("black", "#009ACD"), lty=1:1, box.lty=0, text.font=2)

# Kiểm tra kết quả dự báo ===========
plot(testing, lwd = 2)
lines(predict$mean, col = "red", lwd = 2)
legend(2020.1, 180, legend = c("Data", "Forecast"), col = c("black", "red"),
       lty=1:1, box.lty=0, text.font=2)
  # sai số RMSE
sqrt((sum(testing - predict$mean)^2)/length(testing))

# Dự báo cho năm 2021 ===================
model = Arima(time_series, order = c(0, 1, 1), seasonal = c(0, 0, 2))
predict = forecast(model, h = 12)
plot(predict, lwd = 2)