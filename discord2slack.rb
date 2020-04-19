require 'slack-ruby-client'
require 'discordrb'
require "pp"
require 'open-uri'
require 'rubygems'
require 'rmagick'
require 'gyazo'
require 'aws-sdk'

# discord bot info
TOKEN = "NzAwMjg4OTgwNzk2ODMzODIz.XpgzkQ.lm9TilYh3CI7nHHGpLcPt3akgN8"
CLIENT_ID = 700288980796833823

# slack bot info
Slack.configure do |conf|
    conf.token = 'xoxb-136542423521-1090684378256-o3awytx92JKfN1MPRhoDXpdI'
end

# slack client
client = Slack::Web::Client.new
client.auth_test

# discord bot
bot = Discordrb::Commands::CommandBot.new token: TOKEN, client_id: CLIENT_ID, prefix:'/'

# gyazo bot
gyazo = Gyazo::Client.new access_token: 'a23443064be80b54f95fb0e563d010c40e90a1f2fa6bc5aa963f2f6909473e01'

# s3 configuration
Aws.config.update({
    region: 'us-west-2',
    credentials: Aws::Credentials.new("AKIAJPLLSRQS2JPD2C4Q", "+czldk2qBd58SEUoj5maFnRH5o6jmg8pTJQCsHpO")})
s3 = Aws::S3::Resource.new
bucket = s3.bucket('discord2slack-for-dp9')

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
    srv.users.each do |user|
        user_info[user.id] = user.name
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
    voice_status.each do |channel, users|
        if !(users == []) then
            imagelist = []
            users.each do |user|
                avatar = bucket.object("avatar/#{user}.jpg")
                imagelist.push(avatar.key)
            end
            avatars = Magick::ImageList.new(*imagelist)
            avatars = avatars.append(false)
            bg = bucket.object("bg/#{channel}.jpg")
            pp bg
            bg = Magick::Image.read(bg.key).first
            bg.composite!(avatars, Magick::SouthWestGravity, Magick::OverCompositeOp)
            bg.write("notification/#{channel}.jpg")
            #notification_img = bucket.object("notification/#{channel}.jpg")
            res = gyazo.upload imagefile: "notification/#{channel}.jpg"
            pp res[:permalink_url]
            #client.chat_postMessage(channel: '#discord_state', text: "Now #{users.join(', ')} in ##{channel}\n#{res[:permalink_url]}")
        end
    end
end