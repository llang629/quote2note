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
    
    usereport = Time.now.to_s+"\n"+@midifile+"\n"+request.ip+"\n"+request.user_agent+"\n"+request.referrer
    $stderr.puts "q2n: route /action use report:"+"\n"+usereport
    Pony.mail( :subject => 'quote2note in use', :body => usereport )
    
    if @midifile.include? "ERROR"
        @symbolinvalid = true
        erb :main
        else
        midifull = filepath + @midifile
        @wavfile = @midifile.sub(/[^.]+\z/,"wav")
        wavfull  = filepath + @wavfile
        system( "fluidsynth -F #{wavfull} #{sndfnt} #{midifull}" )
        @mp3file = @midifile.sub(/[^.]+\z/,"mp3")
        mp3full  = filepath + @mp3file
        system( "lame #{wavfull} #{mp3full} --tt #{@midifile} -tl quote2note -ta Larry_Lang" )
        erb :result
    end
end

get '/sweep' do
    $stderr.puts "q2n: route /sweep"
    FileUtils.rm_rf(Dir.glob(ENV['Q2N_DIR']+"/*"))
end