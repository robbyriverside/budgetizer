# Tagging

Tags are applied to transactions based on an AI evaluation of the business named in the description of the transaction.

This is AI's most important job.  It is the job that defines the user experience.  Because the user does not have to worry about tags, AI does not have to worry about understanding tags defined by the user.  

When new transactions are downloaded, they are evaluated and tagged based on the AI evaluation.

Tags used in the software are ALL defined by AI.  The user can only remove tags from a transaction, not add them.  The goal is to have a consistent set of tags for all the businesses, so that the user does not have to worry about them.  AI develops the set of tags incrementally over time.  

## Company tagging

When assigning tags to a transaction, AI searches the web and determines what kinds of things the business sells, then it adds all those tags to the transaction.

For example, Target sells clothes, home goods, and food.  So if a transaction is for Target, it will be tagged with clothes, home goods, and food.  For some large stores like Target, it will also add tags for the store name, like Target and Walmart.  

The user evaluates these assigned tags and can remove them, only.  So if you bought food at Target, it will be tagged with clothes, home goods, and food.  If you remove the clothes tag and home goods tag, it means that transaction was only for food.

Transactions only store the tags that were removed.  The total tags for the transaction are defined by the company found when the AI read the description of the transaction.  So a transaction will know which company it is for, and the tags that were removed.  
Compton's Market is a grocery store, so the bank would send it with MCC 5411 ("Grocery Stores").

Example:
```
Here is how the system should handle an unknown store without adding a new entry to 
db_tags.json
:

Transaction Arrives:
Description: "COMPTONS MARKET SACRAMENTO CA"
MCC: 5411
System Lookup:
It looks up MCC 5411 in 
db_tags.json
.
It finds the tag: Groceries (or "Grocery Stores").
Auto-Tagging:
Vendor Tag: "Comptons Market" (Extracted dynamically from the string).
Service Tag: "Groceries" (Mapped from MCC 5411).
Market Tag: "Groceries" (Parent category).
```

## Special Tags

The system uses these tags for more than just user reporting.  For example, would have tags for Netflix that includes subscription, streaming, and movies.  Subscriptions are fixed, streaming and movies are variable.  A specific bill from Netflix will be tagged with subscription, streaming, and movies.  But the user might remove anything but subscription if the transaction is the subscription bill. 

A streaming tag is a fixed cost, so all the system does with that is verify that the amount did not change from last cycle.  IF the user bought a movie from Netflix, it will be tagged with movies which indicates a variable cost.  The system offers all the tags associated with that vendor (aka company) and the user removes some of them.

## Tag Storage

As the AI encounters new companies, it will create tags for the company and store them in the database.  The matching uses regular expressions to match the tags to the transaction description.  But if no match is found, AI is called to evaluate the transaction description and determine if this is a new store.  If this store already exists, then the regular expressions are updated to match the new description.   IF the store is new, then the AI will create the tags and store them in the database.

I call this Lazy AI matching.  Because the gradually AI finds a way to make it so that the regular expressions are good enough to perform the match.  So the AI does not want to be called, hence lazy.  It tries to use a function to access a company it already knows, first, and then calls AI if it cannot find a match.

A more advanced way if for the AI to write a function to match the tags to the transaction description.  The problem is that AI has too much flexibility and might do harm.  But by limiting the AI to a updating regular expressions, it can't do any harm.  

## Tagged Budgets

Tags represent categories of expenses.  So the budget is based on a collection of tags and a specific type of format for each tag.  At any point, the user can add or change a budget for a tag.  The user can say the limit and frequency of the budget.  For example, the food tag, might have a budget of $100 per every seven days.  But the streaming tag, is monthly and tracks how much money the family spends on streaming services.  

Weekly tags are parts of a month, so it can be any number of days.  For example, we might divide the month evenly into four weeks, which would be equal subdivisions of a specific amount days in a month.  The system is smart about defining these divisions, if there are a few days left over, it simply adds them to the last week.  So we need a good UI for defining these divisions.  Remember that a month, isn't a month, it's the length of the cycle (or cashflow).  So dividing it by equal parts removes the calendar limitations.  

I am using month and week, because it is well understood by the user.  But we need to change the terminology for cycle length and subdivision length, those are correct, but not user friendly.

The budget storage is a table of tags that have an associated budget.  The budget is a limit and a frequency.  The limit is the amount of money that should be spent on that tag.  The frequency is the length of time that the limit is valid for.  For example, the food tag might have a limit of $100 and a frequency of every seven days.  This means that the user can spend $100 on food every seven days.  If the user spends $100 on food in one week, they can spend $100 on food in the next week.  If the user spends $100 on food in one week, they cannot spend $100 on food in the next week. 

Budgets are a way to tell the system which tags are important for the user.  The user can set a budget for a tag and the system will track the amount of money spent on that tag and compare it to the budget.  If the user spends more money on a tag than the budget, the system will highlight the tag in red and place it at the top of the report.  

## Tagged Reports

In the context of a cashflow, the tags are collected by follwing the hierarchy of cashflows and gathering the tags from the leaf transactions.  Leaf transactions have no sub-cashflow associated with them.  So even if there are tags of a higher cashflow, the tags are only collected from the leaf transactions.  

All the reports are based on a collection of tags and any associated budget for that tag.  For most tags, there is no limit and no frequency, so the report simply shows the total amount spent on that tag.  But for tags that have a limit and frequency, the report shows the total amount spent on that tag and the remaining amount based on the limit.  The tags that have an exceeded budget are highlighted in red and placed at the top of the report.  

The user can request a report with hides the non-budged tags and only shows the tags that have a budget.  Or they could request a report that shows only the tags that have exceeded their budget.  So the reporting request from the user is very flexible.

## Use of Tags

Everywhere a tag is shown in the UI, transactions, reports, budgets, is an opportunity to interact with a tag.  Of course, you can remove the tag from the specific transaction.  But you can also select the tag and assign, change or review it's budget.  

## Smart tagging

When a new transaction is added to the cashflow, the system will review the previous cycle to find if there are any transactions with the same description.  If there are, the system will apply the previous tags to the new transaction.  This smart tagging is trying to remove the same tags that the user chose.  Or at least, the UI offers the same tags from the previous cycle and the user can simply approach the tag selection, or use all the tags from that vendor.  

## Terminology

Transaction description leads to vendor (not company) identification.  

Tags may have different purposes, but they are all treated the same way.  

Budgeting or limit tracking are the main budgeting features of this software.  


