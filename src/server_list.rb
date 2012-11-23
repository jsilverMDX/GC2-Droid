require 'ruboto/widget'
require 'ruboto/util/toast'
require 'ruboto/activity'


ruboto_import_widgets :Button, :LinearLayout, :TextView, :ListView, :EditText, :ScrollView

require 'global_chat'

class ServerList

  attr_accessor :handle_text, :password_text, :host_text, :port_text

  def load_preferences
    e = getPreferences(Context::MODE_PRIVATE)
    handle = e.getString("Handle", "")
    port = e.getString("Port", "")
    host = e.getString("Host", "")
    { :handle => handle, :port => port, :host => host }
  end

  def save_preferences(options)
    e = getPreferences(Context::MODE_PRIVATE).edit
    e.putString("handle", options[:handle])
    e.putString("host", options[:host])
    e.putString("port", options[:port])
    e.commit
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
        {:host => par[1], :name => par[0], :port => par[2]}
      end

      @names = @server_list_hash.map { |i| i[:name] }

      $activity.run_on_ui_thread do
        self.content_view =
        linear_layout :orientation => :vertical do

          scroll_view do
            @server_list = list_view(:list => @names, :on_item_click_listener => proc {
              |av, v, p, i|
              host = @server_list_hash[p][:host]
              port = @server_list_hash[p][:port]
              @host_text.setText host
              @port_text.setText port
            })
          end

          # pref = load_preferences
          linear_layout :orientation => :vertical do

            linear_layout :orientation => :horizontal do
              text_view :text => "Handle"
              @handle_text = edit_text :width => 200, :text => 'jsilver' #pref[:handle]
            end

            linear_layout :orientation => :horizontal do
              text_view :text => "Host"
              @host_text = edit_text :width => 350, :text => 'globalchat2.net' #pref[:host]
            end

            linear_layout :orientation => :horizontal do
              text_view :text => "Port"
              @port_text = edit_text :width => 200, :text => '9994' #pref[:port]
            end

            linear_layout :orientation => :horizontal do
              text_view :text => "Password"
              @password_text = edit_text :width => 200, :transformation_method => android.text.method.PasswordTransformationMethod.new
            end

            linear_layout :orientation => :horizontal do
              button :text => "Connect", :on_click_listener => proc { start_gc2_activity }
              button :text => "Refresh", :on_click_listener => proc { refresh_me }
            end

          end

        end
      end
    }
  end


  def start_gc2_activity
    save_preferences(:handle => @handle_text.getText.toString, :host => @host_text.getText.toString, :port => @port_text.getText.toString)
    i = android.content.Intent.new
    i.setClassName($package_name, 'org.ruboto.RubotoActivity')
    configBundle = android.os.Bundle.new
    configBundle.put_string('ClassName', 'GlobalChatActivity')
    i.putExtra('RubotoActivity Config', configBundle)
    # intent.putExtra("host", @host_text.getText.toString)
    $host = @host_text.getText.toString
    # intent.putExtra("port", @port_text.getText.toString)
    $port = @port_text.getText.toString
    # intent.putExtra("handle", @handle_text.getText.toString)
    $handle = @handle_text.getText.toString
    # intent.putExtra("password", @password_text.getText.toString)
    $password = @password_text.getText.toString

    startActivity(i)
  end

end
