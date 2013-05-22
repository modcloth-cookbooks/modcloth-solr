maintainer       "ModCloth, Inc."
maintainer_email "ops@modcloth.com"
license          "Apache 2.0"
description      "Installs/Configures solr"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.1.0"

depends "java"
depends "smf", '< 1.0.0'

attribute "solr/only_bind_private_ip",
  :display_name => "Bind Private IP",
  :description => "Bind only on RFC 1918 network interfaces",
  :default => "false",
  :required => "optional"

attribute "solr/users",
  :display_name => "Solr users",
  :description => "Users that are able to manage solr using RBAC.",
  :type => "array",
  :required => "recommended"

attribute "solr/auto_commit/max_docs",
  :display_name => "Solr Auto-commit max documents",
  :description => "Maximum number of document writes to queue before forcing a commit. solr/auto_commit/max_time must also be set for this to take effect.",
  :type => "string",
  :required => "recommended"

attribute "solr/auto_commit/max_time",
  :display_name => "Solr Auto-commit max time",
  :description => "Maximum time (in milliseconds) before queued document writes are committed. solr/auto_commit/max_docs must also be set for this to take effect.",
  :type => "string",
  :required => "recommended"

attribute "solr/memory/xms",
  :display_name => "Solr min memory",
  :description => "Minimum JVM memory allocation for Solr (-Xms), eg 1000M [leave empty for default JVM behavior]",
  :type => "string",
  :default => "",
  :required => "recommended"

attribute "solr/memory/xmx",
  :display_name => "Solr max memory",
  :description => "Maximum JVM memory allocation for Solr (-Xmx), eg 5000M [leave empty for default JVM behavior]",
  :type => "string",
  :default => "",
  :required => "recommended"

attribute "solr/smf_path",
  :display_name => "Solr SMF path",
  :description => "PATH variable to set for operations in SMF",
  :type => "string",
  :required => "optional"

attribute "solr/use_sunspot",
  :display_name => "Use sunspot schema.xml",
  :description => "Use conf/schema.xml from Sunspot gem. Defaults to true.",
  :required => "optional"

attribute "solr/master/hostname",
  :display_name => "Solr master hostname",
  :description => "Hostname on which solr master runs. Used to configure replication.",
  :type => "string",
  :required => "recommended"

attribute "solr/master/port",
  :display_name => "Solr master port",
  :description => "Port on which solr master runs. Defaults to 9985.",
  :type => "string",
  :required => "optional"

attribute "solr/master/home",
  :display_name => "Solr master home",
  :description => "Directory into which solr home will be installed and configured. Defaults to /opt/solr/master",
  :type => "string",
  :required => "optional"

attribute "solr/replica/port",
  :display_name => "Solr replica port",
  :description => "Port on which solr slave runs. Defaults to 8983.",
  :type => "string",
  :required => "optional"

attribute "solr/replica/home",
  :display_name => "Solr replica home",
  :description => "Directory into which solr home will be installed and configured. Defaults to /opt/solr/replica.",
  :type => "string",
  :required => "optional"

attribute "solr/replica/replication_search",
  :display_name => "Solr replication search",
  :description => "Chef search with which to find a solr master from which to replicate. If this is nil, defaults to node.solr.master.hostname",
  :type => "string",
  :required => "optional"

attribute "solr/newrelic/license_key",
  :display_name => "Solr NewRelic license key",
  :description => "License key to configure Solr NewRelic integration. Leave key empty to disable NewRelic.",
  :type => "string",
  :required => "optional"

attribute "solr/newrelic/app_name",
  :display_name => "Solr NewRelic app name",
  :description => "App name with which to register events with NewRelic",
  :type => "string",
  :default => "Solr application",
  :required => "recommended"

attribute "solr/newrelic/remote_jar_file",
  :display_name => "Solr NewRelic remote jar file location",
  :description => "Http(s) Location of user-specific newrelic.jar file",
  :type => "string",
  :default => "",
  :require => "recommended"

attribute "solr/newrelic/environment",
  :display_name => "Solr NewRelic environment",
  :description => "Environment with which to configure NewRelic notifications",
  :type => "string",
  :default => "demo",
  :required => "recommended"

attribute "solr/jvm_flags",
  :display_name => "Solr JVM flags",
  :description => "Extra flags to pass to the JVM (eg -d64 for 64bit mode)",
  :type => "string",
  :default => "",
  :required => "optional"
