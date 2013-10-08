Description
===========

This cookbook exists to make a deployment of a [Datastax Opscenter][1] cluster on a Cassandra cluster in Amazon EC2.

[Datastax Opscenter][1] is a Monitoring and Management platform for Apache Cassandra - vital for visualising Cassandra's Status.

[Datastax Opscenter][1] is deployed in a traditional many-clients just-one-server model, which conflicts slightly with Cassandra's masterless deployment model.

To get around needing to know this/manage in an automated manner a leadership election takes place between nodes in the cluster, a leader is automatically assigned based on having the 'lowest' alphanumeric hostname, and that leader generates an agent package which is then distributed by http and verified by checksum.

The good news is that Opscenter stores its data within Cassandra itself in its own Keyspace (2 replicas) so if a leader is terminated and a new leader arises from the ashes, no data should be lost.

This cookbook supports two modes of deployment - multiregion OR non-multiregion, set through attributes. We default to non-multiregion aka singleregion. The way multiregion is expressed is in a difference in the agent's address configuration.

This cookbook holds certain assumptions to be true in order to easily manage its deployment:

A) You are deploying this on EC2
Reason: This was cookbook was developed on/designed for EC2 deployment. If you want to support non-EC2 deployment please submit patches.

B) All members of the cluster share the same UNIQUE chef role and this is the first role in the list of roles. i.e. cassandra-cluster-one or product-production-casdb.
Reason: The unique role is used to search for other cluster members for shared information. If you want to extend/improve this please submit patches.

C) Connectivity between cluster members is suffiently open to allow for agent distribution and agent connectivity. Typically you should have a security group that allows relatively open access from that security group.
Reason: Nothing will work without connectivity anyway. No node is an island.

[1]: http://planetcassandra.org/Download/DataStaxCommunityEdition

Requirements
============
* Chef 10.16.4+
* Cassandra on each node.
* Python cookbook to run the server.
* Java cookbook to run the agent (on each node including the elected server).
* Nginx cookbook for agent distribution on the elected server.

## Platform

* Ubuntu 12.04+ [tested heavily]
* Very Probably Debian
* Probably RPM-based distros. [we do attempt to differentiate where necessary]

Attributes
==========

See the contents of attributes/default.rb where there are accurate comments and self-explanatory attribute names.

Recipes
=======

* `default.rb` : A dummy recipe pointing to install.rb
* `install.rb` : Installs everything by calling the rest of the recipes in the right order. Includes a leadership election section for nominating the server.
* `opscenter-server.rb` : Installs the server
* `opscenter-agent.rb` : Installs the agent
* `opscenter-server-shutdown.rb` : Shuts down the server when a new leader takes over - we wouldn't want to waste ram, right ?

Usage
=====

Include cassandra-opscenter in your runlist.

Once this cookbook is deployed and the nodes converged, and you have set connectivity through whatever firewalls/security groups you have you should be able to reach Server's webserver on its public ip on port 8888.

Development
===========

See the [Github page][2]

[2]: https://github.com/mdsol/cassandra_opscenter_cookbook

License and Authors
===================

* Author: Alex Trull <atrull@mdsol.com>
* Author: Benton Roberts <broberts@mdsol.com>

Copyright: 2013–2013 Medidata Solutions, Inc.
