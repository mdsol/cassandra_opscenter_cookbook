log "Installing Opscenter Agent"

# Install Agent

# Download Agent from Leader - the leader may take a while to generate the agent.tar.gz at install time, so we give it up to 40 tries to do it.
log "Downloading Agent from http://#{$LEADEREC2PUBLICHOSTNAME}/agent.tar.gz"
remote_file "#{Chef::Config[:file_cache_path]}/#{$LEADEREC2PUBLICHOSTNAME}-opscenter-#{node[:cassandra][:opscenter][:version]}-agent.tar.gz" do
  source "http://#{$LEADEREC2PUBLICHOSTNAME}/agent.tar.gz"
  mode "0644"
  retries 10
  checksum $LEADERAGENTCHECKSUM
  notifies :run, "bash[Opscenter Agent Installation]", :immediately
end

# Install the Agent according to the Documentation - but clear out the old address.yaml in case there is an update, in case the server changed.
bash "Opscenter Agent Installation" do
  code <<-EOH
  cd /tmp/ && tar zxvf #{Chef::Config[:file_cache_path]}/#{$LEADEREC2PUBLICHOSTNAME}-opscenter-#{node[:cassandra][:opscenter][:version]}-agent.tar.gz && cd agent && ./bin/install_agent.sh opscenter-agent.deb #{$LEADEREC2PUBLICHOSTNAME}
  EOH
  not_if "dpkg -l opscenter-agent | grep #{node[:cassandra][:opscenter][:version]} && grep #{$LEADEREC2PUBLICHOSTNAME} /var/lib/opscenter-agent/conf/address.yaml"
  notifies :create, "template[/var/lib/opscenter-agent/conf/address.yaml]", :immediately
end

# Opscenter Agent configuration - differs between single and multi region setups
if node[:cassandra][:multiregion] == "true"
  template "/var/lib/opscenter-agent/conf/address.yaml" do
    variables :LEADEREC2PUBLICHOSTNAME => $LEADEREC2PUBLICHOSTNAME
    source "multiregion-address.yaml.erb"
    mode      "0644"
    notifies :restart, "service[opscenter-agent]", :immediately
  end
elsif node[:cassandra][:multiregion] == "false"
  template "/var/lib/opscenter-agent/conf/address.yaml" do
    variables :LEADEREC2PUBLICHOSTNAME => $LEADEREC2PUBLICHOSTNAME
    source "singleregion-address.yaml.erb"
    mode      "0644"
    notifies :restart, "service[opscenter-agent]", :immediately
  end
end

# Delete the downloaded file if we didn't manage to install it - it is safer to download again and try again
file "#{Chef::Config[:file_cache_path]}/#{$LEADEREC2PUBLICHOSTNAME}-opscenter-#{node[:cassandra][:opscenter][:version]}-agent.tar.gz" do
  action :delete
  not_if "dpkg -l opscenter-agent | grep #{node[:cassandra][:opscenter][:version]} && grep #{$LEADEREC2PUBLICHOSTNAME} /var/lib/opscenter-agent/conf/address.yaml"
end

# We use the opscenter-agent service resource so it must be specified somewhere.
service "opscenter-agent" do
  action :start
end
