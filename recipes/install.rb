# Two packages needed for the Agent to work - all nodes run the Agent, including the Master, in our case.

# required for IO stat reporting
package "sysstat"
# required for opscenter agent connectivity
package "libssl0.9.8"

## Simplistic leader election
node.save
peers = search(:node, "roles:#{node[:roles].first}" )
leader = peers.sort{|a,b| a.uptime_seconds <=> b.uptime_seconds}.last || node    # the "or" covers the case where node is the first db

# Some reporting on the election
log "cassandra-opscenter LeaderElection: #{node[:roles].first} Leader is : #{$LEADERNAME} #{$LEADEREC2PUBLICHOSTNAME} #{$LEADERIPADDRESS} "

# set some global vars to be used by this and the agent recipe
$LEADERNAME = leader.name
$LEADERIPADDRESS = leader.ipaddress
$LEADEREC2PUBLICHOSTNAME = leader.ec2.public_hostname

if (node.name == leader.name)
  # leader installs the server - it is the Master
  include_recipe "cassandra-opscenter::opscenter-server"
  # leader installs the agent too
  include_recipe "cassandra-opscenter::opscenter-agent"
else 
  # followers install the agent 
  include_recipe "cassandra-opscenter::opscenter-agent"
  # and shuts down previous instances of the server - saving memory, etc
  include_recipe "cassandra-opscenter::opscenter-server-shutdown"
end

