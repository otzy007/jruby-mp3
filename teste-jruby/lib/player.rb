# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'java'
require 'thread'


#Carrega jars do EMF
#Dir["lib/*.jar"].each { |jar| puts jar; require jar }

##imports do Java
#include_class "java.io.BufferedReader"
#include_class "java.io.FileReader"
#include_class 'javax.swing.JFrame'
#include_class 'javax.swing.JLabel'
#include_class 'javax.swing.JPanel'
#include_class 'javax.swing.JButton'
#include_class 'java.awt.BorderLayout'
#include_class 'java.lang.Runnable'
#include_class 'java.net.URL'
#include_class 'java.awt.Event'
#JFile = java.io.File
#include_class 'javax.swing.JFileChooser'
#include_class 'java.awt.event.ActionListener'
#include_class 'java.lang.System'
#include_class 'javax.sound.sampled.AudioFormat'
#include_class 'javax.sound.sampled.AudioInputStream'
#include_class 'javax.sound.sampled.AudioSystem'
#include_class 'javax.sound.sampled.DataLine'
#include_class 'javax.sound.sampled.SourceDataLine'

class Player_Thread

  attr_accessor :playing,:thread_play,:current_file
  @@tamanho_buffer = 2048

  def initialize
    @mutex=Mutex.new
    @res=ConditionVariable.new
    #Se tá tocando
    @playing=false
    #Thread que toca
    @thread_play=nil
    #arquivo aberto
    @current_file=nil
    #se tah pausado
    @pause=false
  end


  #Toca o arquivo setado no momento
  def play
    if(@current_file==nil)
      raise Exception,"Arquivo para leitura é nulo!",caller
    end
    @thread_play=Thread.new(@current_file) do |file|
      begin
        #tira do pause, se estiver
        @pause=true;self.pause
        ins = AudioSystem.getAudioInputStream java.net.URL.new("file:///" << file.getPath().gsub('\\','/'))
        baseFormat = ins.getFormat()
        decoded_format = AudioFormat.new(AudioFormat::Encoding::PCM_SIGNED, baseFormat.getSampleRate(), 16, baseFormat.getChannels(),baseFormat.getChannels() * 2, baseFormat.getSampleRate(), false)
        din = AudioSystem.getAudioInputStream(decoded_format, ins);
        info = DataLine::Info.new(SourceDataLine.java_class, decoded_format)
        @line = AudioSystem::getLine(info)
        unless (@line == nil)
          @line.open(decoded_format)
          data = Java::byte[@@tamanho_buffer].new #constrói array java
          #Start
          @line.start()
          n_bytes_lidos=0
          n_bytes_lidos = din.java_send :read, [Java::byte[],Java::int,Java::int],data, 0, @@tamanho_buffer
          @playing=true
          while (n_bytes_lidos != -1 && @playing)
            if(@pause)
              @mutex.synchronize do
                @res.wait(@mutex)
              end
            end
            @line.java_send :write, [Java::byte[],Java::int,Java::int],data,0,n_bytes_lidos
            if(@pause)
              @mutex.synchronize do
                @res.wait(@mutex)
              end
            end
            n_bytes_lidos = din.java_send :read, [Java::byte[],Java::int,Java::int],data, 0, @@tamanho_buffer
            if(@pause)
              @mutex.synchronize do
                @res.wait(@mutex)
              end
            end
          end
          # Stop
          puts 'cabou'
          @line.drain()
          @line.stop()
          @line.close()
          din.close()
        end
      rescue Exception => err
        puts "ECCEPCHUN: " << err
        unless din == nil
          din.java_send :close
        end
      end
    end
  end

  def pause
    if(@pause)
      @mutex.synchronize do
        @res.signal
      end
    end
    @pause=!@pause
  end

  def stop
    @playing=false
  end
end
