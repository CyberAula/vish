def print_mail(excursion_id, category, position)
  excursion = Excursion.find(excursion_id)
  puts "email: " + excursion.author.user.email
  puts "Dear " + excursion.author.user.name
  puts "We are glad to inform you that your excursion entitled " + excursion.title + "(http://vishub.org/excursions/" + excursion.id.to_s + ") has won the " + position + " prize in the ViSH competitions in the category " + category + "."
  puts "There were many really good excursions presented to the competition, you can see all the winners in http://vishub.org/contest"
  puts "Thank you for taking part in the competition, we hope you enjoyed the experience and continue using Virtual Science Hub in the future and spreading the word among your colleagues."
  puts "We will contact you after 7th January 2014 to send you the information to get your prize.

Happy new year 2014.
The ViSH Team"

end

