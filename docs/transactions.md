# Transactions

Trasactions are read from banking sources using an API to pull the data.  

Each cashflow has a distinct source for transactions.  
A big step in writing this software is using a service to pull the data from the bank.  

So each cashflow is configured with a source of transactions these are compared to transactions from previous cycles to validate: check expected fixed transactions and check limits on variable transactions.

I don't ever want to enter a transaction manually.  But transactions are distinct and can be matched using amount, date, description, and tags.  So if a new unique transaction is found, it won't match any previous transactions.  The system uses "Lazy AI" matching: it attempts to match using existing regex rules derived from previous ID tagging. If no match is found, AI evaluates the description to identify the vendor/business and assigns appropriate tags.  These tags are then used to update the matching rules for future transactions.

The important requirement here is to avoid entering transactions manually and to match transaction content automatically.  

It's important to note that onece a transaction is identified as fixed, all the system does is check the amount and date.  Date can vary by day of the month, but amount should be the same.  

Variable transactions are controlled by budgets set on Tags.  The user sets a limit on a specific Tag (e.g., "Groceries").  The system calculates the remaining amount based on the limit and the total amount of transactions with that Tag.  Limits are the primary way to budget.  This allows the cashflow to be monitored based on fixed costs and variable Tag limits.  

So each cashflow can calculate if it is on budget or over budget.  

