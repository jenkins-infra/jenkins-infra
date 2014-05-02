#!/usr/bin/env ruby
# compress all but the latest log files
# run from cron daily
#
# MANAGED BY PUPPET. DO NOT MODIFY LOCALLY
def rotate(dir)

  logs=Dir.glob(dir+"/*.*");

  # select uncompressed log files
  logs=logs.select { |f| f =~ /\.[0-9]{14}$/ }

  # group logs to domains
  groups = {}
  logs.each { |f|
    head = f[0...-15];
    g = groups[head];
    if !g then
      g = groups[head] = [];
    end
    g << f;
    # puts "#{head}\t#{f}";
  }
  groups.each { |k,v|
    puts k;
    v = v.sort();
    v[0...-1].each { |f|
      puts "  Compressing #{f}";
      system "gzip #{f}";
    }
    puts "  Preserving  #{v[-1]}";
  }
end

rotate(".")
Dir.glob("*").select{|f| FileTest.directory?(f) }.each{|f| rotate(f) }
