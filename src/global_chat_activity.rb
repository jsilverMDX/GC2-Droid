require 'ruboto/widget'
require 'ruboto/util/toast'
require 'ruboto/activity'
require 'global_chat_controller'

ruboto_import_widgets :LinearLayout, :TextView, :ListView, :EditText

class GlobalChatActivity
  def on_create(bundle)
    super
    set_title 'GlobalChat2'

    @gcc = GlobalChatController.new(self)

    self.content_view = linear_layout :orientation => :vertical do
      linear_layout :layout => {:weight= => 1, :width= => :fill_parent, :height= => :match_parent} do
        @nicks_table = list_view :list => [], :background_color => android.graphics.Color::BLUE,
        :layout => {:width= => 200, :height= => :fill_parent},
        :on_item_click_listener => proc { |av, v, p, i| @chat_message.text = "#{v.text}: " ; @chat_message.setSelection(@chat_message.getText().length()) }
        @scroll_view = scroll_view(:layout => {:width= => :fill_parent, :height= => :fill_parent}) do
          @chat_window_text = text_view :text => '', :margins => [10,0,0,100], :layout => {:width= => :fill_parent, :height= => :fill_parent}
        end
      end
      linear_layout :orientation => :horizontal, :layout => {:width= => :fill_parent, :height= => :wrap_content} do
        @chat_message = edit_text :text => '', :layout => {:weight= => 1, :width= => :fill_parent, :height= => :wrap_content}
        @send_button = button :text => 'Send', :layout => {:width= => :wrap_content, :height= => :wrap_content},
        :on_click_listener => proc {Thread.start{@gcc.post_message(@chat_message.text.to_s)};@chat_message.text = ''}
      end
    end

    @gcc.host = intent.extras.get_string('host')
    @gcc.port = intent.extras.get_string('port')
    @gcc.handle = intent.extras.get_string('handle')
    @gcc.password = intent.extras.get_string('password')

    @gcc.nicks_table = @nicks_table
    @gcc.chat_window_text = @chat_window_text
    @gcc.chat_message = @chat_message
    @gcc.scroll_view = @scroll_view
    @gcc.nicks = []
    @gcc.chat_buffer = ""

    Thread.new do
      @gcc.sign_on
    end

    # go landscape
    # setRequestedOrientation(0)
  end

  def on_resume
    super
    @gcc.nicks
  end

  def on_pause
    super
    @gcc.return_to_server_list
  end

  def update_nicks(nicks)
    @nicks_table.adapter.clear
    nicks.each{|n| @nicks_table.adapter.add(n)}
  end

  def update_title(title)
    set_title title
  end
end
