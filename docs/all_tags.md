# All Tags

**Consistency Rule**: We must use a consistent set of tags to prevent duplicates (e.g., use "Coffee" but NOT "Coffee Shop"). AI should assign existing tags whenever possible.

## Vendor Tags
These tags are defined by looking at the merchant name in the transaction. They are automatically applied as the first tag.

- Amazon
- Target
- Shell
- Starbucks
- Uber
- Whole Foods
- Netflix
- Chevron
- Safeway

## System Tags
These are tags used by the system to manage the budgeting logic, status, or transaction nature.

- Subscription - fixed recurring expense
- Fixed - fixed non-recurring expense
- Variable - variable non-recurring expense
- Recurring - variable recurring expense
- Income - Positive amount added to the budget
- Transfer - transfer between accounts
- Pending - pending transaction

## Vendor Markets (Broad Categories)
These represent the broad market sector of a vendor. A vendor often belongs to one primary market, but may span multiple.

- **Groceries**: Supermarkets, bakers, butchers (e.g., Whole Foods, Safeway).
- **Dining**: Restaurants, fast food, bars (e.g., McDonald's).
- **Home Goods**: Furniture, decor, hardware (e.g., Home Depot, IKEA).
- **Clothing**: Apparel, shoes, accessories (e.g., GAP, Nike).
- **Gas**: Fuel stations (e.g., Shell, Chevron).
- **Auto Maintenance**: Repairs, parts, service (e.g., Jiffy Lube).
- **Transport**: Rideshare, public transit, taxis (e.g., Uber, Lyft).
- **Housing**: Rent, mortgage, repairs (e.g., specific property management).
- **Entertainment**: Fun, hobbies, media (e.g., Netflix, Cinema).
- **Utilities**: Electricity, water, internet (e.g., PGE, Comcast).
- **Health**: Medical, dental, pharmacy (e.g., Walgreens, Kaiser).
- **Travel**: Flights, hotels, car rentals (e.g., Airbnb, Delta).
- **Education**: Tuition, courses, books.

## Specific Services / Products (Sub-categories)
These tags represent specific types of goods or services provided by a vendor. These often overlap with Markets (e.g., Streaming is a specific type of Entertainment).

- **Ride Services**: Taxis, Uber, Lyft.
- **Oil Change**: Preventative maintenance (e.g., Jiffy Lube).
- **Auto Repair**: Mechanical repairs and fixes (e.g., Midas, Mechanic).

- **Coffee**: Coffee shops, cafes.
- **Fast Food**: Quick service dining.
- **Streaming**: Digital media subscriptions (Netflix, Spotify).
- **Internet**: ISP services (subset of Utilities).
- **Mobile**: Cell phone service (subset of Utilities).
- **Gifts**: Presents, donations.
- **Electronics**: Gadgets, tech (often found in Target/Amazon).
- **Alcohol**: Liquor stores, bars.