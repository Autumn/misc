require_relative 'upload'

ARGV.each { |arg|
   f = Upload.new arg
   files = `ssh #{HOST} ls uploads`
   if $? == 0
      files = files.split
      f.check_filename files
      r = f.upload_file
      if r.to_i == 0
         puts "#{f.dir}/#{f.upload} [#{f.size}]"
         puts "access from #{URL}#{f.upload}"
      else
         puts f.error_check r
      end
   else
      puts "unable to connect to server to check files."
   end
}

