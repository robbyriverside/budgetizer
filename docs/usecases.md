# Use Cases

## Staying on budget


The most important use case is staying on budget.  

For example, the credit card transaction in the checking account has a limit that is exceeded.
That is the most common thing to happen.  When that happens, I want to know the source of the over spending by looking a the credit card cashflow that the transaction is linked to and look for overspending on specific credit card transactions.  Like maybe too much restaurant spending or too much gas.

## Cashflow composition

Instead of inventing a new "split transaction", I want to use the cashflow composition to handle multiple transactions in a single cashflow.  This follows the philosophy of removing restrictions instead of adding features.  Because we already have a transaction to sub-cashflow relationship.

There are no split-transactions.  Instead, a withdrawal from cash is a cash transaction and that can be associated with a dynamic cashflow where manual transactions can be added to the cashflow to account for unexpected expenses.

Since a check is also unexpected, but can be treated like it is fixed, which means it does not need a cashflow.
But the expectation is that a check will be for a single category.

## System initialization or onboarding

The basic system activity is loading transactions from the bank and matching them to the cashflows.  
The first time, you setup the system you need to import the bank statements and use it to create the cashflow.  

Transaction data source is 1:1 with cashflow.  Except when the cashflow is manual, like in the cash case.

This follows the approach of loading transactions as a basic user activity.

Create a cashflow from the transactions.
Update a cashflow with transactions.

This is never done, without user supervision.
But with as little manual steps as possible.

An automated cashflow is associated with the bank account.
You can NEVER add transactions manually to an automated cashflow.

A cashflow for cash is manual and associated with a cash transaction from an automated cashflow.
But this cashflow will never have automated transactions.

## Matching reality

Since the system starts with a top-level automated cashflow (checking acount) that will include the current balance in the checking account.  By definition it will match reality, because manual transactions are never added to an automated cashflow.

## Reporting Cashflow Status

Reporting is on a cashflow basis.  The cashflow needs to know about any parent transaction.  Like the credit card payment that shows all the details of the credit card transactions.  The user should only need to make this connection between the cashflow and the parent transaction once.


## Debt Management (Liabilities)

**Gap**: Tracking the balance of long-term debt.
- **Current State**: Mortgage is a "Trigger Transaction".
- **Requirement**: Do we track the *Principal* of the Mortgage/Car Loan reducing over time? Or is it just a cashflow expense?

## Authentication & Security

**Gap**: System access.
- **Requirement**: Login/Auth requirements, especially given financial data is involved.


