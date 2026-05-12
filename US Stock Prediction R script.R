# =============================================================================
# Financial Ratio Analysis: Predicting Next-Year ROA
# Data: US Stocks Fundamentals (XBRL), 2010–2014
# =============================================================================

# --- Package Setup -----------------------------------------------------------

install.packages(c(
  "readxl", "dplyr", "tidyr", "ggplot2",
  "lmtest", "sandwich", "Metrics",
  "corrplot", "stargazer", "car"
))

library(dplyr)
library(tidyr)
library(ggplot2)
library(corrplot)
library(stargazer)
library(lmtest)
library(sandwich)
library(car)
library(Metrics)

# =============================================================================
# Phase 1: Data Loading, Reshaping & Feature Engineering
# =============================================================================

target_indicators <- c(
  "NetIncomeLoss",
  "Assets",
  "Revenues",
  "Liabilities",
  "StockholdersEquity",
  "AccountsReceivableNetCurrent",
  "InventoryNet",
  "DepreciationAndAmortization",
  "Depreciation"
)

load_indicators <- function(filepath) {
  read.csv(filepath) |>
    filter(indicator_id %in% target_indicators)
}


part1 <- load_indicators("indicators part1.csv")
part2 <- load_indicators("indicators part2.csv")
part3 <- load_indicators("indicators part3.csv")

indicators_raw <- bind_rows(part1, part2, part3)
companies      <- read.csv("companies.csv")

cat("Total indicator rows:", nrow(indicators_raw), "\n")
cat("Unique companies:    ", n_distinct(indicators_raw$company_id), "\n")

# Pivot to long format (one row per company-indicator-year)
years <- paste0("X", 2010:2016)

indicators_long <- indicators_raw |>
  pivot_longer(cols = all_of(years), names_to = "year", values_to = "value") |>
  mutate(year = as.integer(sub("X", "", year))) |>
  filter(!is.na(value))

# Pivot wide (one row per company-year, one column per indicator)
panel <- indicators_long |>
  pivot_wider(
    id_cols     = c(company_id, year),
    names_from  = indicator_id,
    values_from = value,
    values_fn   = mean
  ) |>
  mutate(DA = coalesce(DepreciationAndAmortization, Depreciation))

# Keep only 2010-2014 and drop rows missing core variables
panel <- panel |>
  filter(year >= 2010, year <= 2014) |>
  filter(
    !is.na(Assets) & Assets > 0,
    !is.na(NetIncomeLoss),
    !is.na(Revenues),
    !is.na(Liabilities)
  )

cat("After core filter:", nrow(panel), "rows,",
    n_distinct(panel$company_id), "companies\n")

# Engineer financial ratios
panel <- panel |>
  group_by(company_id) |>
  arrange(company_id, year) |>
  mutate(
    Assets_lag1     = lag(Assets, 1),
    AR_lag1         = lag(AccountsReceivableNetCurrent, 1),
    Inv_lag1        = lag(InventoryNet, 1),
    NetIncome_lead1 = lead(NetIncomeLoss, 1),
    Assets_lead1    = lead(Assets, 1),
    
    ROA_next       = NetIncome_lead1 / Assets_lead1,
    ROA_current    = NetIncomeLoss / Assets,
    Profit_Margin  = NetIncomeLoss / Revenues,
    Debt_Ratio     = Liabilities / Assets,
    Asset_Turnover = Revenues / Assets,
    AR_Growth      = (AccountsReceivableNetCurrent - AR_lag1) / Assets_lag1,
    Inv_Growth     = (InventoryNet - Inv_lag1) / Assets_lag1,
    Depr_to_Assets = DA / Assets
  ) |>
  ungroup()

# Build analytic dataset
ratio_cols <- c(
  "ROA_next", "ROA_current", "Profit_Margin",
  "Debt_Ratio", "Asset_Turnover",
  "AR_Growth", "Inv_Growth", "Depr_to_Assets"
)

winsorize <- function(x, probs = c(0.01, 0.99)) {
  bounds <- quantile(x, probs, na.rm = TRUE)
  pmax(pmin(x, bounds[2]), bounds[1])
}

analytic <- panel |>
  filter(year %in% c(2011, 2012, 2013)) |>
  select(company_id, year, all_of(ratio_cols), Assets) |>
  na.omit() |>
  mutate(
    across(all_of(ratio_cols), winsorize),
    size_group = case_when(
      Assets < quantile(Assets, 0.33) ~ "Small",
      Assets < quantile(Assets, 0.67) ~ "Medium",
      TRUE                            ~ "Large"
    ),
    size_group = factor(size_group, levels = c("Small", "Medium", "Large"))
  )

cat("Analytic dataset:", nrow(analytic), "rows,",
    n_distinct(analytic$company_id), "companies\n")
print(table(analytic$size_group))

# --- Plot 1: Distribution of Next-Year ROA -----------------------------------

ggplot(analytic, aes(x = ROA_next)) +
  geom_histogram(bins = 40, fill = "#2C7BB6", color = "white", alpha = 0.85) +
  geom_vline(
    xintercept = mean(analytic$ROA_next),
    color = "#D7191C", linetype = "dashed", linewidth = 1
  ) +
  annotate(
    "text",
    x     = mean(analytic$ROA_next) + 0.15,
    y     = 30,
    label = paste("Mean:", round(mean(analytic$ROA_next), 3)),
    color = "#D7191C", size = 3.5, hjust = 0
  ) +
  scale_x_continuous(limits = c(-1, 0.5)) +
  labs(
    title    = "Distribution of Next-Year ROA",
    subtitle = "U.S. Publicly Listed Firms, 2011–2013 (zoomed to core distribution)",
    x        = "Next-Year ROA",
    y        = "Number of Firms",
    caption  = "Source: US Stocks Fundamentals (XBRL)"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title       = element_text(face = "bold", size = 15),
    plot.subtitle    = element_text(color = "gray50"),
    plot.caption     = element_text(color = "gray60", size = 9),
    panel.grid.minor = element_blank()
  )

ggsave("figure1_ROA_distribution.png", width = 9, height = 5, dpi = 300)

# =============================================================================
# Phase 2: Descriptive Statistics & Correlations
# =============================================================================

desc_vars <- analytic |> select(all_of(ratio_cols))

stargazer(
  as.data.frame(desc_vars),
  type   = "text",
  title  = "Table 1: Descriptive Statistics",
  digits = 3,
  out    = "descriptive_stats.txt"
)

cor_matrix <- cor(desc_vars, use = "complete.obs")
print(round(cor_matrix, 3))

# --- Plot 2: Correlation Matrix ----------------------------------------------

col_palette <- colorRampPalette(c("#D7191C", "#FFFFFF", "#2C7BB6"))(200)

corrplot(
  cor_matrix,
  method      = "color",
  col         = col_palette,
  type        = "upper",
  tl.cex      = 0.9,
  tl.col      = "black",
  tl.srt      = 45,
  addCoef.col = "black",
  number.cex  = 0.8,
  cl.cex      = 0.8,
  cl.ratio    = 0.15,
  title       = "Correlation Matrix of Financial Ratios",
  mar         = c(0, 0, 2.5, 0),
  diag        = FALSE,
  outline     = TRUE
)

# =============================================================================
# Phase 3: OLS Regression & Diagnostics
# =============================================================================

model_ols <- lm(
  ROA_next ~ ROA_current + Profit_Margin + Debt_Ratio +
    Asset_Turnover + AR_Growth + Inv_Growth + Depr_to_Assets,
  data = analytic
)

stargazer(
  model_ols,
  type             = "text",
  title            = "Table 2: OLS Regression Results",
  dep.var.labels   = "Next-Year ROA",
  covariate.labels = c(
    "Current ROA", "Profit Margin", "Debt Ratio",
    "Asset Turnover", "AR Growth", "Inventory Growth",
    "Depreciation to Assets"
  ),
  digits = 3,
  out    = "regression_results.txt"
)

# Assumption checks
cat("\n--- VIF (Multicollinearity) ---\n");            print(vif(model_ols))
cat("\n--- Breusch-Pagan (Heteroskedasticity) ---\n"); print(bptest(model_ols))
cat("\n--- Durbin-Watson (Autocorrelation) ---\n");    print(dwtest(model_ols))

# --- Plot 3: Actual vs Predicted ROA -----------------------------------------

analytic$predicted_ROA <- fitted(model_ols)

ggplot(analytic, aes(x = predicted_ROA, y = ROA_next)) +
  geom_point(alpha = 0.5, color = "#2C7BB6", size = 2.5) +
  geom_abline(
    intercept = 0, slope = 1,
    color = "#D7191C", linetype = "dashed", linewidth = 1
  ) +
  geom_smooth(
    method = "lm", color = "gray40",
    se = TRUE, fill = "gray70", alpha = 0.2, linewidth = 0.9
  ) +
  scale_x_continuous(limits = c(-2, 1)) +
  scale_y_continuous(limits = c(-2, 0.5)) +
  annotate(
    "text",
    x     = 0.5,
    y     = -1.8,
    label = paste("R² =", round(summary(model_ols)$r.squared, 3)),
    color = "#2C7BB6", size = 4.5, fontface = "bold"
  ) +
  labs(
    title    = "Actual vs Predicted Next-Year ROA",
    subtitle = "Red dashed line = perfect prediction | Gray band = model fit with 95% CI",
    x        = "Predicted Next-Year ROA",
    y        = "Actual Next-Year ROA",
    caption  = "Source: US Stocks Fundamentals (XBRL)"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title       = element_text(face = "bold", size = 15),
    plot.subtitle    = element_text(color = "gray50"),
    plot.caption     = element_text(color = "gray60", size = 9),
    panel.grid.minor = element_blank()
  )

ggsave("figure3_actual_vs_predicted.png", width = 9, height = 5, dpi = 300)

# =============================================================================
# Phase 4: Train/Test Split & Model Evaluation
# =============================================================================

# Time-based 70/30 split
train <- analytic |> filter(year %in% c(2011, 2012))
test  <- analytic |> filter(year == 2013)

cat("Training observations:", nrow(train), "\n")
cat("Test observations:",     nrow(test),  "\n")

# Train OLS on training set
model_train <- lm(ROA_next ~ ROA_current + Profit_Margin + Debt_Ratio +
                    Asset_Turnover + AR_Growth + Inv_Growth + Depr_to_Assets,
                  data = train)

# Baseline model (prior ROA only)
model_baseline <- lm(ROA_next ~ ROA_current, data = train)

# Predictions on test set
pred_ols      <- predict(model_train,    newdata = test)
pred_baseline <- predict(model_baseline, newdata = test)

# Evaluation metrics
cat("\n--- OLS Model ---\n")
cat("R²:  ", round(cor(pred_ols,      test$ROA_next)^2, 3), "\n")
cat("RMSE:", round(rmse(test$ROA_next, pred_ols),        3), "\n")
cat("MAE: ", round(mae(test$ROA_next,  pred_ols),        3), "\n")

cat("\n--- Baseline Model ---\n")
cat("R²:  ", round(cor(pred_baseline, test$ROA_next)^2,  3), "\n")
cat("RMSE:", round(rmse(test$ROA_next, pred_baseline),   3), "\n")
cat("MAE: ", round(mae(test$ROA_next,  pred_baseline),   3), "\n")


# --- Plot 4: Model Comparison ------------------------------------------------

# Build metrics from actual computed results (not hardcoded)
metrics_df <- data.frame(
  Model  = rep(c("OLS Model", "Baseline Model"), each = 3),
  Metric = rep(c("R²", "RMSE", "MAE"), 2),
  Value  = c(
    round(cor(pred_ols,      test$ROA_next)^2, 3),
    round(rmse(test$ROA_next, pred_ols),        3),
    round(mae(test$ROA_next,  pred_ols),        3),
    round(cor(pred_baseline, test$ROA_next)^2,  3),
    round(rmse(test$ROA_next, pred_baseline),   3),
    round(mae(test$ROA_next,  pred_baseline),   3)
  )
)

metrics_df$Metric <- factor(metrics_df$Metric, levels = c("R²", "RMSE", "MAE"))

ggplot(metrics_df, aes(x = Metric, y = Value, fill = Model)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.6),
           width = 0.5, alpha = 0.85) +
  geom_text(aes(label = round(Value, 3)),
            position = position_dodge(width = 0.6),
            vjust = -0.5, size = 3.8, fontface = "bold") +
  scale_fill_manual(values = c("OLS Model"      = "#2C7BB6",
                               "Baseline Model" = "#D7191C")) +
  labs(
    title    = "OLS Model vs Baseline Model: Performance Metrics",
    subtitle = "Evaluated on holdout test set (2013 firm-year observations)",
    x        = "Evaluation Metric",
    y        = "Value",
    fill     = "Model",
    caption  = "Source: US Stocks Fundamentals (XBRL)"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title       = element_text(face = "bold", size = 15),
    plot.subtitle    = element_text(color = "gray50"),
    plot.caption     = element_text(color = "gray60", size = 9),
    panel.grid.minor = element_blank(),
    legend.position  = "top"
  )

ggsave("figure4_model_comparison.png", width = 9, height = 5, dpi = 300)


# =============================================================================
# Phase 5: Subgroup Analysis by Firm Size
# =============================================================================

model_small  <- lm(ROA_next ~ ROA_current + Profit_Margin + Debt_Ratio +
                     Asset_Turnover + AR_Growth + Inv_Growth + Depr_to_Assets,
                   data = analytic |> filter(size_group == "Small"))

model_medium <- lm(ROA_next ~ ROA_current + Profit_Margin + Debt_Ratio +
                     Asset_Turnover + AR_Growth + Inv_Growth + Depr_to_Assets,
                   data = analytic |> filter(size_group == "Medium"))

model_large  <- lm(ROA_next ~ ROA_current + Profit_Margin + Debt_Ratio +
                     Asset_Turnover + AR_Growth + Inv_Growth + Depr_to_Assets,
                   data = analytic |> filter(size_group == "Large"))

stargazer(model_small, model_medium, model_large,
          type             = "text",
          title            = "Table 3: Regression Results by Firm Size",
          column.labels    = c("Small", "Medium", "Large"),
          dep.var.labels   = "Next-Year ROA",
          covariate.labels = c("Current ROA", "Profit Margin",
                               "Debt Ratio", "Asset Turnover",
                               "AR Growth", "Inventory Growth",
                               "Depreciation to Assets"),
          digits = 3,
          out    = "regression_by_size.txt")


# --- Plot 5: Coefficients by Firm Size ---------------------------------------

extract_coefs <- function(model, size_label) {
  coefs <- summary(model)$coefficients
  data.frame(
    Variable = rownames(coefs),
    Estimate = coefs[, 1],
    SE       = coefs[, 2],
    Size     = size_label
  ) |> filter(Variable != "(Intercept)")
}

coef_df <- bind_rows(
  extract_coefs(model_small,  "Small"),
  extract_coefs(model_medium, "Medium"),
  extract_coefs(model_large,  "Large")
)

coef_df$Variable <- dplyr::recode(coef_df$Variable,
                                  "ROA_current"    = "Current ROA",
                                  "Profit_Margin"  = "Profit Margin",
                                  "Debt_Ratio"     = "Debt Ratio",
                                  "Asset_Turnover" = "Asset Turnover",
                                  "AR_Growth"      = "AR Growth",
                                  "Inv_Growth"     = "Inventory Growth",
                                  "Depr_to_Assets" = "Depreciation to Assets"
)

ggplot(coef_df, aes(x = Estimate, y = Variable, color = Size)) +
  geom_point(size = 3.5, position = position_dodge(width = 0.5)) +
  geom_errorbarh(
    aes(xmin = Estimate - 1.96 * SE,
        xmax = Estimate + 1.96 * SE),
    height    = 0.25,
    position  = position_dodge(width = 0.5),
    linewidth = 0.8
  ) +
  geom_vline(xintercept = 0, linetype = "dashed",
             color = "black", linewidth = 0.8) +
  scale_color_manual(values = c("Small"  = "#ABD9E9",
                                "Medium" = "#2C7BB6",
                                "Large"  = "#08306B")) +
  scale_x_continuous(limits = c(-3, 3)) +
  labs(
    title    = "Regression Coefficients by Firm Size",
    subtitle = "Error bars = 95% confidence intervals | Dashed line = zero effect",
    x        = "Coefficient Estimate",
    y        = NULL,
    color    = "Firm Size",
    caption  = "Source: US Stocks Fundamentals (XBRL)"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title       = element_text(face = "bold", size = 15),
    plot.subtitle    = element_text(color = "gray50"),
    plot.caption     = element_text(color = "gray60", size = 9),
    panel.grid.minor = element_blank(),
    legend.position  = "top"
  )

ggsave("figure5_coefficients_by_size.png", width = 10, height = 6, dpi = 300)
