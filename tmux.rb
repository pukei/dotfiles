require 'optparse'

begin
  msg = <<~TEXT

    \t\033[31m# Try one of these:\033[0m
    \033[32m\truby ~/dotfiles/tmux.rb bw|cb|cm|ps|s|sb|t

    \t# Start MySQL, Postgres, Redis
    \truby ~/dotfiles/tmux.rb t --start

    \t# Switch branch (default: "develop") and git pull
    \truby ~/dotfiles/tmux.rb t -branch=main
    \033[0m
  TEXT

  @options = {}

  OptionParser.new do |opts|
    opts.banner = "Usage: tmux.rb [options]#{msg}Options:"
    opts.on('-s', '--start', "\tStart MySQL, Postgres, Redis") do
      @options[:start] = true
    end

    opts.on('-b', '--branch[=BRANCH]', "\tSwitch branch (default: \"develop\") and git pull") do |opt|
      @options[:branch] = opt || 'develop'
    end
  end.parse!

  WORKSPACE = {
    bw:  ['~/workspace/tripla_booking_widget', 2, 'yarn server --port 8080'],
    cb:  ['~/workspace/triplabot2.0', 2, 'yarn server --port 8082'],
    cm:  ['~/workspace/tripla_frontend_app', 2, 'yarn server --port 8083'],
    ps:  ['~/workspace/pakku_subbu', 3, 'foreman start'],
    ps3: ['~/workspace/pakku_subbu', 3, ['br -p 7000', 'anycable-go --host=localhost --port=7777 --path=/', 'be anycable']],
    s:   ['~/workspace/ships', 3, 'export PORT=4000; br -p 4000'],
    sb:  ['~/workspace/tripla_search_bar', 2, 'yarn server --port 8081'],
    sc:  ['~/workspace/site-controller-api', 3, 'br -p 5000'],
    t:   ['~/workspace/tripla', 3, 'br']
  }.freeze

  project = ARGV[0].to_sym
  workspace = '-c ' + WORKSPACE[project][0]
  more_windows = WORKSPACE[project][1]
  start_servers = Array(WORKSPACE[project][2])
rescue
  abort msg
end

# start servers
`~/.start-services` if @options[:start]

`tmux start-server`

`tmux new-session -d -s #{project} -n 1 #{workspace}`

more_windows.times do |i|
  `tmux new-window -t #{project}:#{i + 2} -n #{i + 2} #{workspace}`
end

(more_windows + 1).times do |i|

  # Opne vim in the first window if "branch" is no specified
  if i == 0 && !@options[:branch]
    `tmux send-keys -t #{project}:1 "vim" C-m`
  end

  # Last window
  if i == more_windows
    start_servers.each_with_index do |start_server, si|
      # Select pane
      `tmux selectp -t #{project}:#{i + 1}`

      if si == 1
        `tmux split-window -h #{workspace}`
      end

      if si == 2
        `tmux split-window -v #{workspace}`
      end

      # Try to checkout the branch and pull
      if @options[:branch]
        cmds = ["git fetch origin #{@options[:branch]}", "git checkout #{@options[:branch]}", 'git pull']
        cmds << 'yarn install' if [:bw, :cb, :cm, :s, :sb].include?(project)
        cmds << 'rdm' if [:s, :t].include?(project)

        `tmux send-keys "#{cmds.join('; ')}" C-m`
      end

      # Run server
      `tmux send-keys "#{start_server}" C-m`
    end
  end
end
