# -*- encoding: UTF-8 -*-
# https://github.com/raa0121/raa0121-lingrbot/blob/master/dice.rb
require 'sinatra'
require 'json'
require "mechanize"


get '/' do
	"Hello, world"
end


class ReadingVimrc
	def initialize
		@is_running_ = false
		@messages = []
	end

	def is_running?
		@is_running_
	end

	def start
		@is_running_ = true
		@messages = []
	end

	def stop
		@is_running_ = false
	end
	
	def members
		@messages.map {|mes| mes[:name] }.uniq
	end

	def status
		is_running? ? "started" : "stopped"
	end

	def add(message)
		if is_running?
			@messages << message
		end
	end
end


reading_vimrc = ReadingVimrc.new

reading_vimrc_help = <<"EOS"
vimrc読書会で発言した人を集計するための bot です

!reading_vimrc {command}

"start"  : 集計の開始
"stop"   : 集計の終了
"status" : ステータスの出力
"member" : "start" ～ "stop" の間に発言した人を列挙
"help"   : 使い方を出力
EOS


get '/reading_vimrc' do
	"status: #{reading_vimrc.status}<br>members<br>#{reading_vimrc.members.join('<br>')}"
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
			return members.empty? ? "だれもいませんでした" : members.join("\n")
		end
		if /^!reading_vimrc[\s　]help$/ =~ text
			return reading_vimrc_help
		end
		if /^!reading_vimrc[\s　]*(.+)$/ =~ text
			return "Not found command"
		end
		reading_vimrc.add({:name => e["message"]["speaker_id"], :text => text})
	}
	return ""
end


