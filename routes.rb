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
Pony.mail( :subject => 'quote2note starting', :body => Time.now.to_s )

get '/' do
    $stderr.puts "q2n: route /"
    @symbolinvalid = false
    erb :main
end

get '/action' do
    FileUtils.mkdir_p(ENV['Q2N_DIR'])
    
    @symbol = params[:symbol].upcase
    $stderr.puts "q2n: route /action with " +@symbol
    
    @midifile = %x[ruby quote2note.rb --symbol #{@symbol}].delete("\n")
    
    report = Time.now.to_s+"\n"+@midifile+"\nClient IP: "+request.ip+"\nClient Browser: "+request.user_agent
    $stderr.puts "q2n: route /action report:"+"\n"+report
    Pony.mail( :subject => 'quote2note in use', :body => report )
    
    if @midifile.include? "ERROR"
        @symbolinvalid = true
        erb :main
        else
        midifull = filepath + @midifile
        basename = File.basename(@midifile, '.*')
        @wavfile = basename+".wav"
        wavfull  = filepath + @wavfile
        if not File.exists?( wavefull ) system( "fluidsynth -F #{wavfull} #{sndfnt} #{midifull}" )
        @mp3file = basename+".mp3"
        mp3full  = filepath + @mp3file
        if not File.exists?( mp3full ) system( "lame -V5 #{wavfull} #{mp3full} --tt #{basename} --tl Quote2Note --ta 'Larry Lang'" )
        erb :result
    end
end

get '/clear' do
    $stderr.puts "q2n: route /clear"
    FileUtils.rm_rf(Dir.glob(ENV['Q2N_DIR']+"/*"))
end