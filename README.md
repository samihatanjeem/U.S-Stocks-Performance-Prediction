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

# Tools & Technologies
R Studio
OLS Regression
Robust Standard Errors (HC3)
Panel Data Analysis
Financial Ratio Engineering
XBRL Financial Data (Kaggle)
