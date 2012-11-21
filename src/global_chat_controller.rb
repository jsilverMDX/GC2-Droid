require 'uri'
require 'socket'

class GlobalChatController



  attr_accessor :chat_token,
  :chat_buffer,
  :nicks,
  :handle,
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
  :activity


  def initialize
    @mutex = Mutex.new
    @nicks = []
    @chat_buffer = ""
  end

  def cleanup
    @chat_message.setText('')
    @nicks = []
    reload_nicks
    @chat_window_text.setText('')
  end

  def sendMessage
    begin
      @activity.run_on_ui_thread do
        @message = @chat_window_text.getText.toString
        if @message != ""
          post_message(@message)
          @chat_window_text.setText('')
        end
      end
    rescue
      autoreconnect
    end
  end

  def scroll_the_scroll_view_down
    # FIXME: Android
    # y = self.scroll_view.documentView.frame.size.height - self.scroll_view.contentSize.height
    # self.scroll_view.contentView.scrollToPoint(NSMakePoint(0, y))
  end

  def update_chat_views
    @activity.run_on_ui_thread do
      @chat_window_text.setText(@chat_buffer)
    end
  end

  def sign_on

    return if (@host == "" || @port == "")

    log "Connecting to: #{@host} #{@port}"
    Thread.new do
      begin
        @ts = TCPSocket.new(@host, @port)
      rescue
        log "Could not connect to GlobalChat server."
        sleep 5
        return false
      end
      sign_on_array = @password == "" ? [@handle] : [@handle, @password]
      send_message("SIGNON", sign_on_array)
      begin_async_read_queue
    end
    $autoreconnect = true
    true
  end

  def return_to_server_list
    $autoreconnect = false
    @ts.disconnect
    #... load SL activity
  end

  def update_and_scroll
    update_chat_views
    scroll_the_scroll_view_down
  end

  def begin_async_read_queue
    # changed from Queue to Thread
    Thread.new do
      loop do
        sleep 0.1
        data = ""
        begin
          while line = @ts.recv(1)
            break if line == "\0"
            data += line
          end
        rescue
          autoreconnect
          break
        end
        p data
        parse_line(data)
      end
    end
  end

  def reload_nicks
    @activity.run_on_ui_thread do
      if @nicks_table && @nicks
        @nicks_table.reload_list(@nicks)
      end
    end
  end

  def parse_line(line)
    parr = line.split("::!!::")
    command = parr.first
    if command == "TOKEN"
      $autoreconnect = true
      @last_ping = Time.now # fake ping
      @chat_token = parr[1]
      @handle = parr[2]
      get_handles
      get_log
      $connected = true
    elsif command == "PONG"
      @nicks = parr.last.split("\n")
      reload_nicks
      ping
    elsif command == "HANDLES"
      @nicks = parr.last.split("\n")
      reload_nicks
    elsif command == "BUFFER"
      buffer = parr[1]
      unless buffer.nil?
        @chat_buffer = buffer
        update_and_scroll
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
      $autoreconnect = false
      text = parr[1]
      log("#{text}\n") do
        return_to_server_list
      end
    end
  end


  def send_message(opcode, args)
    msg = opcode + "::!!::" + args.join("::!!::")
    sock_send @ts, msg
  end

  def sock_send io, msg
    begin
      p msg
      msg = "#{msg}\0"
      io.send msg, 0
    rescue
      autoreconnect
    end
  end



  def autoreconnect
    Thread.new do
      unless $autoreconnect == false
        loop do
          break if $connected == true
          run_on_main_thread do
            output_to_chat_window("Could not connect to GlobalChat. Will retry in 5 seconds..")
            NSLog "connected? #{$connected}"
            sign_on
          end
          sleep 5
        end
      end
    end
  end

  def post_message(message)
    send_message "MESSAGE", [message, @chat_token]
    add_msg(self.handle, message)
  end

  def add_msg(handle, message)
    if @handle != handle && message.include?(@handle)
      # FIXME: Android
      #NSBeep()
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

  def log str
    # NSLog str
    p str
    output_to_chat_window(str)
  end

  def ping
    # sleep 3
    @last_ping = Time.now
    send_message("PING", [@chat_token])
  end

  def output_to_chat_window str
    @mutex.synchronize do
      @chat_buffer += "#{str}"
      update_and_scroll
    end
  end

end