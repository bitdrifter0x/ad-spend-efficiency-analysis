-- Platform With Highest Conversion Rate--

SELECT 
  platform,
  SUM(conversions) AS total_conversions,
  SUM(clicks) AS total_clicks,
  ROUND(SUM(conversions) * 1.0 / NULLIF(SUM(clicks), 0), 4) AS conversion_rate
FROM ad_performance_dataset_audit
GROUP BY platform
ORDER BY conversion_rate DESC;

-- Output --
/*
| Platform  | Total Conversions | Total Clicks | Conversion Rate  |
|-----------|-------------------|--------------|------------------|
| TikTok    | 15,503            | 228,582      | 0.0678           |
| Facebook  | 18,188            | 271,491      | 0.0670           |
| Instagram | 15,489            | 231,573      | 0.0669           |
*/


-- Performance Variation by Audience Segment --

SELECT 
  campaign_name,
  audience_segment,
  SUM(clicks) AS total_clicks,
  SUM(conversions) AS total_conversions,
  ROUND(SUM(conversions) / SUM(clicks), 4) AS conversion_rate
FROM 
  ad_performance_dataset_audit
GROUP BY 
  campaign_name, audience_segment
ORDER BY 
  FIELD(audience_segment, 'Gen Z', 'Millennials', 'Gen X');

-- Output --
/*
| Campaign Name     | Audience Segment | Total Clicks | Total Conversions | Conversion Rate|
|------------------|------------------|--------------|-------------------|-----------------|
| Campaign 1       | Gen Z            | 94,006       | 6,296             | 0.0670          |
| Campaign 3       | Gen Z            | 111,175      | 7,472             | 0.0672          |
| Campaign 2       | Gen Z            | 151,951      | 10,708            | 0.0705          |
| Campaign 1       | Millennials      | 70,678       | 4,397             | 0.0622          |
| Campaign 3       | Millennials      | 86,113       | 6,057             | 0.0703          |
| Campaign 2       | Millennials      | 119,090      | 8,188             | 0.0688          |
| Campaign 1       | Gen X            | 24,466       | 1,329             | 0.0543          |
| Campaign 3       | Gen X            | 31,922       | 2,044             | 0.0640          |
| Campaign 2       | Gen X            | 42,245       | 2,689             | 0.0637          |
*/


-- Campaigns With Zero Conversions And High Spend --

WITH ranked_campaigns AS (
  SELECT 
    campaign_name,
    platform,
    audience_segment,
    ad_creative_type,
    spend,
    conversions,
    NTILE(4) OVER (ORDER BY spend DESC) AS spend_quartile
  FROM ad_performance_dataset_audit
)
SELECT 
  campaign_name,
  platform,
  audience_segment,
  ad_creative_type,
  spend,
  conversions
FROM ranked_campaigns
WHERE conversions = 0
  AND spend_quartile = 1
ORDER BY spend DESC;

-- Output --
/*
/*
| campaign_name | platform  | audience_segment | ad_creative_type | spend | conversions |
|---------------|-----------|------------------|------------------|-------|-------------|
| Campaign 1    | TikTok    | Gen Z            | Image            |425.97 | 0           |
| Campaign 1    | Facebook  | Millennials      | Image            |393.25 | 0           |
| Campaign 1    | Tiktok    | Gen Z            | Image            |362.31 | 0           |
| Campaign 1    | Facebook  | Millennials      | Image            |343.36 | 0           |
| Campaign 1    | Instagram | Gen Z            | Image            |325.45 | 0           |
+ 146 more...
*/


-- Campaigns With ROAS Below Average ROAS And Thier Percentage Spend --

WITH combo_performance AS (
  SELECT 
    campaign_name,
    platform,
    audience_segment,
    ad_creative_type,
    SUM(spend) AS total_spend,
    SUM(revenue) AS total_revenue,
    ROUND(SUM(revenue) / NULLIF(SUM(spend), 0), 2) AS roas
  FROM ad_performance_dataset_audit
  GROUP BY campaign_name, platform, audience_segment, ad_creative_type
),

average_roas_cte AS (
  SELECT AVG(roas) AS avg_roas
  FROM combo_performance
),

total_spend_cte AS (
  SELECT SUM(total_spend) AS grand_total_spend
  FROM combo_performance
)

SELECT 
  cp.campaign_name,
  cp.platform,
  cp.audience_segment,
  cp.ad_creative_type,
  ROUND(cp.total_spend * 100.0 / ts.grand_total_spend, 2) AS spend_share_percent,
  cp.roas AS underperforming_roas
FROM combo_performance cp
JOIN average_roas_cte ar ON TRUE
JOIN total_spend_cte ts ON TRUE
WHERE cp.roas < ar.avg_roas
ORDER BY spend_share_percent DESC;

-- Output --
/*
| Campaign        | Platform  | Audience Segment | Creative Type | Spend Share % | Underperforming ROAS |
|-----------------|-----------|------------------|----------------|----------------|------------------------|
| Campaign 1      | TikTok    | Gen Z            | Image          | 3.65           | 0.40                   |
| Campaign 1      | TikTok    | Gen Z            | Carousel       | 3.63           | 1.49                   |
| Campaign 2      | TikTok    | Gen Z            | Image          | 3.30           | 1.04                   |
| Campaign 2      | TikTok    | Gen Z            | Carousel       | 3.23           | 2.86                   |
| Campaign 1      | Facebook  | Millennials      | Carousel       | 2.88           | 1.45                   |
| Campaign 1      | Facebook  | Millennials      | Image          | 2.80           | 0.40                   |
| Campaign 2      | Facebook  | Millennials      | Image          | 2.64           | 0.88                   |
| Campaign 2      | Facebook  | Millennials      | Carousel       | 2.61           | 2.66                   |
+ 47 more...
*/


-- Audience Segment Contribution To Total Revenue --

WITH segment_performance AS (
  SELECT 
    audience_segment,
    SUM(spend) AS total_spend,
    SUM(revenue) AS total_revenue
  FROM ad_performance_dataset_audit
  GROUP BY audience_segment
),
totals AS (
  SELECT 
    SUM(spend) AS grand_total_spend,
    SUM(revenue) AS grand_total_revenue
  FROM ad_performance_dataset_audit
)

SELECT 
  sp.audience_segment,
  ROUND(sp.total_revenue * 100.0 / t.grand_total_revenue, 2) AS revenue_share_percent,
  ROUND(sp.total_spend * 100.0 / t.grand_total_spend, 2) AS spend_share_percent,
  ROUND(sp.total_revenue / NULLIF(sp.total_spend, 0), 2) AS roas
FROM segment_performance sp
JOIN totals t ON TRUE
ORDER BY revenue_share_percent DESC;

-- Output --
/*
| Audience Segment | Revenue Share % | Spend Share % | ROAS |
|------------------|------------------|----------------|------|
| Gen Z            | 49.78            | 48.80          | 3.92 |
| Millennials      | 37.85            | 37.43          | 3.88 |
| Gen X            | 12.36            | 13.77          | 3.45 |
*/








