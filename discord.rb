require 'slack-ruby-client'
require 'discordrb'
require "pp"

# discord bot info
TOKEN = "NzAwMjg4OTgwNzk2ODMzODIz.XpgzkQ.lm9TilYh3CI7nHHGpLcPt3akgN8"
CLIENT_ID = 700288980796833823

# slack bot info
Slack.configure do |conf|
    conf.token = 'xoxb-136542423521-1090684378256-o3awytx92JKfN1MPRhoDXpdI'
end

# Clientのインスタンス生成
client = Slack::Web::Client.new
client.auth_test

# bot
bot = Discordrb::Commands::CommandBot.new token: TOKEN, client_id: CLIENT_ID, prefix:'/'

voice_status = Hash.new
user_info = Hash.new
bot.ready do |event|
    bot.servers.each_value do |srv|
        #ボイスチャンネルの{id => name}のhashを作成
        srv.voice_channels.each do |channel|
            voice_status[channel.name] = []
        end
        #ユーザーの{id => name}のhashを作成
        srv.users.each do |user|
            user_info[user.id] = user.name
        end
    #サーバからボイスチャンネルにいるユーザーを取得
        active_users = []
        pp srv.voice_states
        srv.voice_states.each do |user_id, status|
        #アクティブなチャンネルの名前を取得
            active_channel_name = status.voice_channel.name
        #アクティブユーザーの名前を取得
            #active_users.push(user_info[user_id])
            voice_status[active_channel_name].push(user_info[user_id])
        end
        pp voice_status
    end

    voice_status.each do |channel, users|
        if !(users == []) then
            client.chat_postMessage(channel: '#discord_state', text: "Now #{users.join(', ')} in ##{channel}")
        end
    end
end

bot.run
client.start!