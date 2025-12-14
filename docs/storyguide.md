# Story Guide

Before we write any code, we are going to walk through many user stories
to optimize the user experience.  The goal is for the Budgetizer app to do all the work.  
Very little user input is required, other than focusing the meaning of every transaction.

Every transactions starts with a broad perspective of what a transaction means. Because the transactions starts with every market and service the vendor provides. If the user never wants to touch the transaction tags, the app will still provide value. It just means that the app does not know which product or service the transaction identifies.

If the user wants to make the transactions more specific the user can remove tags that don't fit.  This allows the app to provide finer and more accurate control of your spending.

Of course, the user can review every transaction in a cashflow cycle.  The cashflow is defined by a source of transactions.  The checking account cashflow, savings cashflow, credit card cashflow, etc.  The cashflow has a starting balance and a list of transactions.  The cashflow cycle by when it ends.  The end event might be when the account closes that billing cycle, or a specific transaction that happens at the end of the cycle. 

The Budgetizer's job is to find things you don't want. So everytime you load transactions, the app will find things you don't want.  Like fixed expenses that are increasing or becoming variable.  Or variable expenses that are getting too high, like the credit card bill at the end of the month.  It is always aware of previous cycles and if the transactions are changing in the wrong way, it will alert you.

But the best thing the Budgetizer does is write intelligent reports.  This is based on managing the limits of tags on transactions.  For example, the total of the groceries tag changes every week, so it is called a variable expense.  These are the most important transactions, because they will tell you where your spending is higher than you want.

You can define a limit for the Groceries tag.  The limit is simply and alert level.  Budgetizer doesn't fix it for you, it just allows you to see if spending meets your expectations or intentions.  Even if you exceed that limit every month, Budgetizer gives you how that trend is changing.  Are you getting better at managing your groceries, or worse?

If you think you only need to track Groceries, because you think that's the key to your over spending, then you can only assign that limit to Groceries and that's all Budgetizer will provide.  But eventually you will discover that tracking multiple variable tags, will help you find all the leaks where your money is going.  You will find that you are not tracking enough variable tags, and you will be amazed at how easy it is to track them.  

Simply by assigning these limits to variable tags, you will create a budget.  A flexible budget that you can adjust over and over as you discover new leaks in your spending.  The budgetizer will report on your budgets, that's it's job.  Reports are about the limits on variable expenses, and how they are changing.  Simply by choosing different collections of your budgets, you can control the scope of the report.  

Transactions can also be the link between cashflows.  For example, savings account withdrawls go into the checking account as a transaction and deposits into the savings account as a transaction in the checking account.  Those cross cashflow transactions allow the user to navigate between cashflows.  But there is also a dropdown list of cashflows at the top, where the current cashflow title is shown.  

## User Story

Write userstory.md, which tells the story of Teddy, who is trying to manage his cash flow.  Teddy starts from nothing but an empty workspace.  First, he needs to load data from his accounts.  Once Teddy has loaded several months of transactions from his checking and savings accounts, as well as any credit cards he has, he is amazed at how easy it is.  Budgetizer learns his transactions, and Teddy has a chance to remove any tags that don't fit.  For example, he removes every market tag except groceries to show what he actually purchased.  

Teddy starts by building budgets from the previous month's transactions.  Budgetizer begins with how you actually spend money and lets you gradually set limits on expenses that are getting too high.  

The newly read transactions are the starting point for building a budget.  First, find out what you spent on Groceries, for example, last month.  Open the cashflow cycle and click on the groceries tag, in either the transaction list or the transaction inspector.  Immediately, you will see the income and expenses for all the groceries transactions.  You can also ask for this report to include previous cashflow cycles to show the trend of groceries expenses over time.  Based on the trend, you can set a limit for the groceries tag and see how the past cycles compare to the current cycle.

At this point, budgeting is up to you.  Change the budget, provide more alerts by increasing the frequency.  A budget has a limit and a frequency, which is defined by days.  If you want it weekly, just say seven days.  But the week will start on the first transaction in the cashflow cycle.  The calendar just confuses things because often cycles don't start or end on the first day of the month.  The calendar dates only need to tell the user when this transaction occurred.  

One nuance of defining the budget frequency is handleing uneven cycles.  Where the frequency does not exactly divide the cashflow cycle.  For example, if the cashflow cycle is 31 days and the budget frequency is 7 days, then there are an uneven number of days in each report.  In that case, the budgetizer will prorate the budget limit to account for the uneven number of days in each reporting period.  Every report has an associated reporting period in days.

This is important because if you have a cashflow that starts on the 3rd of the month, it will also end on the 2nd of the next month.  Since, months vary in length, then the prorate reporting period adjustment must be handled depending on the number of days in a month.



