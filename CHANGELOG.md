# 0.4.8 / 2012-03-13 / Grady Griffin

* readme revisions
* fixing view manager bug

# 0.4.7 / 2012-03-13 / Grady Griffin

* readme revision

# 0.4.6 / 2012-03-12 / Grady Griffin

* tested with sqlite
* tested with postgres

# 0.4.5 / 2012-03-11 / Grady Griffin

* refactored some validation logic code
* reorganized code to clean up active record base
* added generator to manage view versioning
* removed old view versioning code
* added view manager class to handle view versioning, creating  and updating

# 0.4.4 / 2012-03-11 / Grady Griffin

* added various connection adapters; only mysql tested

# 0.4.3 / 2012-03-11 / Grady Griffin

* major refactor to do less in active record base
* add view versioning to prevent creating views when not necessary

# 0.4.2 / 2012-03-11 / Grady Griffin

* reorganized some methods
* added logic to free up complex data structures once they are not needed
* fixed some comment typos
* added comments
* updated reflect\_on\_multiple\_associations to work as intended

# 0.4.1 / 2012-03-11 / Grady Griffin

* added homepage to gemspec

# 0.4.0 / 2012-03-11 / Grady Griffin

* added tests for validation and configurations
* reorganized files
* added more comments


# 0.3.1 / 2012-03-11 / Grady Griffin

* Cleaned up some sti problems
* added more comments
* removed some unnecessary codez

# 0.3.0 / 2012-03-11 / Grady Griffin

* inherits validations as well
* MTI to MTI is working
* STI to STI is working
* MTI to STI to MTI is working
* bulletproofed shard system by giving it its own association classes

# 0.2.1 / 2012-03-09 / Grady Griffin

* added some reasonable defaults for shard associations
* already had CRU added D for CRUD
* updated logic to support polymorphic associations
* added crud tests

# 0.2.0 / 2012-03-09 / Grady Griffin

* revamped entire library to use associations as table shards
* general cleanup
* added more options for associations


# 0.1.0 / 2012-03-08 / Grady Griffin

* can make a simple MTI class
* modified schema dumper to omit views

# 0.0.1 / 2012-03-07 / Grady Griffin

* initial commit