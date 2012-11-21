# require 'ruboto/widget'
# require 'ruboto/util/toast'

# ruboto_import_widgets :Button, :LinearLayout, :TextView, :ListView

class GlobalChatActivity
  require 'global_chat_controller'

  def on_create(bundle)
    super
    set_title 'GlobalChat2'

    @host = $activity.getIntent.getExtras.get("host")
    @port = $activity.getIntent.getExtras.get("port")
    @handle = $activity.getIntent.getExtras.get("handle")
    @password = $activity.getIntent.getExtras.get("password")


    p $activity.getIntent.putExtras($activity.getIntent) #(android.os.Bundle)

    @gca = self

    $activity.run_on_ui_thread do
      @gca.content_view =
      linear_layout :orientation => :vertical do
        linear_layout :layout => {:width= => :fill_parent, :height= => 310} do
          @nicks_table = list_view :layout => {:width= => 141, :height= => :fill_parent}
          @chat_window_text = text_view :layout => {:width= => 339, :height= => :fill_parent}
        end
        linear_layout :orientation => :vertical, :layout => {:width= => :fill_parent, :height= => 60} do
          @chat_message = edit_text :text => '', :layout => {:width= => :fill_parent}
        end
      end
    end

    @gcc = GlobalChatController.new
    @gcc.chat_message = @chat_message
    @gcc.nicks_table = @nicks_table
    @gcc.chat_window_text = @chat_window_text
    @gcc.activity = $activity
    @gcc.host = @host
    @gcc.port = @port
    @gcc.handle = @handle
    @gcc.password = @password
    @gcc.sign_on

  end
end
