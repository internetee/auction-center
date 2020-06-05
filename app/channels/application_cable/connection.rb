module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_current_user
      logger.add_tags 'ActionCable', current_user.email
    end

    def find_current_user
      reject_unauthorized_connection unless env['warden'].user
      user = User.find_by(id: env['warden'].user.id)
      reject_unauthorized_connection unless user
      user
    end
  end
end
