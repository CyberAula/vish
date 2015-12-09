def prepareFile(filePath)
  system "rm " + filePath if File.exist?(filePath)
  system "touch " + filePath
end

def write(line,filePath)
  line = "nil" if line==nil
  puts line.to_s

  # Create a new file and write to it  
  File.open(filePath, 'a') do |f| 
    f.puts  line.to_s + "\n"
  end
end

def printTitle(title)
  unless title.nil?
    puts "#####################################"
    puts title
    puts "#####################################"
  end
end