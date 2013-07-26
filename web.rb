# -*- encoding: UTF-8 -*-
# https://github.com/raa0121/raa0121-lingrbot/blob/master/dice.rb
require 'sinatra'
require 'json'
load "reading_vimrc.rb"



get '/' do
	"Hello, world"
end


OWNER = ["manga_osyo", "thinca", "deris0126", "rbtnn ", "LeafCage "]

def owner?(name)
	!!OWNER.index(name)
end


reading_vimrc = ReadingVimrc.new

reading_vimrc_help = <<"EOS"
vimrc読書会で発言した人を集計するための bot です

!reading_vimrc {command}

"start"   : 集計の開始、"member" は "reset" される（owner）
"stop"    : 集計の終了（owner）
"reset"   : "member" をリセット（owner）
"restore" : "member" を1つ前に戻す（owner）
"status"  : ステータスの出力
"member"  : "start" ～ "stop" の間に発言した人を列挙
"member_with_count" : "member" に発言数も追加して列挙
"help"    : 使い方を出力
EOS


get '/reading_vimrc' do
	"status: #{reading_vimrc.status}<br>members<br>#{reading_vimrc.members.sort.join('<br>')}<br>link: #{reading_vimrc.start_link}<br>"
end

def to_lingr_link(message)
	time = message["timestamp"].match(/(.*)T/).to_a[1].gsub(/-/, '/')
	return "http://lingr.com/room/#{message["room"]}/archives/#{time}/#message-#{message["id"]}"
end


post '/reading_vimrc' do
	content_type :text
	json = JSON.parse(request.body.string)
	json["events"].select {|e| e['message'] }.map {|e|
		text = e["message"]["text"]
		name = e["message"]["nickname"]
		speaker_id = e["message"]["speaker_id"]
		
		if /^=== 第\d+回 vimrc読書会 ===/ =~ text && owner?(speaker_id)
			reading_vimrc.start to_lingr_link(e["message"])
			return "started"
		end
		if /^!reading_vimrc[\s　]start$/ =~ text && owner?(speaker_id)
			reading_vimrc.start to_lingr_link(e["message"])
			return "started"
		end
		if /^!reading_vimrc[\s　]stop$/ =~ text && owner?(speaker_id)
			reading_vimrc.stop
			return "stopped"
		end
		if /^!reading_vimrc[\s　]reset$/ =~ text && owner?(speaker_id)
			reading_vimrc.reset
			return "reset"
		end
		if /^!reading_vimrc[\s　]restore$/ =~ text && owner?(speaker_id)
			reading_vimrc.restore
			return "restore"
		end
		if /^!reading_vimrc[\s　]status$/ =~ text
			return reading_vimrc.status
		end
		if /^!reading_vimrc[\s　]member$/ =~ text
			members = reading_vimrc.members
			return members.empty? ? "だれもいませんでした" : members.sort.join("\n") + "\n" + reading_vimrc.start_link
		end
		if /^!reading_vimrc[\s　]member_with_count$/ =~ text
			names = reading_vimrc.messages.map {|mes| mes[:name] }
			if names.empty?
				return "だれもいませんでした"
			end
			return names.inject(Hash.new(0)) { |h,o| h[o]+=1; h }
				.sort_by {|k,v| -v}.map {|name, count| "#{"%03d" % count}回 : #{name}" }
				.join("\n") + "\n" + reading_vimrc.start_link
		end
		if /^!reading_vimrc[\s　]help$/ =~ text
			return reading_vimrc_help
		end

		if /^!reading_vimrc[\s　]*(.+)$/ =~ text
			return "Not found command"
		end
		reading_vimrc.add({name: name, text: text})
	}
	return ""
end


