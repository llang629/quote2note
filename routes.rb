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
require 'pony'
Pony.options = { :to => 'q2n@larrylang.net', :from => 'noreply@larrylang.net' }
#Pony.mail :subject => 'quote2note starting', :body => Time.now.to_s

get '/' do
    $stderr.puts "q2n: route /"
    @symbolinvalid = false
    erb :main
end

get '/action' do
    FileUtils.mkdir_p(ENV['Q2N_FOLDER'])
    
    @symbol = params[:symbol].upcase
    $stderr.puts "q2n: route /action with " +@symbol
    
    @midifile = %x[ruby quote2note.rb --symbol #{@symbol}].delete("\n")
    @wavfile  = @midifile.sub(/[^.]+\z/,"wav")
    wav_ret   = system( "fluidsynth -F ENV['Q2N_FOLDER']/#{@wavfile} /usr/share/sounds/sf2/FluidR3_GM.sf2 ENV['Q2N_FOLDER']/#{@midifile}" )
    @mp3file  = @midifile.sub(/[^.]+\z/,"mp3")
    mp3_ret   = system( "lame ENV['Q2N_FOLDER']/#{@wavfile} ENV['Q2N_FOLDER']/#{@mp3file}" )
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
    FileUtils.rm_rf(Dir.glob(ENV['Q2N_FOLDER']+"/*"))
end