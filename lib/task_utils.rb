def prepareFile(filePath)
  if File.exist?(filePath)
    system "rm " + filePath
  end
  system "touch " + filePath
end

def write(line,filePath)
  if line==nil
    line = "nil"
  end
  puts line.to_s

  # Create a new file and write to it  
  File.open(filePath, 'a') do |f| 
    f.puts  line.to_s + "\n"
  end
end