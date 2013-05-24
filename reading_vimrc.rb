# -*- encoding: UTF-8 -*-

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
    reset
  end

  def stop
    @is_running_ = false
  end

  def reset
    @messages = []
  end

  def members
    @messages.map {|mes| mes[:name] }.uniq
  end

  def messages
    @messages
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

