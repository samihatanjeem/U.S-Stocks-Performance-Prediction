# 📈U.S-Stocks-Performance-Prediction 
The US stock companies submit their financial data to the US Securities and Exchange Commission in a format called XBRL or eXtensible Business Reporting Language (2025). This makes the data available to the public but it is not easy to use right away since it requires a lot of data cleaning and adjustments done through technical tools before analysis. This project uses the US Stocks Fundamentals dataset with financial data of 12,129 companies to solve this problem. It builds a firm-year panel dataset using XBRL financial data by extracting assets, revenue, income, liabilities, and equity to engineer ratios like ROA, ROE, debt ratio, asset turnover, inventory growth, and profit margin. It uses OLS regression to predict next-period ROA and identify financial drivers of future US stock firms performance.

# 🎯Objectives
1. Build a structured firm-year dataset from XBRL financial data
2. Engineer financial ratios including ROA, profit margin, debt ratio, and asset turnover
3. Apply regression models to predict next-period firm performance
4. Identify financial drivers that influence future profitability and decision-making

# Key Findings
1. Current ROA was the strongest predictor of next-year ROA
2. Higher debt ratios were associated with weaker future performance
3. Predictive drivers varied significantly across firm sizes
4. The model achieved strong interpretive value for financial forecasting
Which financial indicators best predict a company's next-year Return on Assets (ROA)?
The pipeline covers everything from raw indicator extraction and reshaping to ratio engineering, outlier handling, and model validation — making this as much a data engineering project as a modeling one.

# ⚙️Data Engineering Pipeline
The raw dataset arrived as a multi-file structure with over 1 million rows of financial indicators across 12,000+ companies, requiring significant engineering before any analysis was possible.

## 1. Raw Data Extraction & Filtering
Filtered ~8,500 XBRL indicators down to 9 key financial variables across three indicator source files (income statement, balance sheet, cash flow)
<img width="371" height="187" alt="image" src="https://github.com/user-attachments/assets/41ec989e-9dd8-4d9c-97fd-d68f133b339b" />

## 2. Wide-to-Long Reshape & Panel Construction
The source data was structured in wide format (one row per company, hundreds of indicator columns). It was reshaped into a tidy firm-year panel using pivot operations in R:
<img width="488" height="218" alt="image" src="https://github.com/user-attachments/assets/2d7c7112-7116-4d63-8c88-ab6114637e6e" />

## 3. Data Cleaning & Quality Filtering
Removed firms with missing Assets (Core denominator for all ratios)
Removed firms with < 2 consecutive years (Required for forward-looking target variable)
Filtered to 2011–2013 window (Highest data completeness across firms)
Winsorized at 1st / 99th percentile (Removed extreme outlier distortion)
After cleaning: 279 firm-year observations across 182 companies (down from 12,129 raw companies).

# 📊 Modeling & Analysis
## Model 1: Descriptive Statistics
After thorough data cleaning, the dataset consists of 279 firm year observations across 182 companies from 2011 to 2013. 
<img width="474" height="242" alt="Screenshot 2026-04-26 203203" src="https://github.com/user-attachments/assets/b5d4939c-e9ec-4956-ad53-baa6dc773713" />
<img width="765" height="536" alt="Screenshot 2026-04-26 205518" src="https://github.com/user-attachments/assets/a393cd49-dba9-43d5-abf1-b37d47f25c04" />

## Model 2: Correlation Analysis
The current year ROA and next year ROA have a strongly positive correlation with 0.795, which gives us a strong signal that the firms across performing well in the current year are more likely to perform well in the next year, which proves one of our hypotheses. 
<img width="574" height="302" alt="Screenshot 2026-04-26 210532" src="https://github.com/user-attachments/assets/0be70e7e-c98c-4b63-9376-cd4012f1b29a" />
The correlation table and matrix chart was built using R, and the financial ratios show several notable relationships between the variables. 
<img width="605" height="529" alt="Screenshot 2026-04-26 210607" src="https://github.com/user-attachments/assets/d1a35682-e939-4262-ae06-9ef85e9afb87" />

## Model 3: Regression Assumption Tests
We performed 3 diagnostic tests with R regression to verify the models before interpreting the results. 
Multicollinearity (VIF) , Heteroskedasticity , Autocorrelation
<img width="539" height="429" alt="Screenshot 2026-04-26 213609" src="https://github.com/user-attachments/assets/cd0c51d2-4329-4235-bd0e-a5c7c890699f" />
The Actual vs Predicted plot shows how well the model fits the data. Most points cluster around the regression line with an R² of 0.673, which means the model captures the general direction of next-year ROA well. Some dots are visible at extreme negative values, where the model slightly underpredicts losses for the worst performing firms.
<img width="630" height="419" alt="Screenshot 2026-04-26 213718" src="https://github.com/user-attachments/assets/f0aec6bf-fc47-4938-bef7-11f9a4086d9f" />

<img width="429" height="276" alt="image" src="https://github.com/user-attachments/assets/9757f712-7b03-4261-974e-c83310c3d53b" />
<img width="2700" height="1500" alt="figure3_actual_vs_predicted" src="https://github.com/user-attachments/assets/4e2f42ea-2553-455e-8ce2-3ecb7ad8caf2" />

## Model 4:  OLS Regression Results
We used all 7 predictors to estimate the OLS regression model to evaluate the next year ROA. 
<img width="429" height="276" alt="image" src="https://github.com/user-attachments/assets/9757f712-7b03-4261-974e-c83310c3d53b" />
<img width="444" height="631" alt="Screenshot 2026-04-26 213517" src="https://github.com/user-attachments/assets/b1d386bf-dc58-4b01-8950-7741d934d51e" />

OLS Model VS Baseline Model:
The baseline model slightly outperformed the full OLS model  among 3 metrics - higher R², lower RMSE, and lower MAE. This tells us, adding six extra predictors with current ROA did not significantly improve out-of-sample prediction accuracy. 
<img width="609" height="380" alt="Screenshot 2026-04-26 220550" src="https://github.com/user-attachments/assets/a9a7f5f1-7434-4835-9a26-c6574cc58143" />


## Model 5: Regression Analysis by Firm Size
<img width="747" height="653" alt="Screenshot 2026-04-27 005031" src="https://github.com/user-attachments/assets/29a6cc19-e0a9-417c-9def-2f20dc376422" />

Separate OLS models for small, medium, and large firms (by total asset tercile) to test whether predictive drivers shift across firm segments.
Small Firms have an R² of 0.646, Current ROA  of 1.187 and  p value  < 0.01. Small firms have a Debt Ratio of negative -0.722 with p value  < 0.01. This tells us that small firms heavily depend on current earnings for their future performance and are most sensitive to leverage. 
Medium Firms have an R² of 0.529, Current ROA of 0.392 and p value < 0.05. Medium firms have a Profit Margin of 0.135 with p value < 0.01 and a Debt Ratio of negative -0.386 with p value < 0.01. This tells us that medium firms are driven by a more balanced mix of predictors where profitability starts playing a bigger role alongside leverage.
Large Firms have an R² of 0.541, Profit Margin of 0.255 and p value < 0.01 and Inventory Growth of 0.706 with p value < 0.01. Large firms have a Debt Ratio of nearly zero at 0.027 with p value < 0.1. This tells us that large firms are least sensitive to debt and are more driven by profit margins and operational efficiency, suggesting they can absorb leverage without the same negative impact on future profitability that smaller firms experience.
 <img width="776" height="414" alt="Screenshot 2026-04-27 005104" src="https://github.com/user-attachments/assets/5263bffb-0e14-487e-b087-1b8e4f118dd5" />

# 📋 Findings Summary

Earnings persist. Current-year ROA is the single strongest predictor of next-year ROA (β = 1.261, p < 0.01), consistent with earnings persistence theory.
Leverage is a red flag. Debt ratio is consistently negative across all firm sizes (β = −0.619 full model), meaning highly leveraged firms significantly underperform the following year.
Firm size changes the story. Small firms are most sensitive to leverage. Large firms are driven by margins and operational efficiency. A single universal model misses these dynamics.
More variables ≠ better prediction. The baseline single-variable model marginally outperformed the full 7-predictor model on holdout data — a clean reminder that with only 127 training observations, model complexity can hurt more than it helps.
XBRL data has real signal — but requires real engineering. Going from 1M+ raw indicator rows to a clean, analysis-ready panel was the core challenge and biggest value-add of this project.


# ⚠️ Limitations & Future Work

Small sample: 279 observations limits multi-variable generalization. More years of XBRL data would meaningfully improve model stability.
Pooled OLS: A fixed-effects or random-effects panel model would better control for unobserved firm heterogeneity with a larger time window.
Narrow time range: 2011–2013 only. Results may not generalize across different economic cycles.
Future directions: Cross-validation, industry-stratified models, gradient boosting for non-linear relationships, and expanding to the full 2010–2016 window.


# 📄 Research Paper
The full academic write-up is available in [research_paper/](https://docs.google.com/document/d/1DgZ9cS1nuSOZk6VsdXNzbmhwzaivUfkv98UWt4RdzYs/edit?tab=t.0#heading=h.673jr5lgodgk) , covering theoretical background (accrual accounting theory, fundamental analysis, earnings persistence), hypothesis development, full methodology, and academic references.

# Tools & Technologies
Language: R
Data wrangling: dplyr, tidyr, readr
Modeling: base R lm(), sandwich (robust SEs), lmtest
Diagnostics: car (VIF), lmtest (Breusch-Pagan, Durbin-Watson)
Visualization: ggplot2, corrplot
Data source: XBRL Financial Data (Kaggle: https://www.kaggle.com/datasets/usfundamentals/us-stocks-fundamentals )
