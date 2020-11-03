require 'slack-ruby-client'
require 'discordrb'
require "pp"
require 'open-uri'
require 'rubygems'
require 'rmagick'
require 'gyazo'
require 'aws-sdk'
require 'date'

# discord bot info
TOKEN = ENV["DISCORD_BOT_TOKEN"]
CLIENT_ID = ENV["DISCORD_BOT_CLIENT_ID"]

# slack bot info
Slack.configure do |conf|
    conf.token = ENV["SLACK_BOT_TOKEN"]
end

# slack client
client = Slack::Web::Client.new
client.auth_test

# discord bot
bot = Discordrb::Commands::CommandBot.new token: TOKEN, client_id: CLIENT_ID, prefix:'/'

# gyazo bot
gyazo = Gyazo::Client.new access_token: ENV["GYAZO_ACCESS_TOKEN"]

# s3 configuration
Aws.config.update({
    region: 'us-east-2',
    credentials: Aws::Credentials.new(ENV["AWS_ACCESS_KEY"], ENV["AWS_SECRET_KEY"])})
s3 = Aws::S3::Resource.new
bucket = s3.bucket('discord2slack-for-dp9')
#pp bucket

###
### process part
###
voice_status = Hash.new
user_info = Hash.new
#bot.disconnected do |event|

#    client.chat_postMessage(channel: '#discord_state', text: "test")
#end

bot.run(async=true)

bot.servers.each_value do |srv|
    #ボイスチャンネルの{id => name}のhashを作成
    srv.voice_channels.each do |channel|
        voice_status[channel.name] = []
    end
    #ユーザーの{id => name}のhashを作成
    #srv.users.each do |user|
    #    user_info[user.id] = user.name
        #File.open("orig/#{user.name}.jpg", "wb") do |file|
        #    open("#{user.avatar_url}") do |img|
        #        file.puts img.read
        #    end
        #end
        #img = Magick::ImageList.new("orig/#{user.name}.jpg")
        # 新しいサイズへ変更
        #img = img.resize_to_fit(128,128)
        # 新画像保存
        #img.write("avatar/#{user.name}.jpg")
    #    end
    
#サーバからボイスチャンネルにいるユーザーを取得
    active_users = []
    pp srv.voice_states
    srv.voice_states.each do |user_id, status|
    #アクティブなチャンネルの名前を取得
        active_channel_name = status.voice_channel.name
        if !(active_channel_name == "大事な話(slack通知なし)") then
    #アクティブユーザーの名前を取得
        #active_users.push(user_info[user_id])
        #    pp bot.user(user_id).username
            voice_status[active_channel_name].push(bot.user(user_id).username)
        end
    end
    pp voice_status
    voice_status.each do |channel, users|
        if !(users == []) then
            imagelist = []
            users.each do |user|
                avatar = bucket.object("avatar/#{user}.jpg")
                avatar.download_file("avatar/#{user}.jpg")
                imagelist.push(avatar.key)
            end
            avatars = Magick::ImageList.new(*imagelist)
            avatars = avatars.append(false)
            bg = bucket.object("bg/#{channel}.jpg")
            bg.download_file("bg/#{channel}.jpg")
            pp bg
            bg = Magick::Image.read(bg.key).first
            bg.composite!(avatars, Magick::SouthWestGravity, Magick::OverCompositeOp)
            t = Time.new
            timestamp = t.strftime("%Y%m%d%H%M%S")
            draw = Magick::Draw.new  
            draw.font = 'Verdana-Bold'
            draw.pointsize = 5
            draw.gravity = Magick::CenterGravity
            draw.annotate(bg, 16, 16, 1250, 0, timestamp)
            pp timestamp
            bg.write("#{channel}.jpg")
            #notification_img = bucket.object("notification/#{channel}.jpg")
            res = gyazo.upload imagefile: "#{channel}.jpg"
            pp res[:permalink_url]
            client.chat_postMessage(channel: '#000_discord', text: "Now #{users.join(', ')} in ##{channel}\n#{res[:permalink_url]}")
            #client.chat_postMessage(channel: '#discord_observer_develop', text: "Now #{users.join(', ')} in ##{channel}\n#{res[:permalink_url]}")
        end
    end
end