if node.solr.newrelic.license_key.to_s.empty?
  log("no solr license_key set, skipping installation of newrelic.jar") { level :info }
else
  log("solr license_key set, installation of newrelic.jar") { level :info }

  user = "solr"
  dir = ::File.dirname(node.solr.newrelic.jar)

  directory "#{dir}/logs" do
    owner user
    mode 0755
    recursive true
  end

	remote_file node.solr.newrelic.jar do
		source node.solr.newrelic.remote_jar_file
		mode "0744"
		not_if { File.file?(node.solr.newrelic.jar) || node.solr.newrelic.remote_jar_file.empty? }
	end

  log("node.solr.newrelic -> #{node.solr.newrelic.inspect}") { level :info }

  template ::File.join(dir, 'newrelic.yml') do
    source "newrelic.yml.erb"
    owner user
    mode 0644
    variables(:newrelic => node.solr.newrelic)
  end
end
