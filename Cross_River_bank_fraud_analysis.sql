 /*     Fraud Detection and Risk Analysis in Cross River Bank     */
 
 /* Analysis 01: High Risk customer :
 10 customer with lowest credit score and high risk category */
 
Select customer_id, credit_score, risk_category from customer_table where risk_category ="High"
order by credit_score 
asc limit 10;

/*Analysis 02 :  Loan Purpose Insights:
 Determine the most popular loan purposes and
their associated revenues to align financial products with customer demands. */

  select loan_purpose, count(*) as loan_purpose_count, avg(loan_amount) from loan_table group by loan_purpose
  order by loan_purpose_count desc limit 1;
  
  
 /*Analysis 03: High-Value Transactions:
  Detect transactions that exceed 30% of their respective loan amounts 
 to flag potential fraudulent activities. */
 
  select t.transaction_id, l.loan_amount, t.transaction_amount from transaction_table as t 
  join loan_table as l on t.customer_id= l.customer_id
  where t.transaction_amount> 0.30* l.loan_amount;
  
  /* Analysis 04 : Missed EMI Count: 
  Analyze the number of missed EMIs per loan to identify loans at risk of default 
  and suggest intervention strategies. */
  
  select loan_id, count(*) as Missed_EMI_Count  from transaction_table 
  where remarks = "Payment missed." group by loan_id;
  
  
  /* Analysis 05: Regional Loan Distribution: 
  Examine the geographical distribution of loan disbursements to assess regional trends 
  and business opportunities. */
  
  /* Analysis 06 : Loyal Customers: 
  List customers who have been associated with Cross River Bank for 
  over five years and evaluate their loan activity to design loyalty programs. */
  
  select c.customer_id, c.name, l.loan_id, l.loan_amount, l.loan_status from customer_table as c
  join loan_table as l on c.customer_id = l.customer_id 
  where c.customer_since <= DATE_SUB(CURDATE(), INTERVAL 5 YEAR);
  
  
  /* Analysis 07 : Age-Based Loan Analysis: Analyze loan amounts disbursed to customers of different age groups
  to design targeted financial products. */
  
  SELECT
  CASE
    WHEN c.age BETWEEN 18 AND 25 THEN '18-25'
    WHEN c.age BETWEEN 26 AND 35 THEN '26-35'
    WHEN c.age BETWEEN 36 AND 45 THEN '36-45'
    WHEN c.age BETWEEN 46 AND 60 THEN '46-60'
    ELSE '60+'
  END AS age_group,
  COUNT(l.loan_id) AS total_loans,
  SUM(l.loan_amount) AS total_loan_amount,
  AVG(l.loan_amount) AS average_loan_amount
FROM customer_table c
JOIN loan_table l ON c.customer_id = l.customer_id
GROUP BY age_group
ORDER BY age_group;
-- - using windows function
WITH customer_age_group AS (
  SELECT customer_id, 
         CASE
           WHEN age BETWEEN 18 AND 25 THEN '18-25'
           WHEN age BETWEEN 26 AND 35 THEN '26-35'
           WHEN age BETWEEN 36 AND 45 THEN '36-45'
           WHEN age BETWEEN 46 AND 60 THEN '46-60'
           ELSE '60+'
         END AS age_group
  FROM customer_table
)
SELECT 
  ag.age_group,
  COUNT(l.loan_id) AS total_loans,
  SUM(l.loan_amount) AS total_loan_amount,
  AVG(l.loan_amount) AS average_loan_amount
FROM customer_age_group ag
JOIN loan_table l ON ag.customer_id = l.customer_id
GROUP BY ag.age_group
ORDER BY ag.age_group;

/* Analysis 08: High-Performing Loans:
 Identify loans with excellent repayment histories to 
refine lending policies and highlight successful products. */
SELECT 
  l.loan_id,
  l.loan_amount,
  l.loan_purpose,
  SUM(t.transaction_amount) AS total_paid,
  ROUND(SUM(t.transaction_amount) / l.loan_amount, 2) AS repayment_ratio,
  COUNT(t.transaction_id) AS emi_count
FROM 
  loan_table l
JOIN 
  transaction_table t ON l.loan_id = t.loan_id
WHERE 
  t.transaction_type = 'EMI Payment'
GROUP BY 
  l.loan_id, l.loan_amount, l.loan_purpose
HAVING 
  repayment_ratio >= 0.9
ORDER BY 
  repayment_ratio DESC;

-- also to check high performing loan we can filter customer with very good credit score where EMI is paid on time
SELECT 
  l.loan_id,
  c.customer_id,
  c.credit_score,
  COUNT(t.transaction_id) AS emi_paid
FROM 
  loan_table as l
JOIN 
  customer_table as c ON l.customer_id = c.customer_id
JOIN 
  transaction_table t ON l.loan_id = t.loan_id
WHERE t.transaction_type = 'EMI Payment' AND c.credit_score >= 750
GROUP BY 
  l.loan_id, c.customer_id, c.credit_score;

/* Seasonal Transaction Trends: Examine transaction patterns 
over years and months to identify seasonal trends in loan repayments. */
SELECT 
  YEAR(transaction_date) AS year,
  MONTHNAME(transaction_date) AS month,
  COUNT(*) AS total_emi_count,
  SUM(transaction_amount) AS total_emi_amount
FROM transaction_table WHERE transaction_type = 'EMI Payment'
GROUP BY 
  year, MONTH(transaction_date), MONTHNAME(transaction_date)
ORDER BY 
  year, MONTH(transaction_date);
  
  /* Analysis 09:Repayment History Analysis: 
  Rank loans by repayment performance using window functions. */
SELECT loan_id, loan_amount, total_paid, repayment_ratio,
  RANK() OVER (ORDER BY repayment_ratio DESC) AS repayment_rank
FROM ( SELECT l.loan_id, l.loan_amount,
        SUM(t.transaction_amount) AS total_paid, 
        SUM(t.transaction_amount / l.loan_amount) AS repayment_ratio
    FROM loan_table as l 
    JOIN transaction_table as t ON l.loan_id = t.loan_id
    WHERE t.transaction_type = 'EMI Payment'
    GROUP BY l.loan_id, l.loan_amount
) AS loan_summary;

/* Analysis: Credit Score vs. Loan Amount: 
Compare average loan amounts for different credit score ranges. */
SELECT CASE 
    WHEN c.credit_score < 600 THEN 'Poor (300–599)'
    WHEN c.credit_score BETWEEN 600 AND 699 THEN 'Fair (600–699)'
    WHEN c.credit_score BETWEEN 700 AND 749 THEN 'Good (700–749)'
    WHEN c.credit_score BETWEEN 750 AND 799 THEN 'Very Good (750–799)'
    ELSE 'Excellent (800+)' END AS credit_score_range,

  COUNT(l.loan_id) AS total_loans,
  ROUND(AVG(l.loan_amount), 2) AS average_loan_amount,
  SUM(l.loan_amount) AS total_loan_disbursed
FROM customer_table c JOIN loan_table l ON c.customer_id = l.customer_id
GROUP BY credit_score_range ORDER BY credit_score_range;

/* Analysis 09: Early Repayment Patterns: 
Detect loans with frequent early repayments and their impact on revenue. */
-- there is not enough data where we could calculate revenue but we can get total transaction amount for each loan

select loan_id, count(*) as frequent_early_payment from transaction_table 
where transaction_type = "Prepayment" group by loan_id having frequent_early_payment >2;




        
         








