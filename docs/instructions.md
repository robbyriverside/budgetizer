# Budgetizer

I need a simple budgeting app that can track my expenses and income with the help of AI.

## Features

- Track income and expenses
- Categorize expenses
- Generate reports
- Set budgets
- AI-powered expense categorization

## Brainstorm Design

I am dumping out all the things I know about the design of the app.
This is for you to create a cohesive design that you can implement.

---

While the system needs a calendar for reference; recorded dates, etc.

I don't want a budget based on a monthly or yearly budget.

My budget is hierarchical cycles of time periods based on the beginning and end of the cycle and not any monthly boundaries, like the first of the month.  

Each node is a cycle of items which are either income or expenses.  A cycle has an end item which is the last item in the cycle.  Usually, bills have a date they are paid.  But I care about the cycle of the bill, not the date it is paid.

Income into the checking account is the top node, because all income and expenses are paid from the checking account.  History within the cycle defines it's pattern and that pattern can be used to predict if the cycle will be within budget.

Within a cycle is another node, because that node is composed of another cycle.
For example, a credit card is a node that is composed of other expenses.

The tricky part is that the credit card expenses are paid in the next cycle.
In the current budget cycle, we pay the previous cycle's credit card expenses.

So the current cycles credit card expenses will calculate the next cycles credit card payment.
This is important because the credit card allows me to postpone bills until next month.

One credit card is for general use.  All the spending of the family takes place on this card.
Another credit card is for subscriptions.  Subscriptions are a set of fixed expenses that are usually the cycle total will be the same amount.  The third credit card is for extra budget items, like gifts or home projects, etc.  This is managed differently that the other two cards.  I could just pay it off every month, but my credit rating wants me to borrow money and pay on it for a while, and then pay it off.  This tell creditors that I can pay my bills and manage my money.

Finally, we have savings, which is is collected from the checking account on regular intervals.  This is another cycle of items.  The difference is that it collects money from the checking account and puts it into savings.  The savings however is composed of multiple purposes.  Like saving $500 a month for unexpected expenses and regular investment savings.

So savings is like collecting buckets of money for different purposes.

I use the mortgage as the last expense of the checking account cycle.
So the new cycle starts the next expense after the mortgage.

Within a credit card are budgets, for different purposes; like groceries, gas, etc.
The cycle for a credit card is based on when the card switches to a new payment.

I need budgeting to be weekly or monthly expenses.  
For example, weekly for groceries, but monthly for gas.

I need AI to help me categorize expenses, but also keep track of previous categorizations.
On any date, I can print a report that gives me a summary; including it projects how much the general expenses credit card will be for next cycle, identifies over spending that my require money from savings.   It shows which budgets are going over for this cycle.  There is no going under budget, because the target is only a marker for notifications.  No corrective action is automatically taken.  For example, over spending on dining out will mean that the next cycle's general expenses credit card will be higher.  This can be projected and the report can show it.

This is where I want AI to automate my budgeting.   I do not want to use the envelope system or anything like it.  The general card will always show overspending and there may be unexpected expenses. 

Bottom line, the total income should be greater than or equal to the total expenses.  If it is not then it must be pulled from savings.  But there might also be a "buffer amount" sleeping inside the checking account.  Checking account needs to keep a positive balance.  So when the mortgage gets paid, what is left over is the buffer amount.  If the buffer gets over a limit then it can be added to savings.   So savings is the overflow, negative or positive.  But we always want to keep a positive balance in the checking account.

The nodes are a major focus of the UI.  One focus is when I am looking at budgets on the general card.  Another focus is when I am looking at the checking account and cash flow in and out.  Another view is to look at the savings within each purpose.  

The money that leaves savings goes to the checking account.  IT might be for buying investments or paying a large expense.  

### Abstraction Phase



