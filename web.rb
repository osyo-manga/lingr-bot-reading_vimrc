# -*- encoding: UTF-8 -*-
# https://github.com/raa0121/raa0121-lingrbot/blob/master/dice.rb
require 'sinatra'
require 'json'
require "mechanize"
load "reading_vimrc.rb"


get '/' do
	"Hello, world"
end


reading_vimrc = ReadingVimrc.new

reading_vimrc_help = <<"EOS"
vimrc読書会で発言した人を集計するための bot です

!reading_vimrc {command}

"start"  : 集計の開始、"member" は "reset" される
"stop"   : 集計の終了
"status" : ステータスの出力
"member" : "start" ～ "stop" の間に発言した人を列挙
"member_with_count" : "member" に発言数も追加して列挙
"reset"  : "member" をリセット
"help"   : 使い方を出力
EOS


get '/reading_vimrc' do
	"status: #{reading_vimrc.status}<br>members<br>#{reading_vimrc.members.sort.join('<br>')}"
end


post '/reading_vimrc' do
	content_type :text
	json = JSON.parse(request.body.string)
	json["events"].select {|e| e['message'] }.map {|e|
		text = e["message"]["text"]
		if /^!reading_vimrc[\s　]start$/ =~ text
			reading_vimrc.start
			return "started"
		end
		if /^!reading_vimrc[\s　]stop$/ =~ text
			reading_vimrc.stop
			return "stoped"
		end
		if /^!reading_vimrc[\s　]status$/ =~ text
			return reading_vimrc.status
		end
		if /^!reading_vimrc[\s　]member$/ =~ text
			members = reading_vimrc.members
			return members.empty? ? "だれもいませんでした" : members.sort.join("\n")
		end
		if /^!reading_vimrc[\s　]member_with_count$/ =~ text
			names = reading_vimrc.messages.map {|mes| mes[:name] }
			if names.empty?
				return "だれもいませんでした"
			end
			return names.inject(Hash.new(0)) { 
				|h,o| h[o]+=1; h
			}.sort_by { |k,v| -v }.map { |name, count|
				"#{"%03d" % count}回 : #{name}"
			}.join("\n")
		end
		if /^!reading_vimrc[\s　]reset$/ =~ text
			return reading_vimrc.reset
		end
		if /^!reading_vimrc[\s　]help$/ =~ text
			return reading_vimrc_help
		end

		if /^!reading_vimrc[\s　]*(.+)$/ =~ text
			return "Not found command"
		end
		reading_vimrc.add({:name => e["message"]["nickname"], :text => text})
	}
	return ""
end


