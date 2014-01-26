SimpleCaptcha.setup do |sc|
  sc.tmp_path = Rails.root.join('tmp/simple_captcha').to_s
end
