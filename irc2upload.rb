require 'pathname'
require 'thread'

URL = "http:\/\/beta.im\/uploads\/"
HOST = "beta.im"
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
      scp = `scp #{@dir}/#{@file} #{HOST}:#{UPLOAD_DIR}/#{@upload}`
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

class Uploading
   def initialize
      @uploads = Array.new
   end

   def uploadirc(data, buffer, command) 
      Weechat.print("", "Waiting...")
      t = Thread.new {
      target = Upload.new command
      files = `ssh #{HOST} ls uploads`
      files = files.split
      target.check_filename(files)
      r = target.upload_file
      if r.to_i == 0
         Weechat.print("", "#{target.dir}/#{target.file} uploaded successfully as #{target.upload}.")
         Weechat.print("", "#{target.size} uploaded. Access from #{URL}#{target.upload}")
         Weechat.print("", "Type /uput in a buffer to paste link into that buffer.")
         @uploads.push target
      else
         Weechat.print("", "Error uploading #{target.dir}/#{target.file}. #{target.error_check r}")
      end 
      }
      t.join
      return Weechat::WEECHAT_RC_OK
   end

   def uputirc(data, buffer, command)
      if @uploads.size != 0
         f = @uploads.shift
         buffer = Weechat.current_buffer
         s = "Uploaded #{f.upload} to #{URL}/#{UPLOAD_DIR}/#{f.upload} [#{f.size}]"
         Weechat.print("#{buffer}", "#{s}")
      else
         Weechat.print("", "No files in buffer.")
      end
      return Weechat::WEECHAT_RC_OK
   end

   def uclearirc(data, buffer, command)
      @uploads.each {|u|

      }
      @uploads = Array.new
      Weechat.print("", "Upload list cleared.") 
      return Weechat::WEECHAT_RC_OK
   end
end

$uploads = Uploading.new

def weechat_init
   Weechat.register("irc_upload.rb", "Upload Files", "1.0", "GPL3", "Uploads file to server via SCP. Notifies and outputs URL when finished.", "", "")
   Weechat.hook_command("upload", "a", "b", "c", "d", "upload", "")
   Weechat.hook_command("uput", "e", "f", "g", "h", "uput", "")
   return Weechat::WEECHAT_RC_OK
end

def upload(data, buffer, command)
   $uploads.uploadirc(data, buffer, command)
end

def uput(data, buffer, command)
   $uploads.uputirc data, buffer, command
end

def uclear(data, buffer, command)
   $uploads.uclearirc data, buffer, command
end
