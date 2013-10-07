# We may lose the election one day. In which case we will stop running the Opscenter Server.
# Metrics are kept in Cassandra itself so this is strangely safe.

# Stop the server
bash "Opscenter Server Shutdown" do
  code <<-EOH
  pkill -f start_opscenter.py
  EOH
  only_if "pgrep -f start_opscenter.py"
end

# Delete the link
link node[:cassandra][:opscenter_home] do
  action :delete
end
