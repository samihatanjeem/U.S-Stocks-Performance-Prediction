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
r# Filtered ~8,500 XBRL indicators down to 9 key financial variables
# across three indicator source files (income statement, balance sheet, cash flow)
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
## Model 1:  Pooled OLS Regression (Full Model)
<img width="429" height="276" alt="image" src="https://github.com/user-attachments/assets/9757f712-7b03-4261-974e-c83310c3d53b" />
<img width="2700" height="1500" alt="figure3_actual_vs_predicted" src="https://github.com/user-attachments/assets/4e2f42ea-2553-455e-8ce2-3ecb7ad8caf2" />

## Model 2: Baseline (Single-Variable)
A naive baseline using only current-year ROA to predict next-year ROA, used as a performance benchmark.
<img width="444" height="631" alt="Screenshot 2026-04-26 213517" src="https://github.com/user-attachments/assets/a5a132aa-d463-46d6-84a2-18ba8db7ddfb" />

<img width="2700" height="1500" alt="figure4_OLS_vs_baseline" src="https://github.com/user-attachments/assets/efa7bc42-ac90-4c3c-b117-e462714303e8" />

##Model 3: Stratified Regression by Firm Size
Separate OLS models for small, medium, and large firms (by total asset tercile) to test whether predictive drivers shift across firm segments.
<img width="747" height="653" alt="Screenshot 2026-04-27 005031" src="https://github.com/user-attachments/assets/259c79f6-d99c-43fd-a7b0-7a95f6dd5230" />
<img width="776" height="414" alt="Screenshot 2026-04-27 005104" src="https://github.com/user-attachments/assets/8a5ac779-4ee7-49ed-884b-422b0ff1eccf" />




# Tools & Technologies
R Studio
OLS Regression
Robust Standard Errors (HC3)
Panel Data Analysis
Financial Ratio Engineering
XBRL Financial Data (Kaggle)
