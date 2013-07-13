# -*- encoding: UTF-8 -*-

class ReadingVimrc
	attr_reader :start_link
	def initialize
		@start_link = ""
		@is_running_ = false
		@messages = []
		@restore_cache = []
	end

	def running?
		@is_running_
	end

	def start(link = "")
		@is_running_ = true
		@start_link = link
		reset
	end

	def stop
		@is_running_ = false
	end
	
	def reset
		@restore_cache = @messages
		@messages = []
	end

	def members
		@messages.map {|mes| mes[:name] }.uniq
	end

	def messages
		@messages
	end

	def status
		running? ? "started" : "stopped"
	end

	def add(message)
		if running?
			@messages << message
		end
	end

	def restore
		@restore_cache, @messages = @messages, @restore_cache
	end
end

