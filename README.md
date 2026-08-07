# 🛒 E-Commerce Customer Retention & Revenue Analytics Engine

## 📑 Executive Summary
This project delivers an end-to-end data pipeline and analytical engine that models customer lifecycle dynamics, retention cohorts, revenue trends, and web funnel conversion optimization for an e-commerce platform. 

Using a Python-driven synthetic data generation engine, over 100,000+ relational records (users, transactional orders, and granular web activity session logs) were programmatically generated and ingested into a SQL database. The project demonstrates a full-stack data workflow—from data generation, relational schema design, and bulk database loading, to advanced analytical SQL querying and revenue modeling.

---

## 🛠️ Tech Stack & Tools
- **Python**: `Faker`, `NumPy`, `Pandas` (Synthetic Data Generation, Probability Weighting)
- **SQL (MySQL)**: Complex Joins, CTEs, Window Functions, Conditional Aggregations
- **Analytics Frameworks**: RFM Segmentation, Cohort Retention Analysis, Funnel Drop-off Analysis

---

## 🚀 The Analytics Roadmap

### Phase 0: Synthesizing Fake Data with Python
Leveraged the Python `Faker` library to synthesize a fully relational mock e-commerce dataset without exposing PII. The ecosystem models three core datasets:
1. **User Profiles**: Realistic demographics and account creation timestamps over a 3-year period.
2. **Order Transactions**: Simulated realistic purchasing variability (random item counts, pricing, weighted discount probabilities). Ensures logical consistency (orders happen *after* account creation). 
3. **Web Event Logs**: Generated clickstream and behavioral event logs to simulate user interactions across the conversion funnel (page views $\rightarrow$ add-to-cart $\rightarrow$ checkout $\rightarrow$ payment $\rightarrow$ purchase).

### Phase 1: Data Sanity Check & EDA (SQL)
Before deep-dive analytics, the raw data underwent rigorous auditing:
- **Primary Key Integrity**: Verified record counts and `user_id`, `order_id`, and `event_id` uniqueness.
- **Time Window Check**: Ensured operational timelines were logical (no orders pre-dating user creation).
- **Referential Integrity & Null Audits**: Validated foreign key constraints to prevent orphaned records and silent null-value corruptions.
- **Order Status Breakdown**: Inspected status distributions to separate recognized revenue from canceled/failed orders.

### Phase 2: Core Executive Metrics (AOV & Revenue)
Translated raw transactional rows into executive metrics:
- **Monthly Revenue & Growth Trends**: Modeled Net Sales, Gross Revenue, and Month-over-Month (MoM) Growth percentages.
- **AOV & Basket Size by Traffic Source**: Analyzed customer acquisition channels. *Insight: Organic Search served as the dominant driver for both registered users and paying customers, though ARPU remained consistent across channels.*
- **Discount Impact & Erosion Analysis**: Evaluated whether discounts actually drive volume. 
  - *Insight*: High Discounts (>$40) accounted for massive volume but eroded $236K in profit margin to generate an average of just 0.5 extra items per order compared to full-price orders.
- **Customer Repeat Purchase Rate**: 
  - *Insight*: Maintained a solid 25.59% repeat order rate. However, almost 75% of buyers purchase once and vanish (many acting as "discount hunters").

### Phase 3: Advanced Behavioral Analytics
- **Cohort Retention Matrix**: Tracked month-over-month repurchase behavior.
  - *Insight*: Retention stabilizes around 14%–20% in Year 2 and 6%–16% in Year 3, indicating a healthy core of loyal, long-term buyers.
- **RFM Customer Segmentation** (Recency, Frequency, Monetary):
  - *Insight*: Identified an "At Risk" segment of 1,154 customers who previously spent high amounts (~$886, rivaling Loyal Customers) but haven't purchased in ~15 months. This is the highest-ROI target for win-back campaigns.

### Phase 4: Web Conversion Funnel (Using Session Logs)
Analyzed step-by-step user journeys to identify friction points:
- **Overall Conversion & Drop-off Ratios**: Reached a strong 11.3% overall conversion rate.
  - *Insight*: The highest friction point is **Payment $\rightarrow$ Purchase** (46.7% drop-off), signaling potential issues with payment options, unexpected fees, or UI friction.
- **Device & Browser Performance**: Evaluated conversion consistency across Chrome, Safari, Desktop, and Mobile.
- **Session Duration & Time-to-Convert**: 
  - *Insight*: Converting users spent ~4m 20s on site, while non-converting users bounced in ~1m, signaling clear intent divergence.

---

## 💡 Key Business Deliverables & Actionable Insights
1. **Revamp the Discount Strategy**: Phase out low-tier ($0–$15) dollar discounts as they don't incentivize larger baskets. Raise the threshold for high-tier discounts (e.g., "Spend $800, Get $50 Off") to protect margins.
2. **Launch Targeted Win-Back Campaigns**: Deploy re-engagement sequences tailored specifically for the high-value "At Risk" RFM segment.
3. **Investigate Checkout Friction**: The 46% drop-off at the final payment step indicates a critical leak in the funnel. The business should audit shipping costs, payment gateways, and trust signals on the checkout page.

