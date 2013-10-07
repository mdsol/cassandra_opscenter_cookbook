log "Installing Opscenter Server"

# download source
src_url = node[:cassandra][:opscenter][:src_url]
local_archive = "#{Chef::Config[:file_cache_path]}/#{::File.basename src_url}"
remote_file local_archive do
  source  src_url
  mode    0644
  not_if  { File.exists? local_archive }
  checksum node[:cassandra][:opscenter][:checksum]
end

VERSION_DIR = "#{node[:cassandra][:opscenter_home]}-#{node[:cassandra][:opscenter][:version]}"

# create the target directory
directory VERSION_DIR do
  owner     "#{node[:cassandra][:user]}"
  group     "#{node[:tomcat][:user]}"
  mode      0775
  recursive true
end

# unpack
execute "unpack #{local_archive}" do
  command   "tar --strip-components 1 --no-same-owner -xzf #{local_archive}"
  creates   "#{VERSION_DIR}/bin/opscenter"
  user      "#{node[:cassandra][:user]}"
  group     "#{node[:tomcat][:user]}"
  cwd       VERSION_DIR
end

# link the opscenter_home to the version directory
link node[:cassandra][:opscenter_home] do
  to        VERSION_DIR
  owner     "#{node[:cassandra][:user]}"
  group     "#{node[:tomcat][:user]}"
end

# opscenter server configuration
template "#{node[:cassandra][:opscenter_home]}/conf/opscenterd.conf" do
  source "opscenterd.conf.erb"
  owner     "#{node[:cassandra][:user]}"
  group     "#{node[:tomcat][:user]}"
  mode      "0640"
end

# Start it up
execute "Start Datastax OpsCenter" do
  command   "#{node[:cassandra][:opscenter_home]}/bin/opscenter"
  user      "#{node[:cassandra][:user]}"
  group     "#{node[:tomcat][:user]}"
  cwd       node[:cassandra][:opscenter_home]
  not_if    "pgrep -f start_opscenter.py"
  notifies :run, "bash[Short Delay for Opscenter Server Startup]", :immediately
end

# We cause a delay after startup so that the agent.tar.gz can be created and permissions set afterwards
bash "Short Delay for Opscenter Server Startup" do
  code <<-EOH
  sleep 15
  EOH
  action :nothing
  not_if { ::File.exists?("#{node[:cassandra][:opscenter_home]}/agent.tar.gz") }
end

# set nginx-readable permissions on agent.tar.gz
file "#{node[:cassandra][:opscenter_home]}/agent.tar.gz" do
  owner     "#{node[:cassandra][:user]}"
  group     "#{node[:tomcat][:user]}"
  mode      0644
  only_if  { ::File.exists?("#{node[:cassandra][:opscenter_home]}/agent.tar.gz") }
  notifies :create, "ruby_block[Save Opscenter Agent Checksum]", :immediately
end

ruby_block "Save Opscenter Agent Checksum" do
  block do
    # We create a hash in our node data and save the node data - the agent installation recipe will use this hash to verify the download.
    node.set[:cassandra][:opscenter][:agent][:checksum] = Digest::SHA256.file("#{node[:cassandra][:opscenter_home]}/agent.tar.gz").hexdigest
    node.save
  end
  action :nothing
end

# We setup a webserver

# setup nginx
include_recipe "nginx_proxy"

# Provide access to the agent.tar.gz on the leader via http/https
rewind :template => "/etc/nginx/sites-available/nginx_proxy" do
  source "nginx_proxy.erb"
  cookbook_name "cassandra-opscenter" 
end

# Make sure we start nginx mid-run
service "nginx" do
  action [ :enable, :start ]
end
