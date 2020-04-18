!/bin/sh

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

cd ~/projects/discord2slack
ruby discord2slack.rb