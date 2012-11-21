require 'ruboto/widget'
require 'ruboto/util/toast'
require 'ruboto/activity'


ruboto_import_widgets :LinearLayout, :TextView, :ListView, :EditText

class GlobalChatActivity
  require 'global_chat_controller'

  def on_create(bundle)
    super
    set_title 'GlobalChat2'

    # Thread.new do

    $activity.run_on_ui_thread do
      $gcc = GlobalChatController.new

      self.content_view =
      linear_layout :orientation => :vertical do
        linear_layout :layout => {:width= => :fill_parent, :height= => 310} do
          nicks_table = list_view :list => ['jsilver'], :layout => {:width= => 200, :height= => :fill_parent}
          chat_window_text = text_view :text => '', :layout => {:width= => 280, :height= => :fill_parent}
          $gcc.nicks_table = nicks_table
          $gcc.chat_window_text = chat_window_text
        end
        linear_layout :orientation => :vertical, :layout => {:width= => :fill_parent, :height= => 60} do
          chat_message = edit_text :text => '', :layout => {:width= => :fill_parent}
          $gcc.chat_message = chat_message
        end
      end

    end


    $gcc.host = $host
    $gcc.port = $port
    $gcc.handle = $handle
    $gcc.password = $password
    $gcc.autoreconnect if $gcc.sign_on == false

  end

  # end


end
