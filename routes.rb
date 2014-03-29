require 'sinatra'
require 'erb'

require 'logger'
$stdout.sync = true
$stderr.sync = true
$stderr.puts "q2n: routes.rb starting"

#FileUtils.mkdir_p('log')
#log = File.new("log/q2n.log", "a+")
#$stdout.reopen(log)
#$stderr.reopen(log)

# email via /usr/sbin/sendmail
#require 'pony'
#Pony.options = { :to => 'q2n@larrylang.net', :from => 'noreply@larrylang.net' }
#Pony.mail :subject => 'quote2note starting', :body => Time.now.to_s

get '/' do
    $stderr.puts "q2n: route /"
    @symbolinvalid = false
    erb :main
end

get '/action' do
    FileUtils.mkdir_p('public/mp3')
    FileUtils.mkdir_p('public/wav')
    FileUtils.mkdir_p('public/mid')
    
    @symbol = params[:symbol].upcase
    $stderr.puts "q2n: route /action with " +@symbol
    
    @midifile = %x[ruby quote2note.rb --symbol #{@symbol}].delete("\n")
    @wavfile  = File.join( File.dirname(my_path), "#{@midifile}.wav" )
    wavGood   = system( "fluidsynth -F ./public/wav/#{@wavfile} /usr/share/sounds/sf2/FluidR3_GM.sf2 ./public/mid/#{@midifile}" )
    @mp3file  = File.join( File.dirname(my_path), "#{@midifile}.mp3" )
    mp3Good   = system( "lame ./public/wav/#{@wavfile} ./public/mid/#{@mp3file}" )
    #Pony.mail :subject => 'quote2note in use', :body => @midifile
    
    if @midifile.include? "ERROR"
        @symbolinvalid = true
        erb :main
        else
        erb :result
    end
end

get '/sweep' do
    $stderr.puts "q2n: route /sweep"
    FileUtils.rm_rf(Dir.glob('public/mp3/*'))
    FileUtils.rm_rf(Dir.glob('public/wav/*'))
    FileUtils.rm_rf(Dir.glob('public/mid/*'))
end