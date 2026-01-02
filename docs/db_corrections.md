# Temporary DB

Instead of trying to simply allows the MockBankService to use the database, we need to introduce a temporary database (just SQL lite stored in a temporary folder) for the mock service.  The mock service allows a reset command that will clear the database and allow us to test the persistence of the data.  IT is also possible that the temp folder had been deleted, which is the same as a reset.

---
# Statements DB

Sometimes to have a valid test case, we need to load multiple statements into the database.  These could be from prior months, or from different accounts.  These statement databases are still providing and SQL database, but they have a permanent backup of all the statements loaded into the database.  So this database starts with a collection of files, and includes commands to load the statements into the database.

The additional use-case for this statements DB is duplication of transactions.  The statement may only have a subset of the transactions for that month.  For example, the user loads the most recent transactions of the current month and some of them are already in the database, so really you are only loading what is new.  This allows the user to simply load the most recent transactions and the system keeps track of what it has loaded into the database.  

The statements DB is a load file kind of interface.  The files are loaded and collected into a folder and the inventory of files and when they were added and how many transactions it contains and the range of dates this statement covers.  The user loads whever files named in any way, and the system reads the contents and converts them into a standardized YAML format, that can be loaded without having to re-read the statement file using AI.

The statements DB is a named resource.  The user can name the statements DB, and the system will create a folder for it.  The user can also select an existing folder to use as the statements DB.  The statements DB is a permanent resource, and the user can delete it if they want to start over.

---
# Loading Screen changes

In the header of the Loading Screen there should be a dropdown list of the types of data sources that are available.  Things like Mock (or generated), Plaid (sandbox or production), or Statements db. When the selection is made, a dialog should open to allow the user to configure the data source based on the type of source selected.

So a mock selection would open a dialog to allow the user to select the mock data to load, it might offer a seed value to apply to the random transaction generator -- this allows the user to conjure repeatable sets of transactions for testing.  

A plaid selection would open a dialog to allow the user to select the plaid source account to load including authentication (ie bank login).  

A statements db selection would open a dialog to allow the user to select the statements db to load.  It might also offer to initialize a new statements db, from an existing one, so that so we can create tests that load different collections of statements.

For example, the test starts by creating a new statements db from an existing one, and then loads a new statement into it.  The test then loads a collection of transactions into the database and runs a report to compare the transactions to the statements.  The test then runs a report to compare the transactions to the statements.

The loading screen also allows selection of a transaction db.  This is where transactions are loaded and where they are saved, from any other transaction source.  But generally, there is only permanent and temporary transaction dbs.  Temporary DBs are an advanced feature, so it defaults to permanent.  But it is also possible to start a temporary DB by loading the contents of the permanent DB into a temporary DB.  This is for testing and debugging purposes.

The result is that there is ALWAYS a transaction DB to save even Mock (automated generated) transactions.  The important part, is keeping a log of all the db loads and the steps used to create it, like starting with one db and then loading new transactions, the dates and sources of the data are part of the db load log.

