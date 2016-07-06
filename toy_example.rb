class Checkout
  def complete_checkout
    self.total = self.orders.map{|o| o.products.map(&:price).reduce(&:+)}.reduce(&:+)

    self.card_amount = self.total
    self.user_funds_amount = 0
    if self.user.has_customer_funds?
      self.card_amount = self.total - user.customer_funds
      self.user_funds_amount = user.customer_funds
    end

    if (authorize_money_from_bank(self.card_amount) &&
        debit_funds_from_user(self.user_funds_amount))
      self.state = "completed"

      email = Email.new(:checkout_completed, checkout: self)
      email.send

      MONITOR.increment(:checkout_completed)
    else
      redirect_to_payment_error_page
    end
  end
end
