#
# Cookbook Name:: cassandra-opscenter
# Recipe:: opscenter-server-shutdown
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
link node[:cassandra][:opscenter][:home] do
  action :delete
end
