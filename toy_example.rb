class Checkout
  def complete_checkout
    calculate_totals

    if (authorize_money_from_bank(self.card_amount) &&
        debit_funds_from_user(self.user_funds_amount))
      post_completed_actions
    else
      redirect_to_payment_error_page
    end
  end

  def calculate_totals
    self.total = self.orders.map{|o| o.products.map(&:price).reduce(&:+)}.reduce(&:+)
    calculate_amounts_to_pay
  end

  def post_completed_actions
    self.state = "completed"
    send_completed_email
    MONITOR.increment(:checkout_completed)
  end

  def calculate_amounts_to_pay
    self.card_amount = self.total
    self.user_funds_amount = 0
    if self.user.has_customer_funds?
      self.card_amount = self.total - user.customer_funds
      self.user_funds_amount = user.customer_funds
    end
  end

  def send_completed_email
    email = Email.new(:checkout_completed, checkout: self)
    email.send
  end
end
