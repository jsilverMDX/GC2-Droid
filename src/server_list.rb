require 'ruboto/widget'
require 'ruboto/util/toast'
require 'ruboto/activity'

require 'pstore'

ruboto_import_widgets :Button, :LinearLayout, :TextView, :ListView, :EditText, :ScrollView

class ServerList
  attr_accessor :handle_text, :password_text, :host_text, :port_text

  def load_prefs
    @pstore = PStore.new("gchat2pro.pstore")
    begin
      @pstore.transaction do
        run_on_ui_thread do
          @handle_text.setText(@pstore["handle"] || "")
          @host_text.setText(@pstore["host"] || "")
          @port_text.setText(@pstore["port"] || "")
        end
      end
    rescue
      puts "no pstore yet"
    end
  end

  def save_prefs
    @pstore.transaction do
      run_on_ui_thread do
        @pstore["handle"] = @handle_text.getText.toString
        @pstore["host"] = @host_text.getText.toString
        @pstore["port"] = @port_text.getText.toString
      end
    end
  end

  def on_stop
    super
    puts "saving preferences"
  end

  def on_create(bundle)
    super
    set_title 'Server List'
    refresh_me
  rescue
    puts "Exception creating activity: #{$!}"
    puts $!.backtrace.join("\n")
  end

  def refresh_me
    Thread.new {
      require 'net/http'
      @server_list_hash = Net::HTTP.get('nexusnet.herokuapp.com', '/msl').
          split("\n").
          collect do |s|
        par = s.split("-!!!-")
        {:name => par[0], :host => par[1], :port => par[2]}
      end

      @names = @server_list_hash.map { |i| i[:name] }

      run_on_ui_thread do
        self.content_view =
        linear_layout :orientation => :vertical do

          scroll_view :layout => {:weight= => 2} do
            @server_list = list_view(
                :list => @names, :height => :match_parent,
                :on_item_click_listener => proc { |av, v, p, i|
                  host = @server_list_hash[p][:host]
                  port = @server_list_hash[p][:port]
                  @host_text.setText host
                  @port_text.setText port
                })
          end

          linear_layout :orientation => :vertical do

            linear_layout :orientation => :horizontal do
              text_view :text => "Handle"
              @handle_text = edit_text :width => 200
            end

            linear_layout :orientation => :horizontal do
              text_view :text => "Host"
              @host_text = edit_text :width => 350
            end

            linear_layout :orientation => :horizontal do
              text_view :text => "Port"
              @port_text = edit_text :width => 200
            end

            linear_layout :orientation => :horizontal do
              text_view :text => "Password"
              @password_text = edit_text :width => 200
            end

            load_prefs

            linear_layout :orientation => :horizontal do
              @connect_button = button :text => "Connect", :on_click_listener => proc { start_gc2_activity }
              button :text => "Refresh", :on_click_listener => proc { refresh_me }
            end

          end

        end
      end
    }
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
    i.put_extra('RubotoActivity Config', bundle)
    start_activity(i)
  end

end
