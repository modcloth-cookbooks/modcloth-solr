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

include_recipe 'modcloth-solr::user'
include_recipe 'modcloth-solr::install'
include_recipe 'modcloth-solr::install_newrelic'
include_recipe 'smf::default'

# configure solr
ruby_block 'copy example solr home into replica' do
  block do
    ::FileUtils.cp_r '/opt/solr/home_example', node.solr.replica.home
    ::FileUtils.chown_R 'solr', 'root', node.solr.replica.home
  end
  not_if { File.directory?(node.solr.replica.home) }
end

execute 'chown solr replica directory' do
  command 'chown -R solr /opt/solr/replica'
end

log_configuration = "#{node.solr.replica.home}/log.conf"
template log_configuration do
  source 'solr-replica-log.conf.erb'
  owner 'solr'
  mode '0700'
  not_if { File.exist?("#{node.solr.replica.home}/log.conf") }
  notifies :restart, 'service[solr-replica]'
end

template "#{node.solr.replica.home}/solr/conf/solrconfig.xml" do
  owner 'solr'
  mode '0600'
  variables(
    role: 'replica',
    config: node.solr)
  notifies :restart, 'service[solr-replica]'
end

template "#{node.solr.replica.home}/solr/conf/schema.xml" do
  owner 'solr'
  mode '0600'
  only_if { node.solr.uses_sunspot }
  notifies :restart, 'service[solr-replica]'
end

# create/import smf manifest
smf 'solr-replica' do
  credentials_user 'solr'
  cmd = []
  cmd << "nohup #{node['modcloth-java']['jdk_base_path']}/#{node['modcloth-java']['jdk_version']}/bin/java"
  cmd << "-Djetty.port=#{node.solr.replica.port}"
  cmd << "-Djava.util.logging.config.file=#{log_configuration}"
  cmd << "-Dreplication.url=http://#{node.solr.master.hostname}:#{node.solr.master.port}/solr/replication"
  cmd << "-Dsolr.data.dir=#{node.solr.replica.home}/solr/data"

  # Add NewRelic to start command if an API key is present
  cmd << "-javaagent:#{node.solr.newrelic.jar}" unless node.solr.newrelic.api_key.to_s.empty?
  cmd << "-Dnewrelic.environment=#{node.application.environment}" unless node.solr.newrelic.api_key.to_s.empty?

  if node.solr.enable_jmx
    # Add the command-line flag for starting JMX.
    cmd << '-Dcom.sun.management.jmxremote'
  end

  if node.solr.java_options
    cmd << node.solr.java_options
  end

  cmd << '-jar start.jar &'
  start_command cmd.join(' ')
  start_timeout 300
  environment 'PATH' => node.solr.smf_path,
              'JAVA_HOME' => "#{node['modcloth-java']['jdk_base_path']}/#{node['modcloth-java']['jdk_version']}"
  working_directory node.solr.replica.home
  notifies :restart, 'service[solr-replica]'
end

node.solr.users.each do |sysuser|
  next if sysuser == 'solr' || sysuser == 'root'
  rbac_auth "Allow user #{sysuser} to manage solr-replica" do
    user sysuser
    auth 'solr-replica'
    only_if "id -u #{sysuser}"
  end
end

template "/opt/solr-#{node.solr.version}/replica/etc/jetty.xml" do
  source 'jetty.xml.erb'
  owner user
  mode '0755'
  notifies :restart, 'service[solr-replica]'
end

# start solr service
service 'solr-replica' do
  action :enable
end
