require 'slack-ruby-client'
require 'discordrb'
require 'timers'

Slack.configure do |conf|
    conf.token = 'xoxb-136542423521-1090684378256-o3awytx92JKfN1MPRhoDXpdI'
end

# RTM Clientのインスタンス生成
client = Slack::Web::Client.new
client.auth_test
#client.chat_postMessage(channel: '#discord_state', text: 'Hello World', as_user: true)

# slackに接続できたときの処理
#client.on :hello do
    #puts('connected!')
#    puts "Successfully connected, welcome '#{client.self.name}' to the '#{client.team.name}' team at https://#{client.team.domain}.slack.com."
#end

# discord bot info
TOKEN = "NzAwMjg4OTgwNzk2ODMzODIz.XpgzkQ.lm9TilYh3CI7nHHGpLcPt3akgN8"
CLIENT_ID = 700288980796833823

# bot
bot = Discordrb::Commands::CommandBot.new token: TOKEN, client_id: CLIENT_ID, prefix:'/'

voice_channel_status = Hash.new
# 誰かがvoice channelに出入りしたら発火
bot.voice_state_update do |event|
    # 発火させたユーザー名を取得
    user = event.user.name

    # もしデータが空だと抜けていったチャンネルを取得
    if event.channel == nil then
        # チャンネル名を取得
        channel_name = event.old_channel.name
        #client.chat_postMessage(channel: "#discord_state", text: "now #{user} leaves #{channel_name}", as_user: true)
        if !(voice_channel_status[channel_name] == nil) then
            voice_channel_status[channel_name].slice!(user)
            voice_channel_status.delete_if{|key, value|
                value == nil
            }
        end
        voice_channel_status.each{|key, value|
            client.chat_postMessage(channel: '#discord_state', text: "Now #{value} in ##{key}")
            }
    else
        # チャンネル名を取得
        channel_name = event.channel.name
        #client.chat_postMessage(channel: "#discord_state", text: "now #{user} joins #{channel_name}", as_user: true)
        voice_channel_status.each{|key, value|
            client.chat_postMessage(channel: '#discord_state', text: "Now #{value} in ##{key}")
            }
        if voice_channel_status.key?(channel_name) then
            voice_channel_status[channel_name] = voice_channel_status[channel_name] + ' ,' + user
        else
            voice_channel_status[channel_name] = user
        end
    end
end

#timers = Timers::Group.new

#timers.now_and_every(5) { 
#if voice_channel_status.length > 0 then
#    voice_channel_status.each{|key, value|
#        client.postMessage(channel: '#discord_state', text: "Now #{value} in ##{key}")
#    }
#end
#    }
#10.times { timers.wait }

# discord bot start
bot.run

# slcakbot start
client.start!