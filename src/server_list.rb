require 'ruboto/widget'
require 'ruboto/util/toast'
require 'ruboto/activity'
require 'ruboto/util/stack'

require 'pstore'

ruboto_import_widgets :Button, :LinearLayout, :TextView, :ListView, :EditText, :ScrollView

class ServerList
  attr_accessor :handle_text, :password_text, :host_text, :port_text

  def on_stop
    super
    puts "saving preferences"
  end

  def on_create(bundle)
    super
    set_title 'Server List'

    self.content_view = linear_layout :orientation => :vertical do
      @server_list = list_view(
          :list => [], :layout => {:weight= => 1, :height= => :match_parent},
          :on_item_click_listener => proc { |av, v, p, i|
            @handle_text.text = @server_list_hash[p][:name]
            @host_text.text = @server_list_hash[p][:host]
            @port_text.text = @server_list_hash[p][:port]
          })
      linear_layout :orientation => :vertical do
        label_width = 130
        linear_layout :orientation => :horizontal do
          text_view :text => "Handle", :width => label_width
          @handle_text = edit_text :width => :match_parent
        end
        linear_layout :orientation => :horizontal do
          text_view :text => "Host", :width => label_width
          @host_text = edit_text :width => :match_parent
        end
        linear_layout :orientation => :horizontal do
          text_view :text => "Port", :width => label_width
          @port_text = edit_text :width => :match_parent
        end
        linear_layout :orientation => :horizontal do
          text_view :text => "Password", :width => label_width
          @password_text = edit_text :width => :match_parent
        end

        linear_layout :orientation => :horizontal, :width => :match_parent do
          @connect_button = button :text => "Connect", :layout => {:weight= => 1},
                                   :on_click_listener => proc { start_gc2_activity }
          button :text => "Refresh", :layout => {:weight= => 1},
                 :on_click_listener => proc { refresh_me }
        end

      end

    end
  rescue
    puts "Exception creating activity: #{$!}"
    puts $!.backtrace.join("\n")
  end

  def on_resume
    super
    refresh_ui
    load_prefs
  end

  private

  def refresh_ui
    Thread.with_large_stack do
      begin
        require 'net/http'
        @server_list_hash = Net::HTTP.get('nexusnet.herokuapp.com', '/msl').
            split("\n").
            collect do |s|
          par = s.split("-!!!-")
          {:name => par[0], :host => par[1], :port => par[2]}
        end
        @names = @server_list_hash.map { |i| i[:name] }
        run_on_ui_thread{@names.each{|n| @server_list.adapter.add(n)}}
      rescue Exception
        puts "Exception refreshing UI: #{$!}"
        puts $!.backtrace.join("\n")
      end
    end
  end

  def load_prefs
    @pstore = PStore.new("gchat2pro.pstore")
    begin
      @pstore.transaction do
        @handle_text.setText(@pstore["handle"] || "")
        @host_text.setText(@pstore["host"] || "")
        @port_text.setText(@pstore["port"] || "")
      end
    rescue
      puts "no pstore yet"
    end
  end

  def save_prefs
    @pstore.transaction do
      @pstore["handle"] = @handle_text.getText.toString
      @pstore["host"] = @host_text.getText.toString
      @pstore["port"] = @port_text.getText.toString
    end
  end

  def start_gc2_activity
    save_prefs
    i = android.content.Intent.new
    i.set_class_name($package_name, 'org.ruboto.RubotoActivity')
    bundle = android.os.Bundle.new
    bundle.put_string('ClassName', 'GlobalChatActivity')
    i.put_extra("host", @host_text.text.toString)
    i.put_extra("port", @port_text.text.toString)
    i.put_extra("handle", @handle_text.text.toString)
    i.put_extra("password", @password_text.text.toString)
    i.put_extra('Ruboto Config', bundle)
    start_activity(i)
  end

end
