# plugins.rb
require_relative "lib/bundler/trivy/plugin"

Bundler::Plugin.add_hook("after-install-all") do
  Bundler::Trivy::Plugin.scan_after_install
end
