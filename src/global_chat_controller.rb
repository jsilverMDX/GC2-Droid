require 'socket'

class GlobalChatController
  attr_accessor :chat_token,
  :chat_buffer,
  :nicks, :handle,
  :handle_text_field,
  :connect_button,
  :server_list_window,
  :chat_window,
  :chat_window_text,
  :chat_message,
  :nicks_table,
  :application,
  :scroll_view,
  :last_scroll_view_height,
  :host,
  :port,
  :password,
  :ts,
  :msg_count

  # WARNING: always log with newline \n

  def initialize(activity)
    @activity = activity
    @mutex = Mutex.new
    @sent_messages = []
    @sent_msg_index = 0
  end

  def cleanup
    @activity.run_on_ui_thread do
      @chat_message.setText('')
      @nicks = []
      reload_nicks
      @chat_window_text.setText('')
    end
  end

  def sendMessage(message)
    # begin
    @activity.run_on_ui_thread do
      @message = @chat_message.getText.toString
      if @message != ""
        post_message(@message)
        @chat_message.setText('')
      end
    end
    # rescue
    # autoreconnect
    # end
  end

  def scroll_the_scroll_view_down
    # FIXME: Android
    # y = self.scroll_view.documentView.frame.size.height - self.scroll_view.contentSize.height
    # self.scroll_view.contentView.scrollToPoint(NSMakePoint(0, y))
  end

  def update_chat_views
    @activity.run_on_ui_thread do
      if !(@chat_window_text == nil)
        @chat_window_text.setText(@chat_buffer)
      end
    end
    if !(@scroll_view == nil)
      Thread.new do
        sleep 0.1
        @activity.run_on_ui_thread do
          @scroll_view.fullScroll(130) # wrong
        end
      end
    end
  end

  def sign_on
    log "connecting to #{@host}:#{@port}\n"
    # begin
    @ts = TCPSocket.open(@host, @port)
    # rescue
    #   log("Could not connect to GlobalChat server. Will retry in 5 seconds.")
    #   sleep 5
    #   return false
    # end
    @last_ping = Time.now # fake ping
    sign_on_array = @password == "" ? [@handle] : [@handle, @password]
    puts "send message SIGNON"
    send_message("SIGNON", sign_on_array)
    puts "send message SIGNON...OK"
    begin_async_read_queue
    $autoreconnect = true
    true
  rescue Exception
    puts "Exception signing on: #{$!.message}"
    puts $!.backtrace
  end

  # def autoreconnect
  #   unless $autoreconnect == false
  #     loop do
  #       if sign_on #start_client
  #         break
  #       end
  #     end
  #   end
  # end


  def return_to_server_list
    puts "returned to server list"
    $autoreconnect = false
    # @ts.disconnect
    @ts.close
    #... load SL activity
  rescue Exception
    puts "Exception closing connection: #{$!}"
    puts $!.backtrace
  end

  def update_and_scroll
    update_chat_views
    scroll_the_scroll_view_down
  end

  def begin_async_read_queue
    puts "begin_async_read_queue"
    Thread.new do
      loop do
        data = ""
        # sleep 0.1
        # begin
        puts "read line"
        while line = @ts.recv(1)
          puts "line: #{line.inspect}"
          # raise if @last_ping < Time.now - 30
          break if line == "\0"
          data += line
        end
        # rescue
        #   autoreconnect
        #   break
        # end

        parse_line(data)
      end
    end
  end

  def reload_nicks
    @activity.run_on_ui_thread do
      if @nicks
        @activity.update_nicks(@nicks)
      end
    end
  end

  def update_title(title)
    @activity.run_on_ui_thread do
      if @server_name
        @activity.update_title(title)
      end
    end
  end

  def parse_line(line)
    puts "parse_line: #{line.inspect}"
    parr = line.split("::!!::")
    command = parr.first
    if command == "TOKEN"
      @chat_token = parr[1]
      @handle = parr[2]
      @server_name = parr[3]
      update_title(@server_name)
      log "Connected to #{@server_name} \n"
      ping # fix for GlobalChatNet
      get_log
      $connected = true
    elsif command == "PONG"
      @nicks = parr.last.split("\n")
      reload_nicks
      ping
    elsif command == "HANDLES" # deprecated?
      @nicks = parr.last.split("\n")
      reload_nicks
    elsif command == "BUFFER"
      buffer = parr[1]
      unless buffer == "" || buffer == nil
        output_to_chat_window(buffer)
      end
    elsif command == "SAY"
      handle = parr[1]
      msg = parr[2]
      add_msg(handle, msg)
    elsif command == "JOIN"
      handle = parr[1]
      output_to_chat_window("#{handle} has entered\n")
    elsif command == "LEAVE"
      handle = parr[1]
      output_to_chat_window("#{handle} has exited\n")
    elsif command == "ALERT"
      # if you get an alert
      # you logged in wrong
      # native alerts
      # are not part of
      # chat experience
      text = parr[1]
      log("#{text}\n")

      # exit
      # @ts.close
    end
  end

  def send_message(opcode, args)
    puts "send_message: #{opcode} #{args}"
    msg = opcode + "::!!::" + args.join("::!!::")
    sock_send @ts, msg
  end

  def sock_send io, msg
    # begin
    puts "sock_send: #{msg}"
    msg = "#{msg}\0"
    io.send msg, 0
    # rescue
    # autoreconnect
    # end
  end

  def post_message(message)
    puts "post_message: #{message.inspect}"
    return if (message.nil? || message.empty?)
    send_message "MESSAGE", [message, @chat_token]
    add_msg(self.handle, message)
  end

  def add_msg(handle, message)
    puts "add_message: #{message}"
    if @handle != handle && message.include?(@handle)
      # vibrate
      getSystemService(Context::VIBRATOR_SERVICE).vibrate(300)
      @msg_count ||= 0
      @msg_count += 1
    end
    msg = "#{handle}: #{message}\n"
    output_to_chat_window(msg)
  end

  def get_log
    send_message "GETBUFFER", [@chat_token]
  end

  def get_handles
    send_message "GETHANDLES", [@chat_token]
  end

  def sign_out
    send_message "SIGNOFF", [@chat_token]
    @ts.close
  end

  def ping
    @last_ping = Time.now
    send_message("PING", [@chat_token])
  end

  def log str
    output_to_chat_window(str)
  end

  def output_to_chat_window str
    puts "chat output: #{str.inspect}"
    @mutex.synchronize do
      @chat_buffer += "#{str}"
      update_and_scroll
    end
  end


end
