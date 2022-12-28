class LineBotController < ApplicationController
  protect_from_forgery except: [:callback]

  def callback
    # POSTリクエストからメッセージボディを文字列として取得する
    body = request.body.read

    # 署名の検証
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      return head :bad_request
    end

    # bodyのevents以下をハッシュに直して格納する
    events = client.parse_events_from(body)

    # eventを取り出し、テキストかどうか評価して処理する
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = {
            type: 'text',
            text: event.message['text'] # 送られてきたテキストをそのまま代入
          }
          client.reply_message(event['replyToken'], message)
        end
      end
    end
    head :ok
  end

  private

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end
