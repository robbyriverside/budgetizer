# Screen Corrections

## Dashboard

Remove the Alerts button from the top of the screen.

Remove the tools button from the top of the screen.
Replace it with the Vendor button.


## Loading Screen

On the left side of the screen, black numbers on a red background is too hard to read. I don't like the red circles either.  Make them something more clear and crisp, like an LED.

On the right side of the screen, the tags are great, but they need a way to delete them.  Like a little X button.   This process also needs an Undo feature that will undo tag deletions.

## Reporting Screen

The reporting screen, needs to contain a way to add new budgets.  

Tags are also known by the sum of the spending on the tagged transactions.  This is a good way to see how much you are spending on each tag.  The bottom of the Reporting screen is a list of spending by tag.  By dragging these tags up to the Reporting area, it will open a dialog to set the budget for that tag.  If you cancel, the tag will be returned to the bottom of the screen.
NOTE: the tags in the lower section of the screen are not editable.  They are just a list of the spending by tag, but color the tags that are already budgeted.  Remember, what's in the reporting area can change.  So there must be a dropdown list at the top with all the known reports, so the view can switch between reports.  The budget report is the default and shows all the tags.  IF the user edits the default report, the save button appears.  But the save button brings up a dialog to ask the Report name.  If you use an existing report name, it will ask if you want to overwrite it.  If you cancel, the report will be returned to the default report.


It will not let the user overwrite the 'budget' default report.  So when you save the report, if it is the budget report, then offer the name 'budget' with a date at the end.  If they change it back to budget, then the save will fail and explain why.

Reporting screen is a split screen, with the top half being the reporting area and the bottom half being the list of tags.  The reporting area can be dragged up and down to change the order of the tags. The list of tags order can be changed.  Listed alphabetically, but the default is based on spending in the current cycle in descending order.

The screen also has a header area with the name of the report and the save report button.

## Vendors Screen

The vendor screen is great.  But I need to be able to delete tags using a small delete X button.  

For each change to the tags, like adding or deleting, create a brief log entry for each change.  Then provide a way to selectively undo the changes.  So instead of calling it undo.  Add a button called changes, which brings up a dialog to select which changes to remove from the changes list. This also lets the user see that the report has unsaved changes, because otherwise the changes button would be seen in an inactive state.

So after you make a change, but don't save it,when you page away to another screen, and come back to Vendor screen, the changes button should be seen in an active state and they would be able to list the changes.  So it is important that the changes list uses clear language for each change.  Of course the undo dialog should let the user delete changes in the list, and an undo button that reverses the changes to the list.