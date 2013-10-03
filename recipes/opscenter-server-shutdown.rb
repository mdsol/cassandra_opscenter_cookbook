# We may lose the election one day. In which case we will stop running the Opscenter Server.

# Stop the server, Remove the linked directory. Metrics are kept in Cassandra itself so this is strangely safe.
bash "Opscenter Server Shutdown and Delink" do
  code <<-EOH
  pkill -f start_opscenter.py
  rm -rf #{node[:cassandra][:opscenter_home]}
  EOH
  only_if { ::File.exists?("#{node[:cassandra][:opscenter_home]}/bin/opscenter") }
end

