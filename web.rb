# -*- encoding: UTF-8 -*-
# https://github.com/raa0121/raa0121-lingrbot/blob/master/dice.rb
require 'sinatra'
require 'json'
require "yaml"
require "open-uri"
require 'octokit'
load "reading_vimrc.rb"


OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

get '/' do
	"Hello, world"
end


OWNER = ["manga_osyo", "thinca", "deris0126", "rbtnn", "LeafCage", "haya14busa"]

def owner?(name)
	!!OWNER.index(name)
end


def last_commit_hash(url)
	Octokit.list_commits(Octokit::Repository.from_url(url)).first['sha']
end

def get_yaml(url)
	YAML.load open(url)
end


def next_reading_vimrc
	get_yaml("https://raw.github.com/osyo-manga/reading-vimrc/gh-pages/_data/next.yml")[0]
end


def last_commi_link(vimrc)
	hash = vimrc["hash"] || last_commit_hash(vimrc["url"])
	vimrc["url"].sub(/blob\/master\//, "blob/" + hash + "/")
end


def last_commit_raw_link(vimrc)
	hash = vimrc["hash"] || last_commit_hash(vimrc["url"])
	raw_link = vimrc["url"].sub(/https:\/\/github/, "https://raw.github")
	raw_link.sub(/blob\/master\//, hash + "/")
end


def as_github_link(vimrc)
	hash = vimrc["hash"] || last_commit_hash(vimrc["url"])
	link = vimrc["url"].sub(/blob\/master\//, "blob/" + hash + "/")
	raw_link = vimrc["url"].sub(/https:\/\/github/, "https://raw.github")
	raw_link = raw_link.sub(/blob\/master\//, hash + "/")
	{ :link => link, :raw_link => raw_link, :name => vimrc["name"] }
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
"chop {raw.github url}" : chop に url の内容をポストします（owner）
"chop_url" : chop page
EOS


get '/reading_vimrc' do
	"status: #{reading_vimrc.status}<br>members<br>#{reading_vimrc.members.sort.join('<br>')}<br>link: #{reading_vimrc.start_link}<br>chop: #{reading_vimrc.chop_url}"
end

def to_lingr_link(message)
	time = message["timestamp"].match(/(.*)T/).to_a[1].gsub(/-/, '/')
	return "http://lingr.com/room/#{message["room"]}/archives/#{time}#message-#{message["id"]}"
end



# get '/reading_vimrc/vimrc/markdown' do
# 	content_type :text
# 	wdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
# 	wdays = ["日", "月", "火", "水", "木", "金", "土"]
# 	log = reading_vimrc.start_link
# 	member = reading_vimrc.members.sort
# 	github = reading_vimrc.target.split("/").drop(3)
# 	url = "https://github.com/#{github[0]}"
#
# text = <<"EOS"
# ---
# layout: archive
# title: 第#{ reading_vimrc.id }回 vimrc読書会
# category: archive
# ---
#
# ### 日時
# #{ reading_vimrc.date.strftime("%Y/%m/%d") }(土) 23:00-
#
# ### vimrc
# [#{ github[0] }](#{ url }) さんの vimrc を読みました。
#
# - [vimrc](#{ reading_vimrc.target }) ([ダウンロード](#{ reading_vimrc.download }))
#
# ### 参加者リスト
#
# #{ member.length }名。
#
# #{ member.map{ |m| "- " + m }.join("\n") }
#
# ### ログ
# <#{ reading_vimrc.start_link }>
#
# ### 関連リンク
# EOS
# 	text
# # 	CGI.escapeHTML(text).gsub(/\n/, "<br>")
# end


get '/reading_vimrc/vimrc/yml' do
	content_type :text
	status = next_reading_vimrc
	status["members"] = reading_vimrc.members.sort
	status["log"] = reading_vimrc.start_link
	status["links"] = reading_vimrc.chop_url.empty? ? nil : [reading_vimrc.chop_url]
	if reading_vimrc.target.is_a? Array
		vimrcs  = reading_vimrc.target
	else
		vimrcs  = status["vimrcs"].map(&method(:as_github_link))
	end
	status["vimrcs"] = vimrcs.map{ |vimrc| { "name" => vimrc[:name], "url" => vimrc[:link] } }
# 	status["vimrcs"] = [{ "name" => status["vimrcs"][0]["name"], "url" => reading_vimrc.target }]

	[status].to_yaml[/^---\n((\n|.)*)$/, 1]
end



get '/reading_vimrc/vimplugin/yml' do
	content_type :text
	wdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
	log = reading_vimrc.start_link
	member = reading_vimrc.members.sort
	github = reading_vimrc.target.split("/").drop(3)
	url = "https://github.com/#{github[0]}/#{github[1]}"

	yml = <<"EOS"
- id: #{ reading_vimrc.id }
  date: #{ reading_vimrc.date.strftime("%Y-%m-%d") } 21:00
  plugins:
    - name: #{ github[1] }
      author: #{ github[0] }
      url: #{ url }
      hash: #{ github[3] }
  members:
#{ member.map{ |m| "    - " + m }.join("\n") }
  log: #{ log }
  links:
EOS
	yml
# 	yml.gsub(/\n/, "<br>").gsub(/ /, "&nbsp;")
end



def starting_reading_vimrc(reading_vimrc)
	reading = next_reading_vimrc
	vimrcs  = reading["vimrcs"].map(&method(:as_github_link))

	reading_vimrc.set_target vimrcs
# 	reading_vimrc.set_download raw_link

	<<"EOS"
=== 第#{reading["id"]}回 vimrc読書会 ===
- 途中参加/途中離脱OK。声をかける必要はありません
- 読む順はとくに決めないので、好きなように読んで好きなように発言しましょう
- vimrc 内の特定位置を参照する場合は行番号で L100 のように指定します
- 特定の相手に発言/返事する場合は先頭に username: を付けます
- 一通り読み終わったら、読み終わったことを宣言してください。終了の目安にします
- ただの目安なので、宣言してからでも読み返して全然OKです
#{
if reading["part"] && reading["part"] == "前編"
	<<"EOS"
- 今回は#{reading["part"]}です。終了時間になったら、途中でも強制終了します
- 続きは来週読みます
- いつも通り各自のペースで読むので、どこまで読んだか覚えておきましょう
EOS
elsif reading["part"] && reading["part"] == "中編"
	<<"EOS"
- 今回は#{reading["part"]}です。終了時間になったら、途中でも強制終了します
- 前回参加していた方は続きから、参加していなかったら最初からになります
- 続きは来週読みます
- いつも通り各自のペースで読むので、どこまで読んだか覚えておきましょう
EOS
elsif reading["part"] && reading["part"] == "後編"
	<<"EOS"
- 今回は#{reading["part"]}です。前回参加した人は続きから読んでください
EOS
end
}#{
	vimrcs.map { |vimrc|
		"#{vimrc[:name]}: #{vimrc[:link]}\nDL用リンク: #{vimrc[:raw_link]}"
	}.join("\n")
}
EOS
end


post '/reading_vimrc' do
	content_type :text
	json = JSON.parse(request.body.string)
	json["events"].select {|e| e['message'] }.map {|e|
		text = e["message"]["text"]
		name = e["message"]["nickname"]
		speaker_id = e["message"]["speaker_id"]
		
		if (/^=== 第(\d+)回 vimrc読書会 ===/ =~ text || /^=== 第(\d+)回 Vimプラグイン読書会 ===/ =~ text) && owner?(speaker_id)
			reading_vimrc.start to_lingr_link(e["message"]), $1
			reading_vimrc.set_target   text[/読むプラグイン: (https.*)\n/, 1]
			reading_vimrc.set_target   text[/本日のvimrc: (https.*)\n/, 1]
			reading_vimrc.set_download text[/DL用リンク: (https.*)\n/, 1]
			return "started"
		end
		if /^!reading_vimrc[\s　]start$/ =~ text && owner?(speaker_id)
			reading_vimrc.start to_lingr_link(e["message"])
			return "started"
		end
		if /^!reading_vimrc[\s　]start_reading_vimrc$/ =~ text && owner?(speaker_id)
			reading_vimrc.start to_lingr_link(e["message"])
			return starting_reading_vimrc(reading_vimrc)
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

		if /^!reading_vimrc[\s　]+chop[\s　]+.+$/ =~ text && owner?(speaker_id)
			url = text[/^!reading_vimrc[\s　]+chop[\s　]+(.+)$/, 1]
			chop_url = reading_vimrc.chop(url)
			return chop_url.empty? ? "無効な URL です" : chop_url
		end

		if /^!reading_vimrc[\s　]chop_url$/ =~ text
			chop_url = reading_vimrc.chop_url
			return chop_url.empty? ? "ありません" : chop_url
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


