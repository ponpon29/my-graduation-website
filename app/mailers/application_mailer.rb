class ApplicationMailer < ActionMailer::Base
  default from: Rails.env.production? ? "とんこつマップ <noreply@resend.dev>" : "from@example.com"
  layout "mailer"
end
