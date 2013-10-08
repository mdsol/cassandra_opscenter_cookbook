## Simplistic leader election
node.save
peers = search(:node, "roles:#{node[:roles].first}" )
leader = peers.sort{|a,b| a.name <=> b.name}.first || node # the "or" covers the case where node is the first db

# Some reporting on the election
Chef::Log.info("cassandra-opscenter LeaderElection: #{node[:roles].first} Leader is : #{leader.name} #{leader.ec2.public_hostname} #{leader.ipaddress}")

# Set some global vars to be used in the agent recipe
$LEADERNAME = leader.name
$LEADERIPADDRESS = leader.ipaddress
$LEADEREC2PUBLICHOSTNAME = leader.ec2.public_hostname
$LEADERAGENTCHECKSUM = leader.cassandra.opscenter.agent.checksum

if (node.name == leader.name)
  # Leader installs the server - it is the Master
  include_recipe "cassandra-opscenter::opscenter-server"
  # Leader installs the agent too
  include_recipe "cassandra-opscenter::opscenter-agent"
else 
  # Followers install the agent 
  include_recipe "cassandra-opscenter::opscenter-agent"
  # And shutdown previous instances of the server - saving memory, etc
  include_recipe "cassandra-opscenter::opscenter-server-shutdown"
end

