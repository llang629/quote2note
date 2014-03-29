require 'sinatra'
require 'erb'

require 'logger'
$stdout.sync = true
$stderr.sync = true
$stderr.puts "q2n: routes.rb starting"
if ENV.has_key?('Q2N_FOLDER')
    filepath = ENV['Q2N_FOLDER']+"/"
    else
    filepath = ""
end
$stderr.puts "q2n: filepath= "+filepath

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
    midifull  = filepath + @midifull
    @wavfile  = @midifile.sub(/[^.]+\z/,"wav")
    wavfull   = filepath + @wavfile
    wav_ret   = system( "fluidsynth -F wavfull /usr/share/sounds/sf2/FluidR3_GM.sf2 midifull" )
    @mp3file  = @midifile.sub(/[^.]+\z/,"mp3")
    mp3full   = filepath + @mp3file
    mp3_ret   = system( "lame wavfull mp3full" )
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