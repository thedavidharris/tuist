Then(/^tuist builds the project$/) do
  system("swift", "run", "tuist", "build", "--path", @dir)
end

Then(/^tuist builds the project at (.+)$/) do |path|
  system("swift", "run", "tuist", "build", "--path", File.join(@dir, path))
end
