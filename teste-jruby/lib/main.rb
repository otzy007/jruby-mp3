######links
#//www.javaworld.com/javaworld/jw-11-2000/jw-1103-mp3.html#resources
#http://kenai.com/projects/jruby/pages/WalkthroughsAndTutorials
#



#Requires do Ruby
#Load Java platform support using JRuby 0.9.1 and later syntax
require 'java'
require 'thread'
require 'player'
##Carrega jars do EMF
Thread.new do
  Dir["lib/*.jar"].each { |jar| require jar }
end

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

class Menu

  def main
    #Interface texto :)
    puts "Rodando"

    e=''
    puts "Digite uma opção"
    while(!(e=gets.chomp)!='sair')
      #chomp pq essa bosta retorna uma quebra de linha no fim
      case e
      when 'sair'
        puts 'FLW'
        exit 0
      when 'list','lista'
        menu_lista
      when 'play'
        menu_play
      end
      puts "Digite uma opção"
    end
  end

  def menu_play
    puts 'play'
    puts "digite o arquivo:"
    entrada_arquivo=""
    entrada_arquivo << gets.chomp.gsub('\\','/')
    file=JFile.new entrada_arquivo

    $player=nil
    if file.exists
      puts 'existes'
      $player=Player_Thread.new
      $player.current_file=file
    end
    e=''
    while(!(e=gets.chomp)!='sair')
      case e
      when 'next'
        puts 'not implemented'
      when 'play'
        puts 'Play!'
        $player.play
      when 'stop'
        puts 'Parando'
        $player.stop
      when 'pause','unpause'
        puts 'Pause'
        $player.pause
      end
      puts 'digite uma opção (play)'
    end
  end

  def menu_lista
    require 'playlist_handler'
    l=Playlist_Handler.new
    puts 'listas'
    e=''
    while(!(e=gets.chomp)!='sair')
      case e
      when 'sair'
        break
      when 'add'
        puts 'digite o nome do arquivo a ser adicionado à lista'
        puts "arquivo adicionado: #{gets.chomp}"
      when 'salvar'
        puts 'digite o nome do arquivo a ser salvo'
        puts "arquivo escolhido: #{gets.chomp}"
      end
      puts 'digite uma opção (lista)'
    end
  end

end

menu=Menu.new
menu.main



class Click_Player
  include ActionListener


  def initialize
    @player=Player_Thread.new
    @fc = JFileChooser.new
    @estado_atual=:inicial
  end

  def actionPerformed(event)
    case (event.getSource)
    when $_btn_search
      self.procurar
    when $_btn_stop
      self.stop
    when $_btn_pause
      self.pause
    when $_btn_play
      self.tocar
    end
  end

  def procurar
    return_val = @fc.showOpenDialog($_frame);
    if (return_val == JFileChooser::APPROVE_OPTION)
      file = @fc.getSelectedFile();
      puts "Opening: " + file.getName() + "."
      if(file.exists)
        @player.current_file=file
        self.muda_estado(:arquivo_aberto)
      end
    else
      puts "Open command cancelled by user."
    end
  end

  def muda_estado novoEstado
    @estado_atual=novoEstado
    case @estado_atual
    when :inicial
      $_btn_search.setEnabled(true)
      $_btn_stop.setEnabled(false)
      $_btn_pause.setEnabled(false)
      $_btn_play.setEnabled(false)
    when :play
      $_text.setText "Tocando " << @player.current_file.getName
      $_btn_search.setEnabled(false)
      $_btn_stop.setEnabled(true)
      $_btn_pause.setEnabled(true)
      $_btn_play.setEnabled(false)
    when :arquivo_aberto
      $_text.setText "Carregado " << @player.current_file.getName
      $_btn_search.setEnabled(true)
      $_btn_stop.setEnabled(false)
      $_btn_pause.setEnabled(false)
      $_btn_play.setEnabled(true)
    when :stop
      $_text.setText "Carregado " << @player.current_file.getName
      self.muda_estado :arquivo_aberto
    end
  end

  def tocar
    @player.play
    self.muda_estado :play
  end

  def pause
    @player.pause
  end

  def stop
    @player.stop
    self.muda_estado :stop
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
$_btn_play = JButton.new("Play")
$_btn_stop.setEnabled false
$_btn_pause.setEnabled false
$_btn_play.setEnabled false
$_text = JLabel.new("Selecione um arquivo .mp3 para tocar!")
_panel.add(BorderLayout::NORTH, $_text)
_panel.add(BorderLayout::WEST, $_btn_search)
_panel.add(BorderLayout::EAST, $_btn_stop)
_panel.add(BorderLayout::CENTER, $_btn_play)
_panel.add(BorderLayout::SOUTH, $_btn_pause)
$_frame.setTitle("JRuby MP3 Player!")
$_frame.pack()
$_frame.setVisible(true)

listener=Click_Player.new()
$_btn_search.addActionListener(listener)
$_btn_stop.addActionListener(listener)
$_btn_pause.addActionListener(listener)
$_btn_play.addActionListener(listener)
