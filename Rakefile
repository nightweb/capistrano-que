require "bundler/gem_tasks"
require 'github_changelog_generator/task'

GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.user = 'nightweb'
  config.project = 'capistrano-que'
  config.issues = false
  config.future_release = '1.0.0'
end
