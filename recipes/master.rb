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

include_recipe "solr::user"
include_recipe "solr::install"
include_recipe "solr::install_newrelic"
include_recipe "smf::default"

auto_commit_enabled = node.solr.auto_commit.max_docs && node.solr.auto_commit.max_time

# configure solr
ruby_block "copy example solr home into master" do
  block do
    ::FileUtils.cp_r "/opt/solr/home_example", node.solr.master.home
    ::FileUtils.chown_R "solr", "root", node.solr.master.home
  end
  not_if { File.directory?(node.solr.master.home) }
end

log_configuration = "#{node.solr.master.home}/log.conf"
template log_configuration do
  source "solr-master-log.conf.erb"
  owner "solr"
  mode "0700"
  not_if { File.exists?("#{node.solr.master.home}/log.conf") }
end

remote_directory "#{node.solr.master.home}/solr/bin" do
  source "bin"
  files_owner "solr"
  files_mode "0755"
  owner "solr"
  mode "0755"
end


template "#{node.solr.master.home}/solr/conf/solrconfig.xml" do
  owner "solr"
  mode "0600"
  variables({
    :role => "master",
    :config => node.solr,
    :auto_commit => auto_commit_enabled
  })
end

template "#{node.solr.master.home}/solr/conf/schema.xml" do
  owner "solr"
  mode "0600"
  variables "filters" => node.solr.filters
  only_if { node.solr.uses_sunspot }
end

# create/import smf manifest
smf "solr-master" do
  credentials_user "solr"
  cmd = []
  cmd << "nohup java"

  cmd << node.solr.jvm_flags

  cmd << "-Xms#{node.solr.memory.xms}" unless node.solr.memory.xms.empty?
  cmd << "-Xmx#{node.solr.memory.xmx}" unless node.solr.memory.xmx.empty?

  cmd << "-Djetty.port=#{node.solr.master.port}"
  cmd << "-Djava.util.logging.config.file=#{log_configuration}"
  cmd << "-Dsolr.data.dir=#{node.solr.master.home}/solr/data"

  if node.solr.only_bind_private_ip
    addresses = node.network.interfaces.map { |name, i| i['addresses'].keys }.flatten

    bind_address = addresses.grep(/^10\.|^172\.1[6-9]\.|^172\.2\d\.|^172\.3[0-1]\.|^192\.168/).first
    cmd << "-Djetty.host=#{bind_address}"
  end

  # Add NewRelic to start command if an API key is present
  cmd << "-javaagent:#{node.solr.newrelic.jar}" unless node.solr.newrelic.license_key.to_s.empty?
  cmd << "-Dnewrelic.environment=#{node.solr.newrelic.environment}" unless node.solr.newrelic.license_key.to_s.empty?

  cmd << "-jar start.jar &"
  start_command cmd.join(' ')
  start_timeout 300
  stop_timeout 60
  environment "PATH" => node.solr.smf_path
  working_directory node.solr.master.home
end

node.solr.users.each do |user|
  rbac "solr-master" do
    user user
    action :add_management_permissions
    not_if { user == "root" }
  end
end

# start solr service
service "solr-master" do
  action :enable
end
