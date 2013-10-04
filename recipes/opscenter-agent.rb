log "Installing Opscenter Agent"

# Install Agent

# Download Agent from Leader - the leader may take a while to generate the agent.tar.gz at install time, so we give it up to 40 tries to do it.
log "Downloading Agent from http://#{$LEADERIPADDRESS}/agent.tar.gz"
remote_file "#{Chef::Config[:file_cache_path]}/#{$LEADERIPADDRESS}-opscenter-#{node[:cassandra][:opscenter][:version]}-agent.tar.gz" do
  source "http://#{$LEADERIPADDRESS}/agent.tar.gz"
  action :create_if_missing
  mode "0644"
  retries 10
  notifies :run, "bash[Opscenter Agent Installation]", :immediately
end

# Install the Agent according to the Documentation - but clear out the old address.yaml in case there is an update, in case the server changed.
bash "Opscenter Agent Installation" do
  code <<-EOH
  cd /tmp/ && tar zxvf #{Chef::Config[:file_cache_path]}/#{$LEADERIPADDRESS}-opscenter-#{node[:cassandra][:opscenter][:version]}-agent.tar.gz && cd agent && ./bin/install_agent.sh opscenter-agent.deb #{$LEADERIPADDRESS}
  EOH
  not_if "dpkg -l opscenter-agent | grep #{node[:cassandra][:opscenter][:version]} && grep #{$LEADERIPADDRESS} /var/lib/opscenter-agent/conf/address.yaml"
  notifies :create, "template[/var/lib/opscenter-agent/conf/address.yaml]", :immediately
end

# Opscenter Agent configuration - we force ssl to be true
template "/var/lib/opscenter-agent/conf/address.yaml" do
  variables :LEADERIPADDRESS => $LEADERIPADDRESS
  source "address.yaml.erb"
  mode      "0644"
  action :nothing
  notifies :restart, "service[opscenter-agent]", :immediately
end

# Delete the downloaded file if we didn't manage to install it - it is safer to download again and try again
file "#{Chef::Config[:file_cache_path]}/#{$LEADERIPADDRESS}-opscenter-#{node[:cassandra][:opscenter][:version]}-agent.tar.gz" do
  action :delete
  not_if "dpkg -l opscenter-agent | grep #{node[:cassandra][:opscenter][:version]} && grep #{$LEADERIPADDRESS} /var/lib/opscenter-agent/conf/address.yaml"
end

# We use the opscenter-agent service resource so it must be specified somewhere.
service "opscenter-agent" do
  action :start
end
