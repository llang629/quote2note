require 'sinatra'
require 'newrelic_rpm'
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

get '/main' do
    $stderr.puts "q2n: route /main"
    @symbolinvalid = false
    erb :main
end

get '/action' do
    FileUtils.mkdir_p(ENV['Q2N_DIR'])
    
    @symbol = params[:symbol].upcase
    
    if @symbol.to_s.empty?
        $stderr.puts "q2n: symbol empty"
        redirect back
        else
        
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
            unless File.exist?( wavfull )
                $stderr.puts "q2n: fresh wav"
                system( "fluidsynth -F #{wavfull} #{sndfnt} #{midifull}" )
            end
            @mp3file = basename+".mp3"
            mp3full  = filepath + @mp3file
            unless File.exist?( mp3full )
                $stderr.puts "q2n: fresh mp3"
                system( "lame -V5 #{wavfull} #{mp3full} --tt #{basename} --tl Quote2Note --ta 'Larry Lag'" )
            end
            erb :result
        end
    end
end

get '/show' do
    $stderr.puts "q2n: route /show"
    %x[ ls -l  #{Dir.glob(ENV['Q2N_DIR']).first} ].insert(0, "<pre>") #<pre> preserves output format
end

get '/clear' do
    $stderr.puts "q2n: route /clear"
    FileUtils.rm_rf(Dir.glob(ENV['Q2N_DIR']+"/*")).insert(0, "<pre>") #<pre> preserves output format
end

get '/*' do
    $stderr.puts "q2n: route other " + request.url
    redirect to('/main')
end
