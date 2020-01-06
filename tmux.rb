begin
  project = ARGV[0].to_sym
  start = ARGV[1]

  WORKSPACE = {
    bw:  ['~/workspace/tripla_booking_widget', 2, 'yarn server --port 8080'],
    cb:  ['~/workspace/triplabot2.0', 2, 'yarn server --port 8082'],
    cm:  ['~/workspace/tripla_frontend_app', 2, 'yarn server --port 8083'],
    ps:  ['~/workspace/pakku_subbu', 3, 'foreman start'],
    ps3: ['~/workspace/pakku_subbu', 3, ['br -p 7000', 'anycable-go --host=localhost --port=7777 --path=/', 'be anycable']],
    s:   ['~/workspace/ships', 3, 'br -p 4000'],
    sb:  ['~/workspace/tripla_search_bar', 2, 'yarn server --port 8081'],
    sc:  ['~/workspace/site-controller-api', 3, 'br -p 5000'],
    t:   ['~/workspace/tripla', 3, 'br']
  }.freeze

  workspace = '-c ' + WORKSPACE[project][0]
  more_windows = WORKSPACE[project][1]
  start_servers = Array(WORKSPACE[project][2])

rescue
  msg = <<~TEXT

    \t\033[31mTry one of these:\033[0m
    \033[32m
    \truby ~/dotfiles/tmux.rb bw
    \truby ~/dotfiles/tmux.rb cb
    \truby ~/dotfiles/tmux.rb cm
    \truby ~/dotfiles/tmux.rb ps
    \truby ~/dotfiles/tmux.rb s
    \truby ~/dotfiles/tmux.rb sb
    \truby ~/dotfiles/tmux.rb t

    \truby ~/dotfiles/tmux.rb t start
    \033[0m
  TEXT

  abort msg
end

# start servers
`~/start-services` if start == 'start'

`tmux start-server`

`tmux new-session -d -s #{project} -n 1 #{workspace}`

more_windows.times do |i|
  `tmux new-window -t #{project}:#{i + 2} -n #{i + 2} #{workspace}`
end

(more_windows + 1).times do |i|
  if i == 0
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

      # Run server
      `tmux send-keys "#{start_server}" C-m`
    end
  end
end
