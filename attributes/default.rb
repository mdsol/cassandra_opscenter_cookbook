# multi region switch variable - switching to true or false sets priam variables - we default to single region i.e. false
# ( in this cookbook the agent config is different depending on this variable )
default[:cassandra][:multiregion] = "false"

default[:cassandra][:parentdir] = "/opt"
default[:cassandra][:opscenter_home] = "#{node[:cassandra][:parentdir]}/opscenter"
default[:cassandra][:opscenter][:version] = "3.2.2"
default[:cassandra][:opscenter][:src_url] = "http://downloads.datastax.com/community//opscenter-#{node['cassandra']['opscenter']['version']}-free.tar.gz"
default[:cassandra][:opscenter][:checksum] = "568b9e8767a0ed1bc7f101f39cf400f63fbba4f7dceefafab19c608aaf386950"

# for agent distribution and proxying/redirect to the opscenter interface on the default http port
include_attribute "nginx_proxy"
node.set[:nginx_proxy][:http_port] = 8888
node.set[:nginx_proxy][:https_port] = 8888
node.set[:nginx_proxy][:target_host] = "#{node[:ipaddress]}"
