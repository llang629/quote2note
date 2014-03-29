#!/usr/bin/env ruby

#dir = File.dirname(File.expand_path(__FILE__))
#$LOAD_PATH.unshift dir + '/../lib'

### parse command line options

require 'trollop'

opts = Trollop::options do
    version "quote2note 1.0 (c) 2014 Larry Lang"
    banner <<-EOS
    quote2note converts stock quotes to MIDI music.
    Price maps to pitch, trend to harmony, and volume to loudness.
    
    Usage:
    quote2note [options] <symbol>
    where [options] are:
    EOS
    opt :symbol, "Stock symbol", :type => String
    opt :duration, "Music duration", :default => 45.0
    opt :live, "Direct to synthesizer, otherwise to default MIDI file SYMBOL-DATE.mid"
    opt :midifile, "Alternate MIDI file name", :type => String
end

# remove all non-letter characters and convert to uppercase
symbol = opts[:symbol].gsub(/[^a-zA-Z]/, "").upcase

duration = opts[:duration]
live = opts[:live]

### retrieve stock data from Yahoo

require 'open-uri'
require 'csv'

# validate stock symbol
url = "http://finance.yahoo.com/d/quotes?s=" +symbol+ "&f=x"
exchange = open(url).string
if exchange.include? "N/A"
    puts "ERROR: Invalid stock symbol [" +symbol+ "]"
    exit
end

# convert stock symbol into Yahoo URL
url = "http://ichart.finance.yahoo.com/table.csv?s=" + symbol
# load stock data into into .csv array
quotes=CSV.new(open(url))

quotes.shift #delete header
quotes = quotes.sort #oldest first

dates   = quotes.transpose[0]
acloses = quotes.transpose[6] #adjusted closing prices
volumes = quotes.transpose[5]
count   = dates.count

### map stock data to MIDI values

#calculate duration of each note
noteduration = duration/count

class Array
    #define user Array method to scale from data to MIDI values, default 0 to 127
    def midify(midimin=0, midimax=127)
        midispan = midimax - midimin
        max = self.map(&:to_f).max
        min = self.map(&:to_f).min
        span = max - min
        self.collect { |s| (((midispan/span)*(s.to_f-min))+midimin).round }
    end
end

notes = acloses.midify(0,120)
vels  = volumes.midify(80,127)

#harmonies according to gaining or losing stock price trend
harmonies = Array.new(count)
harmonies.each_index do |i|
    if i == 0                          #if opening day
        harmonies[i] = notes[i]              #unison
        elsif acloses[i] >= acloses[i-1]   #if gaininig...
        harmonies[i] = notes[i]+4            #major third
        else                               #if losing...
        harmonies[i] = notes[i]+6            #tritone
    end
end

#pulses according to passing time periods
pulses = Array.new(count)
pulses.each_index do |i|
    if i>0 && Date.parse(dates[i]).year != Date.parse(dates[i-1]).year
        pulses[i] = 1
        else
        pulses[i] = 0
    end
end

### write MIDI values via midilib to .mid file
# derivative of 'from_scratch.mid' example for midilib GEM

if live == false
    
    require 'midilib/sequence'
    require 'midilib/consts'
    require 'midilib/io/seqwriter'
    include MIDI
    
    seq = Sequence.new()
    
    # Special first track holds tempo and other meta events
    track = Track.new(seq)
    seq.tracks << track
    microduration = (noteduration*1000000).round #note duration in microseconds
    track.events << Tempo.new(microduration) #tempo by (quarter) note duration
    track.events << MetaEvent.new(META_SEQ_NAME, 'Sequence Name')
    
    # Create a track to hold the notes. Add it to the sequence.
    track = Track.new(seq)
    seq.tracks << track
    
    # Give the track a name and an instrument name (optional).
    track.name = 'My New Track'
    track.instrument = GM_PATCH_NAMES[0]
    
    # Add a volume controller event (optional).
    track.events << Controller.new(0, CC_VOLUME, 127)
    
    # Add note events to the track, according to MIDI values.
    # Arguments for note on and note off constructors are
    # channel, note, velocity, and delta_time.
    # Channel numbers start at zero.
    # Sequence#note_to_delta method yields delta time length of single quarter note.
    track.events << ProgramChange.new(0, 1, 0)
    quarter_note_length = seq.note_to_delta('quarter')
    
    for i in 0..(count-1)
        track.events << NoteOn.new(0, notes[i] , vels[i], 0)
        track.events << NoteOn.new(0, harmonies[i] , vels[i], 0)
        track.events << NoteOff.new(0, notes[i] , vels[i], quarter_note_length)
        track.events << NoteOff.new(0, harmonies[i] , vels[i], quarter_note_length)
        #signal passing time periods
        if pulses[i] == 1
            track.events << NoteOn.new(9, 51, 64, 0)
        end
    end
    
    if ENV.has_key?('Q2N_DIR')
        filepath = ENV['Q2N_DIR']+"/"
        else
        filepath = ""
    end
    filename = symbol+"-"+dates.last+".mid"
    fullfile = filepath + filename    
    File.open(fullfile, 'wb') { |file| seq.write(file) }
    puts filename
    
end

### play MIDI values via unimidi to synthesizer, external or software

if live == true
    
    require 'unimidi'
    
    # selects MIDI output
    output = UniMIDI::Output.use(:first)
    
    #set main patch on channel 1
    output.puts(0xB0, 0x00, 121)  #General MIDI patch bank
    output.puts(0xB0, 0x20, 0)
    output.puts(0xC0, 0x00 )      #General MIDI piano patch
    
    #set click patch on channel 10
    output.puts(0xB9, 0x00, 120)  #General MIDI rhythm bank
    output.puts(0xB9, 0x20, 0)
    output.puts(0xC9, 0x00 )      #General MIDI standard rhythm
    
    
    for i in 0..(count-1)
        
        #print daily stock quote
        puts "#{symbol.upcase}  #{dates[i]}  $#{acloses[i]}  #{volumes[i]}"
        
        #diagnostic
        #puts "#{notes[i]}  #{harmonies[i]}  #{vels[i]}  #{pulses[i]}"
        
        #play note and harmony
        output.puts(0x90, notes[i], vels[i]) # note on
        output.puts(0x90, harmonies[i], vels[i]) # note on
        sleep(noteduration) # wait
        output.puts(0x80, notes[i], vels[i]) # note off
        output.puts(0x80, harmonies[i], vels[i]) # note off
        
        #signal passing time periods
        if pulses[i] == 1
            output.puts(0x99, 51, 64)
        end
        
    end
    
end

