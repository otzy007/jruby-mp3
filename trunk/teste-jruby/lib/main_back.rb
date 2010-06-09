######links
#//www.javaworld.com/javaworld/jw-11-2000/jw-1103-mp3.html#resources
#http://kenai.com/projects/jruby/pages/WalkthroughsAndTutorials
#



#Requires do Ruby
#Load Java platform support using JRuby 0.9.1 and later syntax
require 'java'
require 'thread'


#Carrega jars do EMF
Dir["lib/*.jar"].each { |jar| puts jar; require jar }

#imports do Java
include_class "java.io.BufferedReader"
include_class "java.io.FileReader"
include_class 'javax.swing.JFrame'
include_class 'javax.swing.JLabel'
include_class 'javax.swing.JPanel'
include_class 'javax.swing.JButton'
include_class 'java.awt.BorderLayout'
include_class 'java.lang.Runnable'
include_class 'java.net.URL'
include_class 'java.awt.Event'
JFile = java.io.File
include_class 'javax.swing.JFileChooser'
include_class 'java.awt.event.ActionListener'
include_class 'java.lang.System'
include_class 'javax.sound.sampled.AudioFormat'
include_class 'javax.sound.sampled.AudioInputStream'
include_class 'javax.sound.sampled.AudioSystem'
include_class 'javax.sound.sampled.DataLine'
include_class 'javax.sound.sampled.SourceDataLine'

$mutex=Mutex.new
$cv = ConditionVariable.new
$pause = ConditionVariable.new

#Classes e listeners
class Click_Player
  include ActionListener

  def initialize
    @playing=false
    @thread_play=nil
  end

  def actionPerformed(event)
    case (event.getSource)
    when $_btn_search
      self.procurar
    when $_btn_stop
      self.stop
    when $_btn_pause
      self.pause
    end
  end

  def start_play
    puts 'play'
    fc = JFileChooser.new
    return_val = fc.showOpenDialog($_frame);
    if (return_val == JFileChooser::APPROVE_OPTION)
      file = fc.getSelectedFile();
      puts "Opening: " + file.getName() + "."
      @thread_play = Thread.new(file) do |filePlayed|
        puts "frrrrrrrrrp"
        puts filePlayed.getName()
        ######
        begin
          puts nome=filePlayed.getPath()
          puts nome.gsub!('\\','/')
          $_text.setText("tocando " << nome)
          ins = AudioSystem.getAudioInputStream java.net.URL.new("file:///" << nome)
          baseFormat = ins.getFormat()
          decodedFormat = AudioFormat.new(AudioFormat::Encoding::PCM_SIGNED, baseFormat.getSampleRate(), 16, baseFormat.getChannels(),baseFormat.getChannels() * 2, baseFormat.getSampleRate(), false)
          din = AudioSystem.getAudioInputStream(decodedFormat, ins);
          info = DataLine::Info.new(SourceDataLine.java_class, decodedFormat)
          line = AudioSystem::getLine(info)
          unless (line == nil)
            line.open(decodedFormat)
            data = Java::byte[4096].new #constrói array java
            #Start
            line.start()
            nBytesRead=0
            nBytesRead = din.java_send :read, [Java::byte[],Java::int,Java::int],data, 0, 4096
            @playing=true
            $_btn_stop.setEnabled true
            $_btn_pause.setEnabled true
            while (nBytesRead != -1 && @playing)
              line.java_send :write, [Java::byte[],Java::int,Java::int],data,0,nBytesRead
              if @playing
                nBytesRead = din.java_send :read, [Java::byte[],Java::int,Java::int],data, 0, 4096
              else
                nBytesRead=-1
              end
            end
            # Stop
            puts 'cabou'
            line.drain()
            line.stop()
            line.close()
            din.close()
          end
          unless din == nil
            din.java_send :close
          end
          ######
        rescue Exception => err
          puts err
          unless din == nil
            din.java_send :close
          end
          exit 1
        end
      end
    else
      puts "Open command cancelled by user."
    end
  end

  def stop
    puts 'stop'
    @playing=false
    @thread_play.exit
    $_btn_stop.setEnabled false
    $_btn_pause.setEnabled false
    $_text.setText("Selecione um arquivo .mp3 para tocar!")
  end

  def pause
    puts 'pause'
    unless(@thread_play.stop?)
      @thread_play.run
    else
      @thread_play.stop
      $_text.setText("Pause")
    end
  end

end


#Codigo Principal

$_frame = JFrame.new()
_panel = JPanel.new()
_panel.setLayout(BorderLayout.new())
_panel.setBackground(java.awt.Color::white)
$_frame.getContentPane().add(_panel)
$_frame.defaultCloseOperation = JFrame::EXIT_ON_CLOSE
$_btn_search = JButton.new("Procurar")
$_btn_stop = JButton.new("Parar")
$_btn_pause = JButton.new("Pause")
$_btn_stop.setEnabled false
$_btn_pause.setEnabled false
$_text = JLabel.new("Selecione um arquivo .mp3 para tocar!")
_panel.add(BorderLayout::NORTH, $_text)
_panel.add(BorderLayout::WEST, $_btn_search)
_panel.add(BorderLayout::EAST, $_btn_stop)
_panel.add(BorderLayout::CENTER, $_btn_pause)
$_frame.setTitle("JRuby MP3 Player!")
$_frame.pack()
$_frame.setVisible(true)

listener=Click_Player.new()
$_btn_search.addActionListener(listener)
$_btn_stop.addActionListener(listener)
$_btn_pause.addActionListener(listener)
