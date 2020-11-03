require 'discordrb'
require 'open-uri'
require 'rmagick'
require 'aws-sdk'

# discord bot info
TOKEN = ENV["DISCORD_BOT_TOKEN"]
CLIENT_name = ENV["DISCORD_BOT_CLIENT_name"]
# discord bot
bot = Discordrb::Commands::CommandBot.new token: TOKEN, client_name: CLIENT_name, prefix:'/'

# s3 configuration
Aws.config.update({
    region: 'us-east-2',
    credentials: Aws::Credentials.new(ENV["AWS_ACCESS_KEY"], ENV["AWS_SECRET_KEY"])})
s3 = Aws::S3::Resource.new
bucket = s3.bucket('discord2slack-for-dp9')

bot.run(async=true)

bot.servers.each_value do |srv|
    srv.voice_states.each do |user_id, status|
        pp bot.user(user_id).avatar_url
        #obj = s3.bucket('discord2slack-for-dp9').object("orig/#{user.name}.jpg")
        #File.open("./tmp/#{user.name}.jpg", "wb") do |file|
        urlimg = URI.open("#{bot.user(user_id).avatar_url(format='jpg')}")
        #URI.open("#{user.avatar_url}") do |img|
        #        file.puts img.read
        #    end
        #end
        image = Magick::ImageList.new
        image.from_blob(urlimg.read)
        # 新しいサイズへ変更
        resize = image.resize_to_fit(128,128)
        # 新画像保存
        resize.write("avatar/#{bot.user(user_id).name}.jpg")
        # s3へupload
        obj = s3.bucket('discord2slack-for-dp9').object("avatar/#{bot.user(user_id).name}.jpg")
        obj.upload_file("avatar/#{bot.user(user_id).name}.jpg")
    end
end