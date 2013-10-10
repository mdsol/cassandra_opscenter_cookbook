#
# Cookbook Name:: cassandra-opscenter
# Recipe:: opscenter-agent
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

Chef::Log.info("Installing Opscenter Agent")

# Required for IO reporting
package "sysstat"

# Required for opscenter agent connectivity
package "libssl0.9.8"

# Install java
include_recipe "java"

# Pick a package suffix based on the platform.
case node[:platform]
  when "debian", "ubuntu"
    PACKAGESUFFIX = "deb"
  when "redhat", "centos", "fedora", "scientific", "amazon"
    PACKAGESUFFIX = "rpm"
end

# Download Agent from Leader - the leader may take a while to generate the agent.tar.gz at install time and make it available so we give it some retries to do it.
Chef::Log.info("Downloading Agent from http://#{$LEADEREC2PUBLICHOSTNAME}/agent.tar.gz")
remote_file "#{Chef::Config[:file_cache_path]}/#{$LEADEREC2PUBLICHOSTNAME}-opscenter-#{node[:cassandra][:opscenter][:version]}-agent.tar.gz" do
  source "http://#{$LEADEREC2PUBLICHOSTNAME}/agent.tar.gz"
  mode "0644"
  retries 10
  checksum $LEADERAGENTCHECKSUM
  notifies :run, "bash[Opscenter Agent Installation]", :immediately
end

# Install the Agent according to the Documentation - which we hope has been fixed.
bash "Opscenter Agent Installation" do
  code <<-EOH
  cd /tmp/ && tar zxvf #{Chef::Config[:file_cache_path]}/#{$LEADEREC2PUBLICHOSTNAME}-opscenter-#{node[:cassandra][:opscenter][:version]}-agent.tar.gz && cd agent && ./bin/install_agent.sh opscenter-agent.#{PACKAGESUFFIX} #{$LEADEREC2PUBLICHOSTNAME}
  EOH
  not_if "dpkg -l opscenter-agent | grep #{node[:cassandra][:opscenter][:version]} && grep #{$LEADEREC2PUBLICHOSTNAME} /var/lib/opscenter-agent/conf/address.yaml"
  notifies :create, "template[/var/lib/opscenter-agent/conf/address.yaml]", :immediately
  notifies :restart, "service[opscenter-agent]", :immediately
end

# Opscenter Agent configuration - differs between single and multi region setups
case node[:cassandra][:priam_multiregion_enable]
when "true"
  template "/var/lib/opscenter-agent/conf/address.yaml" do
    variables :LEADEREC2PUBLICHOSTNAME => $LEADEREC2PUBLICHOSTNAME
    source "multiregion-address.yaml.erb"
    mode      "0644"
    notifies :restart, "service[opscenter-agent]", :immediately
  end
else
  template "/var/lib/opscenter-agent/conf/address.yaml" do
    variables :LEADEREC2PUBLICHOSTNAME => $LEADEREC2PUBLICHOSTNAME
    source "singleregion-address.yaml.erb"
    mode      "0644"
    notifies :restart, "service[opscenter-agent]", :immediately
  end
end

# We call the opscenter-agent service resource so it must be specified somewhere.
service "opscenter-agent" do
  action :start
end
