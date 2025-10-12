We're going to add a new page to the admin-only pages of this system

It's going to be a "Unit ID generation" page.

Check out the code we use for generating IDs of Inspections and Units.

The new page is going to pre-generate these IDs for Units. We're going to refer to unit IDs as "Badges" because that's how they're going to be represented in the real world, but for our purposes they're just the IDs of Units, generated in advance.

For now, we're just going to focus on the tables for this pre-generation - we won't change the Unit model at all yet.

There will be two tables:

- "Badges", containing a random string ID, batch ID, and note string
- "BadgeBatches", containing a normal integer ID, creation date, and note string

When creating the "Badges" table you should look at the way we do IDs on Inspections and Units - we don't have an integer ID column.

You'll see that there are notes attached to both batches and badges.

The admin controller - badges_controller.rb - will list existing batches on its index page, in a table - "ID", "Number of Badges", "Date Created", "Notes".

Clicking through into a batch will list the badges within that batch, in a table - "ID", "Note".
You'll then be able to click on an individual batch and edit its note.

Aside from viewing the existing batches and badges, and editing their notes, there'll be a "new"endpoint in badges_controller.rb for creating a new batch. The user will specify the number of IDs, and the note to attach. The system will then create a batch with that note, and then will create that amount of badges (efficiently, by generating a list of IDs up front and creating them in a batch), linked to that batch.

When writing any of this code, you will re-use existing ways of handling forms via the ChobbleForms controllers. You won't need to create any new CSS classes. Your error handling should not be over-cautious.

We'll write tests to go alongside all of this, following the format of the existing tests.
