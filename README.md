About EgoPhone
==============

EgoPhone is a way of viewing information about the way you interact with
people using your iPhone. Currently all it does is import your iOS SMS
database into a DB, but from here the fun can really start.

How do I do it?
---------------

Assuming you've unpacked your sqlite dbs from your iPhone, all you need
to do is `rake egophone:people:import[/path/to/AddressBook.sqlitedb]`
and then `rake egophone:messages:import[/path/to/sms.db]`

Known Issues
------------
 - Doesn't actually do anything.
 - May Not handle some number formats gracefully
 - Does not handle SMSes sent to email addresses or from carrier set
   strings
