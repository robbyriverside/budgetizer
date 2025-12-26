# Loading Screen

When the loading of transactions is underway, the app should display a loading screen. The loading screen is a new page in the UI.  The user can go back to the landing page, but the loading page will not be reloaded and will continue to load transactions in the background.

The loaded transactions are not saved into the database until the loading is complete and the user has had a chance to review and edit the tags and then save the results of loading.  Instead of saving words, it could use completion suggestions to save the tags.

It is a split screen, with the left as a listing of the tags that are being loaded sorted descending by the number of transactions for each tag. The right side is the listing of transactions for a selected tag on the left.  

During loading and automatic tagging, this screen is up and the counts for each tag are updated as transactions are loaded and tagged. It is always possible to select a tag to see the transactions for that tag, even as the list grows.

I don't care about a progress bar, because the user is never waiting for data to load.  The user can always see the loading screen and the counts for each tag are updated as transactions are loaded and tagged. 

If the user chooses to delete tags, the loading screen should be updated to reflect the new counts for each tag.

---

# Vendor Screen

We can allow the user to edit the db_tags table, to change tags assigned to vendors.  The left side of the screen contains a list of vendors and the tags assigned to them, listed on the line below them with different line spacing.  The list will need to be sorted based on vendor name and allow search for a vendor with completion suggestions.

The rigth side of the screen contains vendors that have the specific tag that is selected on the left side of the screen.  To be clear, the left side allows the entire list of vendors to be searched, and the right side shows the vendors that have the selected tag.  

So on the left side, the user can select a tag listed with one of the vendors, and the right side will show all the vendors that have that tag, including their tags on the next line.  So the list control on both side is the same.  In fact, you can select a tag on the right side and it will change the right side list to show vendors with that tag.

All the tags in either list can drag and drop tags between Vendors.  But this ONLY adds the tag to the destination of the drop.  It does not remove the tag from the source of the drop.  

It is also possible to multi-select vendors in either list and drag and drop a tag to all the selected vendors in either list. The target of the drop is in either one list or the other, so the selection of the target list is the only thing that changes, even if there is a selection in the other list.

---

# Reporting Screen

Asking for a report takes you to the reporting screen.  This screen is a report.  By default, it shows all the budgeted tags and their budgets for the current cycle, with might be multiple periods.  The widget for each tag is a simple bar chart with a line that goes across on the level of the budgeted amount.  Andother line shows the maximum amount spent in any cycle for that tag.  So if the max line is above the level line, then you are over budget.  If the max line is below the level line, then you are under budget.  The bar chart is a simple bar chart with a line that goes across on the level of the budgeted amount.  Keep the graph simple don't add any text or legend, it is simple enough to be clear.

Under the display, list the tag name, level amount, max amount, and the percentage of the budget that was spent.  The list should be sorted by the percentage of the budget that was spent, with the worst performers at the top.  Use background colors to indicate the percentage of the budget that was spent.  Green for under budget, yellow for close to budget, and red for over budget.

All of that is just a starting point InfoGraphic.  The user can move a single tag widget up or down to change the order of the tags.  Or the user can move and entire selection of tags up or down to change the order of the tags.   Right menu on a selection and say to top or to bottom.

The reporting screen is a page and has a back button to return to the dashboard.  But the state of the report is saved when the user leaves the screen.  The user can save the report as a favorite and return to it later.  The user can also share the report with others.  



