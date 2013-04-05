#
# Cookbook Name:: solr
# Recipe:: master
#
# Copyright 2010, ModCloth, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

def choose_ip(host)
  if node.solr.only_bind_private_ip
    addresses = host.network.interfaces.map { |name, i| i['addresses'].keys }.flatten
    addresses.grep(/^10\.|^172\.1[6-9]\.|^172\.2\d\.|^172\.3[0-1]\.|^192\.168/).first
  else
    host.ip_address
  end
end

def replication_host_ip
  if node.solr.replica.replication_search
    if Chef::Config[:solo]
      Chef::Log.warn('This recipe uses search. Chef Solo does not support search.')
    else
      host = search('node', node.solr.replica.replication_search).first
      raise('Unable to find solr master') unless host
      choose_ip(host)
    end
  else
    node.solr.master.hostname
  end
end

include_recipe "solr::user"
include_recipe "solr::install"
include_recipe "solr::install_newrelic"
include_recipe "smf::default"

# configure solr
ruby_block "copy example solr home into replica" do
  block do
    ::FileUtils.cp_r "/opt/solr/home_example", node.solr.replica.home
    ::FileUtils.chown_R "solr", "root", node.solr.replica.home
  end
  not_if { File.directory?(node.solr.replica.home) }
end

execute "chown solr replica directory" do
  command "chown -R solr /opt/solr/replica"
end

log_configuration = "#{node.solr.replica.home}/log.conf"
template log_configuration do
  source "solr-replica-log.conf.erb"
  owner "solr"
  mode "0700"
  not_if { File.exists?("#{node.solr.replica.home}/log.conf") }
end

template "#{node.solr.replica.home}/solr/conf/solrconfig.xml" do
  owner "solr"
  mode "0600"
  variables({
    :role => "replica",
    :config => node.solr
  })
end

template "#{node.solr.replica.home}/solr/conf/schema.xml" do
  owner "solr"
  mode "0600"
  variables "filters" => node.solr.filters
  only_if { node.solr.uses_sunspot }
end

replication_host = replication_host_ip
bind_ip = choose_ip(node)

# create/import smf manifest
smf "solr-replica" do
  credentials_user "solr"
  cmd = []
  cmd << "nohup java"

  cmd << node.solr.jvm_flags

  cmd << "-Xms#{node.solr.memory.xms}" unless node.solr.memory.xms.empty?
  cmd << "-Xmx#{node.solr.memory.xmx}" unless node.solr.memory.xmx.empty?

  cmd << "-Djetty.port=#{node.solr.replica.port}"
  cmd << "-Djava.util.logging.config.file=#{log_configuration}"
  cmd << "-Dreplication.url=http://#{replication_host}:#{node.solr.master.port}/solr/replication"
  cmd << "-Dsolr.data.dir=#{node.solr.replica.home}/solr/data"

  if node.solr.only_bind_private_ip
    cmd << "-Djetty.host=#{bind_ip}"
  elsif node.solr.bind_localhost
    cmd << "-Djetty.host=127.0.0.1"
  end

  # Add NewRelic to start command if an API key is present
  cmd << "-javaagent:#{node.solr.newrelic.jar}" unless node.solr.newrelic.license_key.to_s.empty?
  cmd << "-Dnewrelic.environment=#{node.solr.newrelic.environment}" unless node.solr.newrelic.license_key.to_s.empty?

  cmd << "-jar start.jar &"
  start_command cmd.join(' ')
  start_timeout 300
  stop_timeout 60
  environment "PATH" => node.solr.smf_path
  working_directory node.solr.replica.home
end

node.solr.users.each do |user|
  rbac "solr-replica" do
    user user
    action :add_management_permissions
    not_if { user == "root" }
  end
end

# start solr service
service "solr-replica" do
  action :enable
end
