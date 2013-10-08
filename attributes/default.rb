# Multi region switch variable: in this cookbook the agent config is different depending on this variable.
default[:cassandra][:multiregion] = "false"

# A top level directory attribute is provided should you wish to install elsewhere.
default[:cassandra][:parentdir] = "/opt"
default[:cassandra][:opscenter][:home] = "#{node[:cassandra][:parentdir]}/opscenter"

# What version to install, where to get it and a checksum to guarantee it is valid.
default[:cassandra][:opscenter][:version] = "3.2.2"
default[:cassandra][:opscenter][:src_url] = "http://downloads.datastax.com/community/opscenter-#{node['cassandra']['opscenter']['version']}-free.tar.gz"
default[:cassandra][:opscenter][:checksum] = "568b9e8767a0ed1bc7f101f39cf400f63fbba4f7dceefafab19c608aaf386950"

# We create fill in this attribute dynamically mid-chef-run on the host that installs the server and generates the package.
default[:cassandra][:opscenter][:agent][:checksum] = nil

# For agent distribution and proxying/redirect to the opscenter interface on the default http port
include_attribute "nginx_proxy"
node.set[:nginx_proxy][:http_port] = 8888
node.set[:nginx_proxy][:https_port] = 8888
node.set[:nginx_proxy][:target_host] = "#{node[:ipaddress]}"
