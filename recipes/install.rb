#
# Cookbook Name:: solr
# Recipe:: install
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

include_recipe "java::default"
include_recipe "solr::user"

user = "solr"

remote_file             = node.solr.remote_file                # http://.../apache-solr-3.6.2.tgz
local_file              = remote_file.gsub(%r{.*/}, '')        # apache-solr-3.6.2.tgz
local_dir               = local_file.gsub(%r{\.tgz}, '')       # apache-solr-3.6.2.tgz

node["solr"]["version"] = local_dir.gsub(%r{.*-}, '')          # 3.6.2

remote_file "#{Chef::Config[:file_cache_path]}/#{local_file}" do
	source remote_file
	mode "0744"
	not_if { File.directory?("#{Chef::Config[:file_cache_path]}/#{local_dir}") }
end

package_file = "#{Chef::Config[:file_cache_path]}/#{local_file}"

execute "extract solr tar file into tmp" do
  command "cd #{Chef::Config[:file_cache_path]} && tar -xvf #{package_file}"
  not_if { File.directory?("#{Chef::Config[:file_cache_path]}/#{local_dir}") }
end

# install solr
directory "/opt/solr-#{node.solr.version}" do
  owner user
  mode "0755"
  not_if { File.directory?("/opt/solr-#{node.solr.version}") }
end

ruby_block "copy example solr home directory" do
  block do
    ::FileUtils.cp_r "#{Chef::Config[:file_cache_path]}/#{local_dir}/example", "/opt/solr-#{node.solr.version}/home_example"
  end
  not_if { File.exists?("/opt/solr-#{node.solr.version}/home_example") }
end

ruby_block "create empty data directory" do
  block do
    ::FileUtils.mkdir_p "/opt/solr-#{node.solr.version}/home_example/solr/data"
  end
  not_if { File.exists?("/opt/solr-#{node.solr.version}/home_example/solr/data") }
end

execute "chown solr directory" do
  command "chown -R #{user} /opt/solr-#{node.solr.version}"
end

link "/opt/solr" do
  owner user
  to "/opt/solr-#{node.solr.version}"
  not_if { File.directory?("/opt/solr") }
end

directory "/var/log/solr" do
  owner user
  mode "0755"
  not_if { File.directory?("/var/log/solr") }
end
