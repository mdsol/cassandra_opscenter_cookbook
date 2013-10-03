Description
===========

This cookbook exists to make a deployment of a Datastax Opscenter cluster on a Cassandra cluster.

[1]: http://planetcassandra.org/Download/DataStaxCommunityEdition

Requirements
============
Chef 10.16.4+
Cassandra 1.2.x or 2.x.x or later.

## Platform

* Ubuntu 10.04+

Attributes
==========

See the contents of attributes/default.rb

Recipes
=======

default.rb
opscenter.rb
opscenter-server.rb
opscenter-agent.rb

Usage
=====

Include cassandra-opscenter in your runlist.

Development
===========

See github [2]

[2]: https://github.com/mdsol/cassandra_opscenter_cookbook

License and Authors
===================

* Author: Alex Trull <atrull@mdsol.com>
* Author: Benton Roberts <broberts@mdsol.com>

Copyright: 2013–2013 Medidata Solutions, Inc.
