# encoding: utf-8
require 'securerandom'

namespace :create_users do

  #Usage
  #Development:   bundle exec rake create_users:create
  #In production: bundle exec rake create_users:create RAILS_ENV=production
  task :create => :environment do
  	NUMBER_OF_USERS = 60
  	EMAIL_BASE = "usosegurodelastic"
  	EMAIL_SERVER = "gmail.com"
  	USERNAME_BASE = "Alumno"
  	puts "Creating " + NUMBER_OF_USERS.to_s + " users..."

  	created_users = {}
  	for i in 1..NUMBER_OF_USERS
  		user = User.new
  		user.name = USERNAME_BASE + i.to_s
        user.email = EMAIL_BASE + "+" + i.to_s + "@" + EMAIL_SERVER
        user.password = SecureRandom.hex(4)  #pass will have double length of the number indicated here
        user.password_confirmation = user.password
        user.save!
       
        created_users[user.email] = user.password
        puts "User: " + user.email + " with pass: " + user.password
  	end

  	#finally print the array with users and passwords to a file for the teacher to have them all
  	out_file = File.new("USUARIOS_PARA_EL_PROFE.txt", "w")
	out_file.puts("Usuarios creados")
	created_users.each do |key, value|
		out_file.puts("Email: " + key + "  Password: " + value)
	end
	out_file.close

	#and print the array with users and passwords to a file to print them and cut in pieces for the pupils
	out_file = File.new("USUARIOS_SEPARADOS.txt", "w")
	created_users.each do |key, value|
		out_file.puts("")
		out_file.puts("Email: " + key + "  Password: " + value)
		out_file.puts("")
		out_file.puts("-----------------------------------------------------")		
	end	
	out_file.close

  end
end