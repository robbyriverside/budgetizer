# Banking API Selection

## Comparison Grid

| Feature | **Plaid** | **Yodlee** | **Teller** | **Nordigen** (GoCardless) |
| :--- | :--- | :--- | :--- | :--- |
| **Founded** | 2012 | 1999 | 2014 | 2015 |
| **Popularity** | **High**. Market Leader in US. | **High**. Enterprise Standard. | **Medium**. Developer favorite. | **High** (Europe). |
| **Price** | Free for Dev (<100 Items).<br>Scale: Pay-as-you-go. | Expensive Enterprise.<br>Startup Tier available. | **Free** for Dev.<br>Paid tiers reasonable. | **Free** (Basic API).<br>Premium add-ons. |
| **Coverage** | Excellent (US/CA/EU). | Global / Extensive. | Good (US Major Banks). | Excellent (Europe). |
| **Dev Ex** | Excellent SDKs & Docs. | Complex / Legacy. | Modern / Simple. | Good. |

## Detailed Analysis

### 1. Plaid
-   **Pros**: The "Standard". If a bank works with anything, it works with Plaid. The "Development" environment is **Free** for up to 100 live Items (connections), which is likely sufficient for personal use or V1 testing.
-   **Cons**: Moving to "Production" involves a vetting process and potentially higher costs if you exceed the free tier.

### 2. Yodlee
-   **Pros**: Historic data depth.
-   **Cons**: Documentation and integration are notoriously difficult compared to modern competitors. Pricing is opaque and sales-driven.

### 3. Teller
-   **Pros**: Real-time APIs (reverse engineered private APIs in some cases). Very fast. Free tier is generous.
-   **Cons**: Smaller coverage map than Plaid. Less "stable" official partnerships compared to Plaid's open banking initiatives.

### 4. Nordigen / GoCardless
-   **Pros**: Free.
-   **Cons**: Primarily European focus. Dealing with US/Global banks is less robust than Plaid.

## Recommendation

**Winner: Plaid (Development Tier)**

**Reasoning**:
1.  **Cost**: The Development tier is free for up to 100 connections. This covers V1, V2, and V3 development without a credit card swipe.
2.  **Popularity & Stability**: It has the best Flutter SDK support (`plaid_flutter`) and documentation.
3.  **Future Proofing**: If the app grows, Plaid scales (albeit at a cost).

**Process**:
1.  Register for Plaid Dashboard.
2.  Request "Development" access (instant approval usually).
3.  Use the `Sandbox` environment for our V1 Mock testing (Plaid provides excellent Sandbox data, so we might not even need to write our own Mock Logic if we just wrap Plaid's Sandbox!).

**Alternative**: If you are based in Europe, use **Nordigen**. If you strictly hate Plaid, **Teller** is a solid backup for US banks.
