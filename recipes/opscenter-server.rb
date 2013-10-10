#
# Cookbook Name:: cassandra-opscenter
# Recipe:: opscenter-server
#
# Copyright 2013 Medidata Solutions Worldwide
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Chef::Log.info("Installing Opscenter Server")

# Install python
include_recipe "python"

# Required for opscenter server connectivity
package "libssl0.9.8"

# Create a group for our opscenter user
group "#{node[:cassandra][:opscenter][:group]}"

# Create a user.. for our opscenter
user "#{node[:cassandra][:opscenter][:user]}" do
  system    true
  home      node[:cassandra][:opscenter][:home]
  gid       node[:cassandra][:opscenter][:group]
  shell     "/bin/sh"
end

# download source
src_url = node[:cassandra][:opscenter][:src_url]
local_archive = "#{Chef::Config[:file_cache_path]}/#{::File.basename src_url}"
remote_file local_archive do
  source  src_url
  mode    0644
  not_if  { File.exists? local_archive }
  checksum node[:cassandra][:opscenter][:checksum]
end

VERSION_DIR = "#{node[:cassandra][:opscenter][:home]}-#{node[:cassandra][:opscenter][:version]}"

# create the target directory
directory VERSION_DIR do
  owner     "#{node[:cassandra][:opscenter][:user]}"
  group     "#{node[:cassandra][:opscenter][:group]}"
  mode      0775
  recursive true
end

# unpack
execute "unpack #{local_archive}" do
  command   "tar --strip-components 1 --no-same-owner -xzf #{local_archive}"
  creates   "#{VERSION_DIR}/bin/opscenter"
  user      "#{node[:cassandra][:opscenter][:user]}"
  group     "#{node[:cassandra][:opscenter][:group]}"
  cwd       VERSION_DIR
end

# link the opscenter home to the version directory
link node[:cassandra][:opscenter][:home] do
  to        VERSION_DIR
  owner     "#{node[:cassandra][:opscenter][:user]}"
  group     "#{node[:cassandra][:opscenter][:group]}"
end

# opscenter server configuration
template "#{node[:cassandra][:opscenter][:home]}/conf/opscenterd.conf" do
  source    "opscenterd.conf.erb"
  owner     "#{node[:cassandra][:opscenter][:user]}"
  group     "#{node[:cassandra][:opscenter][:group]}"
  mode      "0640"
end

# Start it up
execute "Start Datastax OpsCenter" do
  command   "#{node[:cassandra][:opscenter][:home]}/bin/opscenter"
  user      "#{node[:cassandra][:opscenter][:user]}"
  group     "#{node[:cassandra][:opscenter][:group]}"
  cwd       node[:cassandra][:opscenter][:home]
  not_if    "pgrep -f start_opscenter.py"
  notifies :run, "bash[Short Delay for Opscenter Server Startup]", :immediately
end

# We cause a delay after startup so that the agent.tar.gz can be created and permissions set afterwards
bash "Short Delay for Opscenter Server Startup" do
  code <<-EOH
  sleep 15
  EOH
  action :nothing
  not_if { ::File.exists?("#{node[:cassandra][:opscenter][:home]}/agent.tar.gz") }
end

# Set everyone-readable permissions on agent.tar.gz so nginx can read it and other nodes can get it.
file "#{node[:cassandra][:opscenter][:home]}/agent.tar.gz" do
  owner     "#{node[:cassandra][:opscenter][:user]}"
  group     "#{node[:cassandra][:opscenter][:group]}"
  mode      0644
  only_if  { ::File.exists?("#{node[:cassandra][:opscenter][:home]}/agent.tar.gz") }
  notifies :create, "ruby_block[Save Opscenter Agent Checksum]", :immediately
end

# We create a hash in our node data and save the node data - the agent installation recipe will use this hash to verify the download.
ruby_block "Save Opscenter Agent Checksum" do
  block do
    node.set[:cassandra][:opscenter][:agent][:checksum] = Digest::SHA256.file("#{node[:cassandra][:opscenter][:home]}/agent.tar.gz").hexdigest
    node.save
  end
end

# Install nginx - the cookbook would be better.
package "nginx" do
  notifies :enable, "service[nginx]", :immediately
end

# Start nginx.
service "nginx" do
  supports :restart => true, :reload => true
  action   :enable
end

# Provide access to the agent.tar.gz on the leader via an nginx site.
template "/etc/nginx/sites-available/opscenter" do
  source "opscenter_nginx_site.erb"
  mode    0644
  notifies :create, "link[/etc/nginx/sites-enabled/opscenter]", :immediately
  notifies :restart, "service[nginx]", :immediately
end

# Link the site to enabled access
link "/etc/nginx/sites-enabled/opscenter" do
  to "/etc/nginx/sites-available/opscenter"
end

