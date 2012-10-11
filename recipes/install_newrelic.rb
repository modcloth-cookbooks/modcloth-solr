if node.solr.newrelic.license_key.to_s.empty?
  log("no solr license_key set, skipping installation of newrelic.jar") { level :info }
else
  log("solr license_key set, installation of newrelic.jar") { level :info }

  directory File.dirname(node.solr.newrelic.jar) do
    owner user
    mode 0755
  end

	remote_file node.solr.newrelic.jar do
		source node.solr.newrelic.remote_jar_file
		mode "0744"
		not_if { File.file?(node.solr.newrelic.jar) || node.solr.newrelic.remote_jar_file.empty? }
	end

  log("node.solr.newrelic -> #{node.solr.newrelic.inspect}") { level :info }

  template ::File.join(::File.dirname(node.solr.newrelic.jar), 'newrelic.yml') do
    source "newrelic.yml.erb"
    owner user
    mode 0644
    variables(:newrelic => node.solr.newrelic)
  end
end
