require 'sinatra'
require 'erb'

require 'logger'
$stdout.sync = true
$stderr.sync = true
$stderr.puts "q2n: routes.rb starting"

if ENV.has_key?('Q2N_DIR')
    filepath = ENV['Q2N_DIR']+"/"
    else
    filepath = ""
end
$stderr.puts "q2n: filepath="+filepath

sndfnt = "/usr/share/sounds/sf2/FluidR3_GM.sf2"
$stderr.puts "q2n: sndfnt="+sndfnt

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
    FileUtils.mkdir_p(ENV['Q2N_DIR'])
    
    @symbol = params[:symbol].upcase
    $stderr.puts "q2n: route /action with " +@symbol
    
    $stderr.puts "q2n: sndfntX="+sndfnt
    @midifile = %x[ruby quote2note.rb --symbol #{@symbol}].delete("\n")
    
    #Pony.mail :subject => 'quote2note in use', :body => @midifile
    
    if @midifile.include? "ERROR"
        @symbolinvalid = true
        erb :main
        else
        @midifull = filepath + @midifile
        @wavfile  = @midifile.sub(/[^.]+\z/,"wav")
        @wavfull  = filepath + @wavfile
        $stderr.puts "q2n: sndfntY="+sndfnt
        wav_com = "fluidsynth -F #{@wavfull} #{sndfnt} #{@midifull}"
        $stderr.puts wav_com
        wav_ret   = system( wav_com )
        #wav_ret   = system( "fluidsynth -F #{@wavfull} #{sndfnt} #{@midifull}" )
        @mp3file  = @midifile.sub(/[^.]+\z/,"mp3")
        @mp3full  = filepath + @mp3file
        mp3_ret   = system( "lame #{@wavfull} #{@mp3full}" )
        erb :result
    end
end

get '/sweep' do
    $stderr.puts "q2n: route /sweep"
    FileUtils.rm_rf(Dir.glob(ENV['Q2N_DIR']+"/*"))
end