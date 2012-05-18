require 'pathname'

URL = "http:\/\/haruch.in\/uploads\/"
HOST = "haruch.in"
UPLOAD_DIR = "uploads"

class Size
   def initialize(size)
      @size = size.to_i
      @pfx = "b"
      scale = ["kb", "mb", "gb", "tb", "pb"]
      while @size > 1024
         @size = @size / 1024
         @pfx = scale.shift
      end
   end

   def to_s
      "#{@size}#{@pfx}"
   end
end

class Upload
   attr_reader :dir, :file, :upload, :ext, :size
   attr_writer :upload
   def initialize(path)
      p = Pathname.new(path)
      @dir = p.dirname
      @dirp = p.directory?
      @file = p.basename
      @upload = p.basename
      @ext = p.extname
      @size = Size.new p.size
   end

   def uguu
      Weechat.print("", "uguu")
   end 

   def check_filename(files)
      files.each { |f|
            if f.to_s == @upload.to_s
               rand = rand(10000).to_s
               @upload = "#{rand}#{@file}" 
               check_filename(files)
         end
      }
   end

   def upload_file
      scp = `scp #{@dir}/\"#{@file}\" #{HOST}:#{UPLOAD_DIR}/\"#{@upload}\"`
      $?.to_i
   end

   def error_check(val)
      case val.to_i
      when 0
         "upload successful."
      when 1
         "general error in file copy."
      when 2
         "destination is not directory, but should be."
      when 3
         "maximum symlink level exceeded."
      when 4
         "connecting to host failed."
      when 5
         "connection broken."
      when 6
         "file does not exist."
      when 7
         "no permission to access file."
      when 8 
         "general error in sftp protocol."
      when 9
         "file transfer protocol mismatch."
      when 10
         "no file matches the given criteria."
      when 65
         "host not allowed to connect."
      when 66
         "general error in ssh protocol."
      when 67
         "key exchange failed."
      when 68
         "reserved error."
      when 69
         "MAC error."
      when 70
         "compression error."
      when 71
         "service not available."
      when 72
         "protocol version not supported."
      when 73
         "host key not verifiable."
      when 74
         "connection failed."
      when 75
         "disconnected by application."
      when 76
         "too many connections."
      when 77
         "authentication cancelled by user."
      when 78
         "no more authentication methods available."
      when 79
         "invalid username."
      else 
         "unknown error."
      end
   end
 
end
