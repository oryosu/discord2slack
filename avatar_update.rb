require 'discordrb'
require 'open-uri'
require 'rmagick'
require 'aws-sdk'

# discord bot info
TOKEN = ENV["DISCORD_BOT_TOKEN"]
CLIENT_ID = ENV["DISCORD_BOT_CLIENT_ID"]
# discord bot
bot = Discordrb::Commands::CommandBot.new token: TOKEN, client_id: CLIENT_ID, prefix:'/'

# s3 configuration
Aws.config.update({
    region: 'us-east-2',
    credentials: Aws::Credentials.new(ENV["AWS_ACCESS_KEY"], ENV["AWS_SECRET_KEY"])})
s3 = Aws::S3::Resource.new
bucket = s3.bucket('discord2slack-for-dp9')

bot.run(async=true)

bot.servers.each_value do |srv|
    srv.users.each do |user|
        pp user.avatar_url
        obj = s3.bucket('discord2slack-for-dp9').object("orig/#{user.name}.jpg")
        open(user.avatar_url) do |img|
            obj.put(body: img)
        end
        orig = bucket.object("orig/#{user.name}.jpg")
        orig.download_file("orig/#{user.name}.jpg")
        img = Magick::Image.read(orig.key).first
        # 新しいサイズへ変更
        img = img.resize_to_fit(128,128)
        # 新画像保存
        img.write("avatar/#{user.name}.jpg")
        # s3へupload
        obj = s3.bucket('discord2slack-for-dp9').object("avatar/#{user.name}.jpg")
        obj.upload_file("avatar/#{user.name}.jpg")
    end
end