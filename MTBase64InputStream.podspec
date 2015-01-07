Pod::Spec.new do |s|
  s.name         = "MTBase64InputStream"
  s.version      = "0.0.1"
  s.summary      = "Objective-C implementation of an input stream which encodes given file contents to base64 on the fly."

  s.description  = <<-DESC
                   MTBase64InputStream is a subclass of NSInputStream which encodes files to base64 format on the fly, 
                   removing the need to store large files in memory just to do that.
                   DESC

  s.homepage     = "https://github.com/srgtuszy/Base64Stream"
  s.license      = {:type => "Apache License, Version 2.0", :file => "LICENSE"}
  s.author             = { "Michał Tuszynski" => "srgtuszy@gmail.com" }
  s.social_media_url   = "http://twitter.com/srgtuszy" 
  s.source       = { :git => "https://github.com/srgtuszy/Base64Stream.git", :tag => "0.0.1" }
  s.source_files  = "Base64Stream/*.{h,m}"
  s.requires_arc = true
end