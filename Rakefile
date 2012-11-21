task :boot do
  puts "booting"
  `emulator -avd Android_4.1 -partition-size 200 -no-audio -no-boot-anim`
end

task :off do
  puts "shutdown"
  `adb emu kill`
end

task :send do
  puts 'sending scripts'
  `rake update_scripts:restart`
end

task :subl do
  `sublime_text .`
end

task :log do
  exec('adb logcat')
end

task :manager do
  `android`
end

task :send_text do
  # black magic
  text = ARGV.last
  require 'socket'
  ts = TCPSocket.open('localhost', 5554)
  unless ts.closed?
    ts.puts("sms send 4204206969 #{text}")
  end
  # supplementary magic
  task text.to_sym do ; end
end

task :del do
  # exec('adb uninstall com.jonsoft.globalchat')
  `adb uninstall com.jonsoft.globalchat`
end

task :build do
  Rake::Task['del'].invoke
  Rake::Task['install'].invoke('clean start')
end