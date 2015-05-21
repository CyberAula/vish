SimpleCaptcha.setup do |sc|
  sc.tmp_path = Rails.root.join('public/tmp/simple_captcha').to_s
end
