module NewNotificationsHelper
  def today_or_else(day)
    if day == Date.today
      t('today')
    elsif day == Date.yesterday
      t('yesterday')
    else
      I18n.l day
    end
  end
end
